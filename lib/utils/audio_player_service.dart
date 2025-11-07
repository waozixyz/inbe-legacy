import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';

class AudioPlayerService {
  late AudioSession _session;
  final Map<String, AudioPlayer> _players = {};
  StreamSubscription? _interruptionSubscription;

  Future<void> initialize() async {
    _session = await AudioSession.instance;
    await _session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
    ));

    _interruptionSubscription = _session.interruptionEventStream.listen((event) {
      for (var player in _players.values) {
        if (event.begin) {
          if (event.type == AudioInterruptionType.pause || event.type == AudioInterruptionType.unknown) {
            player.pause();
          }
        } else {
          if (event.type != AudioInterruptionType.unknown) {
            player.play();
          }
        }
      }
    });

  }

 Future<void> preload(String assetPath, String playerId) async {
    try {
      var player = _players[playerId];
      player ??= _players.putIfAbsent(playerId, () => AudioPlayer());
      await player.setAsset(assetPath);
      await player.setVolume(0);
    } catch (e) {
      print('Error preloading audio: $e');
    }
  }

Future<void> play(String assetPath, double volume, String playerId) async {
  if (volume == 0) {
    return;
  }

  try {
    await _session.setActive(true);
    var player = _players[playerId];
    if (player == null) {
      player = AudioPlayer();
      await player.setAsset(assetPath);
      _players[playerId] = player;
    } else {
      var currentAsset = await player.audioSource?.sequence.first.tag;
      if (currentAsset != assetPath) {
        await player.setAsset(assetPath);
      }
    }
    await player.seek(Duration.zero);
    await player.setVolume(volume / 100);
    await player.play();
  } catch (e) {
    print('Error playing audio: $e');
  }
}

  Future<void> stop(String playerId) async {
    try {
      var player = _players[playerId];
      if (player != null) {
        await player.stop();
      }
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  void disposePlayer(String playerId) {
      try {
        var player = _players[playerId];
        if (player != null) {
          player.dispose();
          _players.remove(playerId);
        }
      } catch (e) {
        print('Error disposing audio player: $e');
      }
    }


  Future<void> releaseAudioFocus() async {
    try {
      await _session.setActive(false);
    } catch (e) {
      print('Error releasing audio focus: $e');
    }
  }

  void dispose() {
    _interruptionSubscription?.cancel();
    for (var player in _players.values) {
      player.dispose();
    }
    _players.clear();
  }
}
