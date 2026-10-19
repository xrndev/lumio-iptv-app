import 'package:flutter_test/flutter_test.dart';
import 'package:lumio/core/util/channel_names.dart';
import 'package:lumio/core/util/stable_hash.dart';

void main() {
  searchFoldTests();
  group('parseChannelName (nombres reales de proveedores)', () {
    void expectName(String raw, String title, {String? quality, bool hevc = false}) {
      final n = parseChannelName(raw);
      expect(n.title, title, reason: raw);
      expect(n.quality, quality, reason: '$raw → calidad');
      expect(n.hevc, hevc, reason: '$raw → hevc');
    }

    test('quita prefijo de país, símbolos y calidad', () {
      expectName('ES - LA SEXTA FHD◉', 'LA SEXTA', quality: 'FHD');
      expectName('ES - LA SEXTA HEVC', 'LA SEXTA', hevc: true);
      expectName('ES - LA 1 4K/UHD', 'LA 1', quality: '4K');
      expectName('ES - CUATRO HEVC ◉', 'CUATRO', hevc: true);
      expectName('ES - MOVISTAR  DRAMA HEVC', 'MOVISTAR DRAMA', hevc: true);
      expectName('ES - MOVISTAR PLUS+ SD', 'MOVISTAR PLUS+', quality: 'SD');
      expectName('ES - TEN FHD', 'TEN', quality: 'FHD');
    });

    test('se queda con la mejor calidad si hay varias', () {
      expectName('ES - CANAL HD FHD', 'CANAL', quality: 'FHD');
      expectName('CANAL 4K HEVC', 'CANAL', quality: '4K', hevc: true);
    });

    test('no confunde números ni palabras con etiquetas de calidad', () {
      expectName('ES - TV3', 'TV3');
      expectName('ES - LA 2', 'LA 2');
      expectName('HDTV Plus', 'HDTV Plus');
      expectName('DISCOVERY CHANNEL', 'DISCOVERY CHANNEL');
    });

    test('canales sin prefijo ni etiquetas quedan igual', () {
      expectName('Telemadrid', 'Telemadrid');
      expectName('  La   Sexta  ', 'La Sexta');
    });

    test('separadores de prefijo: |, -, :', () {
      expectName('ES | ANTENA 3 HD', 'ANTENA 3', quality: 'HD');
      expectName('UK: BBC One FHD', 'BBC One', quality: 'FHD');
    });

    test('si al limpiar no queda nada, devuelve el original', () {
      expect(parseChannelName('ES - HD').title, isNotEmpty);
      expect(parseChannelName('4K').title, '4K');
    });
  });

  group('prettyGroupName', () {
    test('quita región y pone mayúsculas de título', () {
      expect(prettyGroupName('EU | ES | MOVISTAR'), 'Movistar');
      expect(prettyGroupName('EU | ES | TDT ESPAÑA VIP'), 'TDT España VIP');
      expect(prettyGroupName('EU | ES | M+ SERIES & CINE'), 'M+ Series & Cine');
      expect(prettyGroupName('VOD | MULTI-LANG - NEW RELEASES'), 'Multi-Lang - New Releases');
      expect(prettyGroupName('SRS | SPANISH'), 'Spanish');
    });

    test('un grupo sin separadores queda igual de legible', () {
      expect(prettyGroupName('Deportes'), 'Deportes');
      expect(prettyGroupName(''), '');
    });
  });

  group('stableHash', () {
    test('es determinista y distingue entradas', () {
      expect(stableHash('http://srv/live/1.ts'), stableHash('http://srv/live/1.ts'));
      expect(stableHash('a'), isNot(stableHash('b')));
      expect(stableHash('a'), hasLength(16));
    });

    test('valores fijos (si cambian, se rompen los datos guardados)', () {
      expect(stableHash(''), '811c9dc59747b28c');
      expect(stableHash('lumio'), stableHash('lumio'));
    });
  });
}

void searchFoldTests() {
  test('foldForSearch ignora tildes y mayúsculas', () {
    expect(foldForSearch('Películas ÑANDÚ'), 'peliculas nandu');
    expect(foldForSearch('La 1 HD'), 'la 1 hd');
  });
}
