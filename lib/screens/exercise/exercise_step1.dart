import 'dart:async';
import 'package:flutter/material.dart';
import 'package:inner_breeze/providers/user_provider.dart';
import 'package:inner_breeze/shared/breeze_style.dart';
import 'package:inner_breeze/widgets/animated_circle.dart';
import 'package:inner_breeze/widgets/stop_session.dart';
import 'package:inner_breeze/utils/breathing_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/services.dart';
import 'package:inner_breeze/utils/audio_player_service.dart';

class ExerciseStep1 extends StatefulWidget {
  ExerciseStep1({super.key});

  @override
  State<ExerciseStep1> createState() => _ExerciseStep1State();
}

class _ExerciseStep1State extends State<ExerciseStep1> {
  int rounds = 1;
  int volume = 80;
  int maxBreaths = 30;
  int breathsDone = -5;
  String animationControl = 'stop';

  String? sessionId;
  Timer? breathCycleTimer;
  Duration tempoDuration = Duration(seconds: 1);
  AudioPlayerService audioPlayerService = AudioPlayerService();
  @override
  void initState() {
    super.initState();
    audioPlayerService.initialize();
    _loadDataFromPreferences();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  }

  Future<void> _loadDataFromPreferences() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final preferences = await userProvider.loadUserPreferences([
      'breaths',
      'tempo',
      'rounds',
      'volume',
      'sessionId',
      'screenAlwaysOn'
    ]);
    var sessionData = await userProvider.loadSessionData();
    if (sessionData == null) {
      userProvider.startNewSession();
      sessionData = await userProvider.loadSessionData();
    }

    try {
      if (preferences.screenAlwaysOn) {
        WakelockPlus.enable();
      } else {
        WakelockPlus.disable();
      }
      // ignore: empty_catches
    } catch (e) {}

    int localMaxBreaths = preferences.breaths;
    int localTempo = preferences.tempo;
    int? localRounds = sessionData?.rounds.length;
    int localVolume = preferences.volume;
    String? localSessionId;

    if (localRounds == 0) {
      localSessionId = await userProvider.startNewSession();
    } else {
      localSessionId = userProvider.user.id;
    }

    setState(() {
      maxBreaths = localMaxBreaths;
      tempoDuration = Duration(milliseconds: localTempo);
      rounds = localRounds!;
      if (rounds > 0) {
        breathsDone = 1;
        animationControl = 'repeat';
      }

      volume = localVolume;
      sessionId = localSessionId;
      startBreathCounting();
    });
  }

  void _navigateToNextExercise() {
    BreathingUtils.cancelBreathCycleTimer(breathCycleTimer);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go('/exercise/step2');
    });
  }

  void startBreathCounting() {
    BreathingUtils.cancelBreathCycleTimer(breathCycleTimer);
    if (breathsDone < 0) {
      breathCycleTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          if (animationControl == 'pause') return;
          animationControl = 'stop';

          breathsDone++;
          if (breathsDone == 0) {
            breathsDone = 1;
            timer.cancel();
            animationControl = 'repeat';
            startBreathCounting();
          }
        });
      });
    } else {
      breathCycleTimer = Timer.periodic(tempoDuration, (timer) {
        setState(() {
          if (animationControl == 'pause') return;

          breathsDone = timer.tick ~/ 2 + 1;
        });
        if (breathsDone == maxBreaths && timer.tick % 2 == 0) {
          audioPlayerService.play(
              'assets/sounds/bell.ogg', volume * 0.8, 'bell');
        }
        if (breathsDone > maxBreaths) {
          animationControl = 'stop';
          timer.cancel();
          _navigateToNextExercise();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                breathsDone < 0
                    ? 'get_ready'.i18n()
                    : '${'round_label'.i18n()}: ${rounds + 1}',
                style: BreezeStyle.header,
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedCircle(
                      tempoDuration: tempoDuration,
                      volume: volume,
                      innerText:
                          (breathsDone > maxBreaths ? maxBreaths : breathsDone)
                              .toString(),
                      controlCallback: () => animationControl,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: StopSessionButton(
                        onPause: pauseBreathCounting,
                        onResume: resumeBreathCounting,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ElevatedButton(
                        onPressed: skipCountdown,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Theme.of(context)
                              .primaryTextTheme
                              .labelLarge
                              ?.color,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                        ),
                        child: Text(
                          'skip_button'.i18n(),
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void pauseBreathCounting() {
    setState(() {
      animationControl = 'pause';
    });
  }

  void resumeBreathCounting() {
    setState(() {
      animationControl = 'resume';
    });
  }

  @override
  void dispose() {
    audioPlayerService.releaseAudioFocus();
    audioPlayerService.disposePlayer('bell');
    BreathingUtils.cancelBreathCycleTimer(breathCycleTimer);

    super.dispose();
  }

  void skipCountdown() {
    BreathingUtils.cancelBreathCycleTimer(breathCycleTimer);

    if (breathsDone < 0) {
      setState(() {
        breathsDone = 1;
        animationControl = 'repeat';
      });
      startBreathCounting();
    } else {
      _navigateToNextExercise();
    }
  }
}
