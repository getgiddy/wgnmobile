import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_state.dart';
import 'models.dart';
import 'supabase_client.dart';

/// Content fetches — world-readable tables, plain FutureProviders.

final sermonsProvider = FutureProvider<List<Sermon>>((ref) async {
  final rows = await supa
      .from('sermons')
      .select()
      .order('preached_on', ascending: false);
  return rows.map(Sermon.fromJson).toList();
});

final devotionalsProvider = FutureProvider<List<Devotional>>((ref) async {
  final rows = await supa
      .from('devotionals')
      .select()
      .lte('for_date', DateTime.now().toIso8601String().substring(0, 10))
      .order('for_date', ascending: false);
  return rows.map(Devotional.fromJson).toList();
});

final eventsProvider = FutureProvider<List<ChurchEvent>>((ref) async {
  final rows = await supa
      .from('events')
      .select()
      .gte('starts_at', DateTime.now().toUtc().toIso8601String())
      .order('starts_at', ascending: true);
  return rows.map(ChurchEvent.fromJson).toList();
});

final testimoniesProvider = FutureProvider<List<Testimony>>((ref) async {
  final rows = await supa
      .from('testimonies')
      .select()
      .eq('approved', true)
      .order('created_at', ascending: false);
  final counts = await supa.from('testimony_amen_counts').select();
  final byId = {
    for (final r in counts) r['testimony_id'] as int: r['amens'] as int,
  };
  return rows
      .map(Testimony.fromJson)
      .map((t) => t.withAmens(byId[t.id] ?? 0))
      .toList();
});

final journalProvider = FutureProvider<List<JournalArticle>>((ref) async {
  final rows = await supa
      .from('journal_articles')
      .select()
      .order('issue_no', ascending: false);
  return rows.map(JournalArticle.fromJson).toList();
});

final updatesProvider = FutureProvider<List<ChurchUpdate>>((ref) async {
  final rows =
      await supa.from('updates').select().order('published_at', ascending: false);
  return rows.map(ChurchUpdate.fromJson).toList();
});

final platformsProvider = FutureProvider<List<BroadcastPlatform>>((ref) async {
  final rows = await supa
      .from('broadcast_platforms')
      .select()
      .order('sort_order', ascending: true);
  return rows.map(BroadcastPlatform.fromJson).toList();
});

Future<Map<String, dynamic>> _config(String key) async {
  final row =
      await supa.from('app_config').select('value').eq('key', key).single();
  return (row['value'] as Map).cast<String, dynamic>();
}

final liveStatusProvider = FutureProvider<LiveStatus>(
    (ref) async => LiveStatus.fromJson(await _config('live')));

final givingConfigProvider = FutureProvider<GivingConfig>(
    (ref) async => GivingConfig.fromJson(await _config('giving')));

final prayerConfigProvider = FutureProvider<PrayerConfig>(
    (ref) async => PrayerConfig.fromJson(await _config('prayer')));

final aboutConfigProvider = FutureProvider<AboutConfig>(
    (ref) async => AboutConfig.fromJson(await _config('about')));

final myPrayersProvider = FutureProvider<List<PrayerRequest>>((ref) async {
  final rows = await supa
      .from('prayer_requests')
      .select()
      .order('created_at', ascending: false);
  return rows.map(PrayerRequest.fromJson).toList();
});

final profileProvider = FutureProvider<Profile?>((ref) async {
  // Watching the auth user rather than reading it means signing in, out or
  // switching accounts refetches on its own, instead of relying on every call
  // site to remember an explicit invalidate.
  final uid = ref.watch(authUserProvider)?.id;
  if (uid == null) return null;
  final row =
      await supa.from('profiles').select().eq('id', uid).maybeSingle();
  return row == null ? null : Profile.fromJson(row);
});
