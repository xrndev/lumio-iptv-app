// Ejecutar: flutter test integration_test/secure_store_test.dart -d windows
// Comprueba el almacén cifrado real de la plataforma (usa una clave de prueba,
// nunca la de la fuente del usuario).
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:iptv_launcher/core/storage/source_store.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('guardar, leer y borrar en el almacén seguro real', (t) async {
    final store = SecureSourceStore(null, 'integration_test_key');
    await store.clear();
    expect(await store.read(), isNull);

    await store.write(const SavedSource.xtream(host: 'http://srv.example', username: 'u', password: 'p'));
    // Instancia nueva = "reinicio" de la app.
    final again = await SecureSourceStore(null, 'integration_test_key').read();
    expect(again?.type, SourceType.xtream);
    expect(again?.location, 'http://srv.example');
    expect(again?.password, 'p');

    await store.clear();
    expect(await SecureSourceStore(null, 'integration_test_key').read(), isNull);
  });
}
