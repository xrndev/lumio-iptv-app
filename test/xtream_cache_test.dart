import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumio/core/errors.dart';
import 'package:lumio/core/network/xtream_client.dart';

/// Servidor falso: cuenta peticiones y puede fallar a voluntad.
class _Fake implements HttpClientAdapter {
  int calls = 0;
  bool fail = false;
  bool failLists = false;

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<List<int>>? s, Future<void>? c) async {
    calls++;
    if (fail || (failLists && o.queryParameters["action"] != null)) throw DioException(requestOptions: o, type: DioExceptionType.connectionError);
    final action = o.queryParameters['action'];
    final body = switch (action) {
      null => '{"user_info":{"status":"Active","max_connections":"1"}}',
      'get_live_categories' => '[{"category_id":"1","category_name":"ES | TDT"}]',
      'get_live_streams' => '[{"stream_id":7,"name":"La 1 HD","category_id":"1"}]',
      _ => '[]',
    };
    return ResponseBody.fromString(body, 200);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory dir;
  late _Fake fake;
  late XtreamClient client;
  final creds = XtreamCredentials(host: 'http://srv', username: 'u', password: 'p');

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('lumio_cache');
    fake = _Fake();
    client = XtreamClient(Dio(BaseOptions(responseType: ResponseType.plain))..httpClientAdapter = fake, () async => dir);
  });
  tearDown(() => dir.delete(recursive: true));

  test('la segunda carga no vuelve a descargar las listas', () async {
    await client.loadLive(creds);
    final first = fake.calls; // info + categorías + canales
    expect(first, 3);
    final r = await client.loadLive(creds);
    expect(fake.calls - first, 1, reason: 'solo se consulta el estado de la cuenta');
    expect(r.playlist.channels.single.stableId, 'x7');
  });

  test('si la descarga de listas falla se usa la copia vieja', () async {
    await client.loadLive(creds);
    for (final f in dir.listSync().whereType<File>()) {
      f.setLastModifiedSync(DateTime.now().subtract(const Duration(days: 3)));
    }
    fake.failLists = true;
    final r = await client.loadLive(creds);
    expect(r.playlist.channels, hasLength(1));
  });

  test('sin copia y sin red, falla', () async {
    fake.fail = true;
    await expectLater(client.loadMovies(creds), throwsA(isA<AppError>()));
  });
}
