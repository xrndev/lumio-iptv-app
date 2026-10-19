import 'package:flutter_test/flutter_test.dart';
import 'package:lumio/core/library/library_data.dart';

ProgressEntry _p(String key, {int pos = 600000, int dur = 6000000, int t = 1, bool hidden = false}) =>
    ProgressEntry(
      key: key,
      isEpisode: key.startsWith('e'),
      id: int.parse(key.substring(1)),
      ext: 'mkv',
      title: 'Título $key',
      poster: 'http://p/$key.jpg',
      subtitle: key.startsWith('e') ? 'Temporada 1 · Episodio 2' : '',
      posMs: pos,
      durMs: dur,
      t: t,
      hidden: hidden,
    );

void main() {
  group('favoritos', () {
    test('añadir, quitar y volver a añadir', () {
      var lib = SourceLibrary.empty;
      expect(lib.isFavorite(LibraryKind.channel, 'x1'), isFalse);

      lib = lib.toggleFavorite(LibraryKind.channel, 'x1', 100);
      expect(lib.isFavorite(LibraryKind.channel, 'x1'), isTrue);

      lib = lib.toggleFavorite(LibraryKind.channel, 'x1', 200);
      expect(lib.isFavorite(LibraryKind.channel, 'x1'), isFalse);
      expect(lib.favoriteUids(LibraryKind.channel), isEmpty);

      lib = lib.toggleFavorite(LibraryKind.channel, 'x1', 300);
      expect(lib.isFavorite(LibraryKind.channel, 'x1'), isTrue);
    });

    test('canales, películas y series son listas independientes', () {
      final lib = SourceLibrary.empty
          .toggleFavorite(LibraryKind.channel, 'x1', 1)
          .toggleFavorite(LibraryKind.movie, 'm1', 2)
          .toggleFavorite(LibraryKind.series, 's1', 3);
      expect(lib.favoriteUids(LibraryKind.channel), ['x1']);
      expect(lib.favoriteUids(LibraryKind.movie), ['m1']);
      expect(lib.favoriteUids(LibraryKind.series), ['s1']);
      expect(lib.isFavorite(LibraryKind.movie, 'x1'), isFalse);
    });

    test('se listan en el orden en que se añadieron', () {
      final lib = SourceLibrary.empty
          .toggleFavorite(LibraryKind.channel, 'b', 20)
          .toggleFavorite(LibraryKind.channel, 'a', 10)
          .toggleFavorite(LibraryKind.channel, 'c', 30);
      expect(lib.favoriteUids(LibraryKind.channel), ['a', 'b', 'c']);
    });

    test('la operación no modifica la biblioteca original (inmutable)', () {
      const base = SourceLibrary.empty;
      final next = base.toggleFavorite(LibraryKind.channel, 'x1', 1);
      expect(base.isFavorite(LibraryKind.channel, 'x1'), isFalse);
      expect(next.isFavorite(LibraryKind.channel, 'x1'), isTrue);
    });
  });

  group('recientes', () {
    test('el último visto va primero y no se repite', () {
      var lib = SourceLibrary.empty.addRecent('a', 1).addRecent('b', 2).addRecent('c', 3);
      lib = lib.addRecent('a', 4);
      expect(lib.recentUids(), ['a', 'c', 'b']);
    });

    test('se limita a $maxRecents', () {
      var lib = SourceLibrary.empty;
      for (var i = 0; i < maxRecents + 20; i++) {
        lib = lib.addRecent('c$i', i);
      }
      expect(lib.recentUids(), hasLength(maxRecents));
      expect(lib.recentUids().first, 'c${maxRecents + 19}');
      expect(lib.recentUids(), isNot(contains('c0')));
    });

    test('clearRecents vacía solo los recientes', () {
      final lib = SourceLibrary.empty
          .toggleFavorite(LibraryKind.channel, 'x1', 1)
          .addRecent('x1', 2)
          .clearRecents();
      expect(lib.recentUids(), isEmpty);
      expect(lib.isFavorite(LibraryKind.channel, 'x1'), isTrue);
    });
  });

  group('progreso', () {
    test('reanudar solo si ha empezado (≥30 s) y no ha terminado', () {
      expect(_p('m1', pos: 10000).resumeAt, isNull, reason: 'menos de 30 s');
      expect(_p('m1', pos: 30000).resumeAt, const Duration(seconds: 30));
      expect(_p('m1', pos: 3000000).resumeAt, const Duration(minutes: 50));
      expect(_p('m1', pos: 5600000).resumeAt, isNull, reason: '≥92 %: visto');
      expect(_p('m1', pos: 5950000).finished, isTrue, reason: 'queda menos de 1 min');
    });

    test('duración desconocida: no se puede decidir que terminó', () {
      expect(_p('m1', pos: 40000, dur: 0).finished, isFalse);
      expect(_p('m1', pos: 40000, dur: 0).fraction, 0);
    });

    test('"continuar viendo": lo empezado, sin terminar ni ocultar, lo último primero', () {
      var lib = SourceLibrary.empty
          .saveProgress(_p('m1', t: 10))
          .saveProgress(_p('m2', t: 30))
          .saveProgress(_p('e3', t: 20))
          .saveProgress(_p('m4', pos: 5900000, t: 40)) // terminada
          .saveProgress(_p('m5', pos: 1000, t: 50)); // casi sin empezar
      expect(lib.continueWatching().map((e) => e.key), ['m2', 'e3', 'm1']);

      lib = lib.hideProgress('m2', 60);
      expect(lib.continueWatching().map((e) => e.key), ['e3', 'm1']);
      expect(lib.progressOf('m2'), isNotNull, reason: 'se oculta, no se pierde');
    });

    test('guardar progreso nuevo sustituye al anterior', () {
      final lib = SourceLibrary.empty.saveProgress(_p('m1', pos: 100000, t: 1)).saveProgress(_p('m1', pos: 900000, t: 2));
      expect(lib.progressOf('m1')!.posMs, 900000);
    });
  });

  group('fusión entre dispositivos', () {
    SourceLibrary phone() => SourceLibrary.empty
        .toggleFavorite(LibraryKind.channel, 'x1', 100)
        .toggleFavorite(LibraryKind.channel, 'x2', 100)
        .addRecent('x1', 100)
        .saveProgress(_p('m1', pos: 900000, t: 100));

    SourceLibrary pc() => SourceLibrary.empty
        .toggleFavorite(LibraryKind.channel, 'x2', 150) // añadido y…
        .toggleFavorite(LibraryKind.channel, 'x2', 200) // …quitado en el PC, más reciente
        .toggleFavorite(LibraryKind.channel, 'x3', 150)
        .addRecent('x3', 150)
        .saveProgress(_p('m1', pos: 1500000, t: 200));

    test('une favoritos de ambos y gana el cambio más reciente', () {
      final m = phone().merge(pc());
      expect(m.favoriteUids(LibraryKind.channel), ['x1', 'x3']);
      expect(m.isFavorite(LibraryKind.channel, 'x2'), isFalse, reason: 'lo quitó el PC después');
    });

    test('una tumba más antigua no borra un favorito más nuevo', () {
      final a = SourceLibrary.empty.toggleFavorite(LibraryKind.channel, 'x1', 100).toggleFavorite(LibraryKind.channel, 'x1', 200); // quitado en t=200
      final b = SourceLibrary.empty.toggleFavorite(LibraryKind.channel, 'x1', 300); // añadido en t=300
      expect(a.merge(b).isFavorite(LibraryKind.channel, 'x1'), isTrue);
      expect(b.merge(a).isFavorite(LibraryKind.channel, 'x1'), isTrue);
    });

    test('el progreso más reciente gana', () {
      expect(phone().merge(pc()).progressOf('m1')!.posMs, 1500000);
      expect(pc().merge(phone()).progressOf('m1')!.posMs, 1500000);
    });

    test('es conmutativa e idempotente (el orden y las repeticiones dan igual)', () {
      final ab = phone().merge(pc());
      final ba = pc().merge(phone());
      expect(ab.toJson(), ba.toJson());
      expect(ab.merge(pc()).toJson(), ab.toJson());
      expect(ab.merge(ab).toJson(), ab.toJson());
    });

    test('fusionar con vacío no cambia nada', () {
      expect(phone().merge(SourceLibrary.empty).toJson(), phone().toJson());
      expect(SourceLibrary.empty.merge(phone()).toJson(), phone().toJson());
    });
  });

  group('limpieza de tumbas', () {
    test('quita las tumbas de más de 90 días y conserva favoritos activos', () {
      const day = 86400000;
      const now = 200 * day;
      final lib = SourceLibrary.empty
          .toggleFavorite(LibraryKind.channel, 'viejo', 10 * day) // añadido
          .toggleFavorite(LibraryKind.channel, 'viejo', 20 * day) // quitado hace 180 días
          .toggleFavorite(LibraryKind.channel, 'reciente', 150 * day)
          .toggleFavorite(LibraryKind.channel, 'reciente', 190 * day) // quitado hace 10 días
          .toggleFavorite(LibraryKind.channel, 'activo', 5 * day); // añadido hace mucho, sigue activo
      final p = lib.pruned(now);
      expect(p.favorites[LibraryKind.channel]!.containsKey('viejo'), isFalse);
      expect(p.favorites[LibraryKind.channel]!.containsKey('reciente'), isTrue);
      expect(p.isFavorite(LibraryKind.channel, 'activo'), isTrue);
    });
  });

  group('JSON y código para compartir', () {
    SourceLibrary sample() => SourceLibrary.empty
        .toggleFavorite(LibraryKind.channel, 'x1', 1)
        .toggleFavorite(LibraryKind.movie, 'm9', 2)
        .toggleFavorite(LibraryKind.movie, 'm9', 3)
        .addRecent('x1', 4)
        .saveProgress(_p('e7', t: 5));

    test('ida y vuelta por JSON', () {
      final back = SourceLibrary.fromJson(sample().toJson());
      expect(back.toJson(), sample().toJson());
      expect(back.isFavorite(LibraryKind.movie, 'm9'), isFalse);
      expect(back.progressOf('e7')!.subtitle, 'Temporada 1 · Episodio 2');
    });

    test('LibraryData: varias fuentes', () {
      final d = const LibraryData().withSource('a', sample()).withSource('b', SourceLibrary.empty);
      final back = LibraryData.fromJson(d.toJson());
      expect(back.of('a').toJson(), sample().toJson());
      expect(back.of('b').favoriteUids(LibraryKind.channel), isEmpty);
      expect(back.of('desconocida').toJson(), SourceLibrary.empty.toJson());
    });

    test('código de compartir: ida y vuelta', () {
      final code = encodeShareCode('src123', sample());
      expect(code, startsWith('LUMIO1.'));
      final r = decodeShareCode(code)!;
      expect(r.sourceId, 'src123');
      expect(r.library.toJson(), sample().toJson());
      expect(decodeShareCode('  $code\n')!.sourceId, 'src123', reason: 'tolera espacios al pegar');
    });

    test('códigos inválidos devuelven null, nunca excepción', () {
      for (final bad in ['', 'hola', 'LUMIO1.', 'LUMIO1.@@@', 'LUMIO2.abcd', 'LUMIO1.aGVsbG8=']) {
        expect(decodeShareCode(bad), isNull, reason: bad);
      }
    });

    test('entradas corruptas se ignoran sin romper el resto', () {
      final lib = SourceLibrary.fromJson({
        'fav': {
          'channel': [
            {'u': 'ok', 't': 1},
            {'u': 5, 't': 'mal'},
            'basura',
          ],
        },
        'rec': [
          {'u': 'r', 't': 2},
          null,
        ],
        'prog': [
          {'k': 'm1'},
        ],
      });
      expect(lib.favoriteUids(LibraryKind.channel), ['ok']);
      expect(lib.recentUids(), ['r']);
      expect(lib.progress, isEmpty);
    });
  });
}
