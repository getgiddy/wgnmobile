import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../data/supabase_client.dart';
import '../data/models.dart';
import 'prefs.dart';

/// A sermon kept on-device. Metadata is duplicated locally so the Offline
/// screen works with no network at all.
class DownloadEntry {
  const DownloadEntry({
    required this.sermonId,
    required this.title,
    required this.speaker,
    required this.meta,
    required this.filePath,
    required this.sizeBytes,
  });

  final int sermonId;
  final String title;
  final String speaker;
  final String meta;
  final String filePath;
  final int sizeBytes;
}

class DownloadsState {
  const DownloadsState({
    this.entries = const {},
    this.inProgress = const {},
  });

  /// sermon id -> completed download.
  final Map<int, DownloadEntry> entries;

  /// sermon id -> progress 0..1.
  final Map<int, double> inProgress;

  int get count => entries.length;
  int get totalBytes =>
      entries.values.fold(0, (sum, e) => sum + e.sizeBytes);
}

class DownloadsNotifier extends Notifier<DownloadsState> {
  Database? _db;
  final _dio = Dio();

  @override
  DownloadsState build() {
    _init();
    return const DownloadsState();
  }

  Future<Database> _database() async {
    if (_db != null) return _db!;
    final dir = await getApplicationSupportDirectory();
    _db = await openDatabase(
      '${dir.path}/wgn_downloads.db',
      version: 1,
      onCreate: (db, _) => db.execute('''
        create table downloads (
          sermon_id integer primary key,
          title text not null,
          speaker text not null,
          meta text not null,
          file_path text not null,
          size_bytes integer not null
        )'''),
    );
    return _db!;
  }

  Future<void> _init() async {
    final db = await _database();
    final rows = await db.query('downloads');
    final entries = <int, DownloadEntry>{};
    for (final r in rows) {
      final path = r['file_path'] as String;
      if (!File(path).existsSync()) {
        await db.delete('downloads',
            where: 'sermon_id = ?', whereArgs: [r['sermon_id']]);
        continue;
      }
      entries[r['sermon_id'] as int] = DownloadEntry(
        sermonId: r['sermon_id'] as int,
        title: r['title'] as String,
        speaker: r['speaker'] as String,
        meta: r['meta'] as String,
        filePath: path,
        sizeBytes: r['size_bytes'] as int,
      );
    }
    state = DownloadsState(entries: entries);
  }

  bool isDownloaded(int sermonId) => state.entries.containsKey(sermonId);

  Future<String?> localPath(int sermonId) async =>
      state.entries[sermonId]?.filePath;

  /// Starts (or removes) a download. Returns a user-facing status message.
  Future<String> toggle(Sermon s, {String meta = ''}) async {
    if (isDownloaded(s.id)) {
      await remove(s.id);
      return 'Removed from offline';
    }
    if (s.audioPath == null) return 'This sermon has no audio file yet';
    if (state.inProgress.containsKey(s.id)) return 'Already downloading…';

    if (ref.read(prefsProvider).wifiOnly) {
      final conn = await Connectivity().checkConnectivity();
      final onWifi = conn.contains(ConnectivityResult.wifi) ||
          conn.contains(ConnectivityResult.ethernet);
      if (!onWifi) return 'Waiting for Wi-Fi (change in Offline settings)';
    }

    final url = storageUrl('sermon-audio', s.audioPath)!;
    final dir = await getApplicationSupportDirectory();
    final audioDir = Directory('${dir.path}/audio');
    await audioDir.create(recursive: true);
    final ext = s.audioPath!.contains('.')
        ? s.audioPath!.split('.').last
        : 'mp3';
    final path = '${audioDir.path}/${s.id}.$ext';

    state = DownloadsState(
      entries: state.entries,
      inProgress: {...state.inProgress, s.id: 0},
    );
    _run(s, url, path, meta);
    return 'Downloading — available offline';
  }

  Future<void> _run(Sermon s, String url, String path, String meta) async {
    try {
      await _dio.download(url, path, onReceiveProgress: (got, total) {
        if (total > 0) {
          state = DownloadsState(
            entries: state.entries,
            inProgress: {...state.inProgress, s.id: got / total},
          );
        }
      });
      final size = File(path).lengthSync();
      final entry = DownloadEntry(
        sermonId: s.id,
        title: s.title,
        speaker: s.speaker,
        meta: meta,
        filePath: path,
        sizeBytes: size,
      );
      final db = await _database();
      await db.insert(
        'downloads',
        {
          'sermon_id': s.id,
          'title': s.title,
          'speaker': s.speaker,
          'meta': meta,
          'file_path': path,
          'size_bytes': size,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      state = DownloadsState(
        entries: {...state.entries, s.id: entry},
        inProgress: {...state.inProgress}..remove(s.id),
      );
    } catch (e) {
      debugPrint('download failed: $e');
      state = DownloadsState(
        entries: state.entries,
        inProgress: {...state.inProgress}..remove(s.id),
      );
    }
  }

  Future<void> remove(int sermonId) async {
    final entry = state.entries[sermonId];
    if (entry == null) return;
    try {
      final f = File(entry.filePath);
      if (f.existsSync()) await f.delete();
    } catch (_) {}
    final db = await _database();
    await db
        .delete('downloads', where: 'sermon_id = ?', whereArgs: [sermonId]);
    state = DownloadsState(
      entries: {...state.entries}..remove(sermonId),
      inProgress: state.inProgress,
    );
  }
}

final downloadsProvider =
    NotifierProvider<DownloadsNotifier, DownloadsState>(DownloadsNotifier.new);
