import 'package:flutter_test/flutter_test.dart';
import 'package:lumio/core/models/channel.dart';
import 'package:lumio/core/models/media.dart';
import 'package:lumio/features/library/progress_tracker.dart';

Channel _movie() => const Channel(
      index: -1,
      name: 'La tormenta',
      url: 'http://srv/movie/u/p/42.mkv',
      isLive: false,
      stableId: 'm42',
      media: MediaMeta(id: 42, isEpisode: false, ext: 'mkv', title: 'La tormenta', poster: 'http://p/42.jpg'),
    );

Channel _episode() => const Channel(
      index: -1,
      name: 'Serie · T1 E2',
      url: 'http://srv/series/u/p/900.mp4',
      isLive: false,
      stableId: 'e900',
      media: MediaMeta(
          id: 900,
          isEpisode: true,
          ext: 'mp4',
          title: 'Serie',
          subtitle: 'Temporada 1 · Episodio 2',
          seriesId: 7),
    );

void main() {
  test('un canal en directo no se sigue (no tiene progreso)', () {
    final t = ProgressTracker()..start(const Channel(index: 0, name: 'La 1', url: 'http://x'));
    expect(t.isTracking, isFalse);
    expect(t.onTick(60000, 6000000, 100000), isNull);
    expect(t.finish(100000), isNull);
  });

  test('guarda como mucho una vez cada 5 s', () {
    final t = ProgressTracker()..start(_movie());
    expect(t.onTick(40000, 6000000, 10000), isNotNull, reason: 'primera lectura válida: guarda');
    expect(t.onTick(41000, 6000000, 11000), isNull);
    expect(t.onTick(44000, 6000000, 14000), isNull);
    final e = t.onTick(46000, 6000000, 15500);
    expect(e, isNotNull);
    expect(e!.posMs, 46000);
    expect(e.key, 'm42');
  });

  test('no guarda si la posición no ha cambiado (en pausa)', () {
    final t = ProgressTracker()..start(_movie());
    expect(t.onTick(40000, 6000000, 10000), isNotNull);
    expect(t.onTick(40000, 6000000, 30000), isNull);
  });

  test('ignora posición 0 o duración desconocida (al parar el reproductor)', () {
    final t = ProgressTracker()..start(_movie());
    expect(t.onTick(0, 6000000, 10000), isNull);
    expect(t.onTick(50000, 0, 10000), isNull);
    expect(t.onTick(-5, 100, 10000), isNull);
  });

  test('finish guarda la última posición buena y no la pisa con un 0 posterior', () {
    final t = ProgressTracker()..start(_movie());
    t.onTick(40000, 6000000, 10000);
    t.onTick(52000, 6000000, 12000); // aún sin guardar (menos de 5 s)
    t.onTick(0, 0, 13000); // lo que emite el reproductor al parar
    final e = t.finish(13500);
    expect(e, isNotNull);
    expect(e!.posMs, 52000);
    expect(e.durMs, 6000000);
    expect(t.isTracking, isFalse);
  });

  test('finish no repite un guardado que ya se hizo', () {
    final t = ProgressTracker()..start(_movie());
    t.onTick(40000, 6000000, 10000); // guardado
    expect(t.finish(10500), isNull);
  });

  test('finish sin haber reproducido nada no guarda', () {
    final t = ProgressTracker()..start(_movie());
    expect(t.finish(1000), isNull);
  });

  test('un episodio guarda los datos de la serie para "Continuar viendo"', () {
    final t = ProgressTracker()..start(_episode());
    final e = t.onTick(120000, 2700000, 10000)!;
    expect(e.key, 'e900');
    expect(e.isEpisode, isTrue);
    expect(e.title, 'Serie');
    expect(e.subtitle, 'Temporada 1 · Episodio 2');
    expect(e.id, 900);
    expect(e.ext, 'mp4');
  });

  test('start reinicia el estado: no mezcla dos contenidos', () {
    final t = ProgressTracker()..start(_movie());
    t.onTick(40000, 6000000, 10000);
    t.start(_episode());
    expect(t.finish(11000), isNull);
    t.start(_episode());
    expect(t.onTick(90000, 2700000, 20000)!.key, 'e900');
  });
}
