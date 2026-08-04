import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_state.dart';
import 'supabase_client.dart';

/// Per-user state (works for anonymous users too): likes, saved devotionals,
/// event registrations, amens, devotional reads, playback positions.
/// Mutations are optimistic; Supabase failures roll back silently on reload.
class UserState {
  const UserState({
    this.likedSermons = const {},
    this.savedDevotionals = const {},
    this.registeredEvents = const {},
    this.amenedTestimonies = const {},
    this.readDates = const {},
    this.playback = const {},
    this.loaded = false,
  });

  final Set<int> likedSermons;
  final Set<int> savedDevotionals;
  final Set<int> registeredEvents;
  final Set<int> amenedTestimonies;

  /// Dates (yyyy-mm-dd) with a devotional marked read.
  final Set<String> readDates;

  /// sermon id -> last position in seconds.
  final Map<int, int> playback;
  final bool loaded;

  UserState copyWith({
    Set<int>? likedSermons,
    Set<int>? savedDevotionals,
    Set<int>? registeredEvents,
    Set<int>? amenedTestimonies,
    Set<String>? readDates,
    Map<int, int>? playback,
    bool? loaded,
  }) =>
      UserState(
        likedSermons: likedSermons ?? this.likedSermons,
        savedDevotionals: savedDevotionals ?? this.savedDevotionals,
        registeredEvents: registeredEvents ?? this.registeredEvents,
        amenedTestimonies: amenedTestimonies ?? this.amenedTestimonies,
        readDates: readDates ?? this.readDates,
        playback: playback ?? this.playback,
        loaded: loaded ?? this.loaded,
      );

  /// Current consecutive-day streak ending today or yesterday.
  int get streak {
    if (readDates.isEmpty) return 0;
    var day = DateTime.now();
    String key(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    // A streak may still be alive if yesterday was read but today isn't yet.
    if (!readDates.contains(key(day))) {
      day = day.subtract(const Duration(days: 1));
      if (!readDates.contains(key(day))) return 0;
    }
    var count = 0;
    while (readDates.contains(key(day))) {
      count++;
      day = day.subtract(const Duration(days: 1));
    }
    return count;
  }

  bool get readToday {
    final now = DateTime.now();
    final key =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return readDates.contains(key);
  }
}

class UserStateNotifier extends Notifier<UserState> {
  @override
  UserState build() {
    // Keyed on the user id, not the whole user: gotrue re-emits on every token
    // refresh, and only a change of identity should throw this state away and
    // refetch. Signing in or out now reloads without the caller asking.
    ref.watch(authUserProvider.select((user) => user?.id));
    _load();
    return const UserState();
  }

  String? get _uid => supa.auth.currentUser?.id;

  Future<void> _load() async {
    if (_uid == null) return;
    try {
      final results = await Future.wait([
        supa.from('sermon_likes').select('sermon_id'),
        supa.from('saved_devotionals').select('devotional_id'),
        supa.from('event_registrations').select('event_id'),
        supa.from('testimony_amens').select('testimony_id'),
        supa.from('devotional_reads').select('for_date'),
        supa.from('playback_progress').select('sermon_id, position_secs'),
      ]);
      state = UserState(
        likedSermons:
            {for (final r in results[0]) r['sermon_id'] as int},
        savedDevotionals:
            {for (final r in results[1]) r['devotional_id'] as int},
        registeredEvents:
            {for (final r in results[2]) r['event_id'] as int},
        amenedTestimonies:
            {for (final r in results[3]) r['testimony_id'] as int},
        readDates: {for (final r in results[4]) r['for_date'] as String},
        playback: {
          for (final r in results[5])
            r['sermon_id'] as int: r['position_secs'] as int,
        },
        loaded: true,
      );
    } catch (e) {
      debugPrint('user state load failed: $e');
    }
  }

  Future<void> reload() => _load();

  Future<void> _toggle({
    required String table,
    required String column,
    required int id,
    required bool nowOn,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      if (nowOn) {
        await supa.from(table).upsert({'user_id': uid, column: id});
      } else {
        await supa.from(table).delete().eq('user_id', uid).eq(column, id);
      }
    } catch (e) {
      debugPrint('toggle $table failed: $e');
    }
  }

  void toggleLike(int sermonId) {
    final on = !state.likedSermons.contains(sermonId);
    state = state.copyWith(
      likedSermons: on
          ? {...state.likedSermons, sermonId}
          : ({...state.likedSermons}..remove(sermonId)),
    );
    _toggle(
        table: 'sermon_likes', column: 'sermon_id', id: sermonId, nowOn: on);
  }

  void toggleSaved(int devotionalId) {
    final on = !state.savedDevotionals.contains(devotionalId);
    state = state.copyWith(
      savedDevotionals: on
          ? {...state.savedDevotionals, devotionalId}
          : ({...state.savedDevotionals}..remove(devotionalId)),
    );
    _toggle(
        table: 'saved_devotionals',
        column: 'devotional_id',
        id: devotionalId,
        nowOn: on);
  }

  void toggleRegistration(int eventId) {
    final on = !state.registeredEvents.contains(eventId);
    state = state.copyWith(
      registeredEvents: on
          ? {...state.registeredEvents, eventId}
          : ({...state.registeredEvents}..remove(eventId)),
    );
    _toggle(
        table: 'event_registrations',
        column: 'event_id',
        id: eventId,
        nowOn: on);
  }

  void toggleAmen(int testimonyId) {
    final on = !state.amenedTestimonies.contains(testimonyId);
    state = state.copyWith(
      amenedTestimonies: on
          ? {...state.amenedTestimonies, testimonyId}
          : ({...state.amenedTestimonies}..remove(testimonyId)),
    );
    _toggle(
        table: 'testimony_amens',
        column: 'testimony_id',
        id: testimonyId,
        nowOn: on);
  }

  /// Marks today's devotional read. Returns false if already marked.
  bool markTodayRead() {
    final now = DateTime.now();
    final key =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (state.readDates.contains(key)) return false;
    state = state.copyWith(readDates: {...state.readDates, key});
    final uid = _uid;
    if (uid != null) {
      supa
          .from('devotional_reads')
          .upsert({'user_id': uid, 'for_date': key}).catchError(
              (e) => debugPrint('mark read failed: $e'));
    }
    return true;
  }

  void savePlayback(int sermonId, int positionSecs) {
    state = state
        .copyWith(playback: {...state.playback, sermonId: positionSecs});
    final uid = _uid;
    if (uid != null) {
      supa.from('playback_progress').upsert({
        'user_id': uid,
        'sermon_id': sermonId,
        'position_secs': positionSecs,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).catchError((e) => debugPrint('save playback failed: $e'));
    }
  }
}

final userStateProvider =
    NotifierProvider<UserStateNotifier, UserState>(UserStateNotifier.new);
