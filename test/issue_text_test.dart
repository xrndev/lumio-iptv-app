import 'package:flutter_test/flutter_test.dart';
import 'package:lumio/features/player/data/issue_text.dart';

void main() {
  group('sanitizeIssue', () {
    test('oculta usuario y contraseña en la ruta de la URL', () {
      final s = sanitizeIssue('Failed to open http://srv.example/live/JOAN/SECRETO/123.ts.');
      expect(s, contains('/live/***/***/123.ts'));
      expect(s, isNot(contains('JOAN')));
      expect(s, isNot(contains('SECRETO')));
    });

    test('oculta credenciales en parámetros y también en películas y series', () {
      expect(sanitizeIssue('http://x/movie/u/p/1.mkv'), contains('/movie/***/***/1.mkv'));
      expect(sanitizeIssue('http://x/series/u/p/2.mp4'), contains('/series/***/***/2.mp4'));
      final q = sanitizeIssue('GET /xmltv.php?username=ana&password=clave123&x=1');
      expect(q, isNot(contains('ana')));
      expect(q, isNot(contains('clave123')));
      expect(q, contains('x=1'));
    });

    test('compacta espacios y acorta textos largos', () {
      expect(sanitizeIssue('a   b\n c'), 'a b c');
      final long = sanitizeIssue('x' * 500);
      expect(long.length, lessThanOrEqualTo(221));
      expect(long, endsWith('…'));
    });
  });

  group('isInterestingIssue', () {
    test('acepta errores de red y HTTP', () {
      expect(isInterestingIssue('HTTP error 403 Forbidden'), isTrue);
      expect(isInterestingIssue('Connection to tcp://1.2.3.4:80 failed: timed out'), isTrue);
      expect(isInterestingIssue('Failed to open http://a/b.ts'), isTrue);
    });

    test('descarta el ruido de gráficos y de libmpv', () {
      expect(isInterestingIssue('media_kit: error: property not found _setProperty(osc, 1)'), isFalse);
      expect(isInterestingIssue('libmpv_render/dxva2-egl: Failed to create EGL surface'), isFalse);
      expect(isInterestingIssue('lavf: Failed to create file cache'), isFalse);
      expect(isInterestingIssue('todo correcto'), isFalse);
    });
  });
}
