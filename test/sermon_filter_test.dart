import 'package:flutter_test/flutter_test.dart';
import 'package:wgnmobile/data/models.dart';
import 'package:wgnmobile/features/sermons/sermons_screen.dart';

Sermon _s(int id, String title, SermonKind kind,
        {String series = 'SERIES', String speaker = 'Speaker'}) =>
    Sermon(
      id: id,
      title: title,
      shortTitle: title,
      series: series,
      speaker: speaker,
      kind: kind,
      preachedOn: DateTime(2026, 7, id),
      durationSecs: 600,
    );

void main() {
  final all = [
    _s(4, 'Charity Never Faileth', SermonKind.audio),
    _s(3, 'Bold As A Lion', SermonKind.audio, speaker: 'Pastor Ifeoma'),
    _s(2, 'Authority Part 1', SermonKind.series, series: 'AUTHORITY'),
    _s(1, 'A Full Service', SermonKind.video),
  ];

  test('kind filter applies when no query', () {
    final audio = filterSermons(all, SermonKind.audio, '', 0);
    expect(audio.map((s) => s.id), [4, 3]);
  });

  test('query searches title, series and speaker across kinds', () {
    expect(filterSermons(all, SermonKind.audio, 'authority', 0).single.id, 2);
    expect(filterSermons(all, SermonKind.audio, 'ifeoma', 0).single.id, 3);
    expect(filterSermons(all, SermonKind.audio, 'zzz', 0), isEmpty);
  });

  test('sort oldest reverses, A–Z sorts by title', () {
    final oldest = filterSermons(all, SermonKind.audio, '', 1);
    expect(oldest.map((s) => s.id), [3, 4]);
    final az = filterSermons(all, SermonKind.audio, '', 2);
    expect(az.first.title, 'Bold As A Lion');
  });
}
