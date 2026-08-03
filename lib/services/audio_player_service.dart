import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../data/models.dart';
import '../data/supabase_client.dart';
import '../data/user_state.dart';
import 'download_manager.dart';

/// Lock-screen / notification bridge around a single just_audio player.
class WgnAudioHandler extends BaseAudioHandler with SeekHandler {
  WgnAudioHandler(this._player) {
    _player.playbackEventStream.listen(_broadcast);
  }

  final AudioPlayer _player;

  void _broadcast(PlaybackEvent event) {
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.rewind,
        _player.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.fastForward,
      ],
      systemActions: const {MediaAction.seek},
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    ));
  }

  void setNowPlaying(Sermon s) {
    mediaItem.add(MediaItem(
      id: s.id.toString(),
      title: s.title,
      artist: s.speaker,
      album: s.series,
      duration: Duration(seconds: s.durationSecs),
    ));
  }

  @override
  Future<void> play() => _player.play();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> stop() => _player.stop();
  @override
  Future<void> seek(Duration position) => _player.seek(position);
  @override
  Future<void> rewind() =>
      _player.seek(_player.position - const Duration(seconds: 15));
  @override
  Future<void> fastForward() =>
      _player.seek(_player.position + const Duration(seconds: 30));
}

class NowPlayingState {
  const NowPlayingState({
    this.sermon,
    this.playing = false,
    this.position = Duration.zero,
    this.speed = 1.0,
  });

  final Sermon? sermon;
  final bool playing;
  final Duration position;
  final double speed;

  Duration get duration => Duration(seconds: sermon?.durationSecs ?? 0);
  double get progress => duration.inSeconds == 0
      ? 0
      : (position.inSeconds / duration.inSeconds).clamp(0.0, 1.0);

  NowPlayingState copyWith({
    Sermon? sermon,
    bool? playing,
    Duration? position,
    double? speed,
  }) =>
      NowPlayingState(
        sermon: sermon ?? this.sermon,
        playing: playing ?? this.playing,
        position: position ?? this.position,
        speed: speed ?? this.speed,
      );
}

class PlayerController extends Notifier<NowPlayingState> {
  static AudioPlayer? _sharedPlayer;
  static WgnAudioHandler? _sharedHandler;

  AudioPlayer get _player => _sharedPlayer!;
  Timer? _saveTimer;

  /// Called once from main() before runApp.
  static Future<void> initAudio() async {
    _sharedPlayer = AudioPlayer();
    try {
      _sharedHandler = await AudioService.init(
        builder: () => WgnAudioHandler(_sharedPlayer!),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'dev.elevatelabs.wgnmobile.audio',
          androidNotificationChannelName: 'WGN playback',
          androidNotificationOngoing: true,
        ),
      );
    } catch (e) {
      // Keep the in-app player working even if the service fails (e.g. tests).
      _sharedHandler = null;
      debugPrint('AudioService init failed: $e');
    }
  }

  @override
  NowPlayingState build() {
    _player.positionStream.listen((pos) {
      if (state.sermon != null) state = state.copyWith(position: pos);
    });
    _player.playingStream.listen((playing) {
      state = state.copyWith(playing: playing);
    });
    _saveTimer = Timer.periodic(const Duration(seconds: 5), (_) => _persist());
    ref.onDispose(() => _saveTimer?.cancel());
    return const NowPlayingState();
  }

  void _persist() {
    final s = state.sermon;
    if (s == null || !state.playing) return;
    ref
        .read(userStateProvider.notifier)
        .savePlayback(s.id, state.position.inSeconds);
  }

  Future<void> playSermon(Sermon s, {bool resume = true}) async {
    if (state.sermon?.id == s.id) {
      // Already loaded: just ensure it's playing.
      if (!state.playing) await _player.play();
      return;
    }
    _persist();
    state = NowPlayingState(sermon: s, playing: false, speed: state.speed);
    _sharedHandler?.setNowPlaying(s);
    try {
      final local = await ref.read(downloadsProvider.notifier).localPath(s.id);
      final url = local ?? storageUrl('sermon-audio', s.audioPath);
      if (url == null) return;
      if (local != null) {
        await _player.setFilePath(local);
      } else {
        await _player.setUrl(url);
      }
      final saved = resume
          ? (ref.read(userStateProvider).playback[s.id] ?? 0)
          : 0;
      if (saved > 10 && saved < s.durationSecs - 10) {
        await _player.seek(Duration(seconds: saved));
      }
      await _player.setSpeed(state.speed);
      await _player.play();
    } catch (e) {
      debugPrint('playSermon failed: $e');
    }
  }

  Future<void> toggle() async {
    if (state.sermon == null) return;
    state.playing ? await _player.pause() : await _player.play();
    _persist();
  }

  Future<void> seekRelative(int seconds) async {
    final target = state.position + Duration(seconds: seconds);
    await _player
        .seek(target < Duration.zero ? Duration.zero : target);
  }

  Future<void> cycleSpeed() async {
    final next = state.speed >= 2.0 ? 1.0 : state.speed + 0.25;
    state = state.copyWith(speed: next);
    await _player.setSpeed(next);
  }
}

final playerProvider =
    NotifierProvider<PlayerController, NowPlayingState>(PlayerController.new);
