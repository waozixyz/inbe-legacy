import 'dart:async';
import 'package:flutter/material.dart';
import 'package:inner_breeze/providers/user_provider.dart';
import 'package:inner_breeze/shared/breeze_style.dart';
import 'package:inner_breeze/utils/breathing_utils.dart';
import 'package:inner_breeze/widgets/animated_circle.dart';
import 'package:inner_breeze/widgets/stop_session.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:provider/provider.dart';
import 'package:inner_breeze/utils/wake_lock_service.dart';

class ExerciseStep3 extends StatefulWidget {
  ExerciseStep3({super.key});

  @override
  State<ExerciseStep3> createState() => _ExerciseStep3State();
}

class _ExerciseStep3State extends State<ExerciseStep3> {
  String animationControl = 'forward';
  int volume = 80;
  int countdown = 30;
  int customTicker = 0;
  Duration tempoDuration = Duration(seconds: 2);
  String innerText = 'in';
  Timer? breathCycleTimer;
  int recoveryPause = 15;

  @override
  void initState() {
    super.initState();
    _loadDataFromPreferences().then((_) {
      if (mounted) {
        startBreathCounting();
      }
    });
  }

  Future<void> _loadDataFromPreferences() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final preferences = await userProvider
        .loadUserPreferences(['volume', 'recoveryPause', 'screenAlwaysOn']);
    await WakeLockService.setEnabled(preferences.screenAlwaysOn);
    if (!mounted) return;
    setState(() {
      volume = preferences.volume;
      recoveryPause = preferences.recoveryPause;
    });
  }

  void _navigateToNextExercise() async {
    BreathingUtils.cancelBreathCycleTimer(breathCycleTimer);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go('/exercise/step1');
    });
  }

  String getDisplayText() {
    switch (innerText) {
      case 'in':
        return 'in_breath'.i18n();
      case 'out':
        return 'out_breath'.i18n();
      default:
        return innerText;
    }
  }

  void startBreathCounting() {
    breathCycleTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (animationControl == 'pause') return;
      setState(() {
        customTicker++;
        if (customTicker < 2) {
          innerText = 'in';
        } else if (customTicker < recoveryPause + 2) {
          innerText = (recoveryPause + 2 - customTicker).toString();
          animationControl = 'stop';
        } else if (customTicker >= recoveryPause + 2 && customTicker <= recoveryPause + 3) {
          innerText = 'out';
          animationControl = 'reverse';
        } else {
          _navigateToNextExercise();
        }
      });
    });
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
                'recovery'.i18n(),
                style: BreezeStyle.header,
              ),
            ),
            Expanded(
              child: Center(
                child: AnimatedCircle(
                  volume: volume,
                  tempoDuration: tempoDuration,
                  innerText: getDisplayText(),
                  controlCallback: () => animationControl,
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
                        onPressed: () {
                          _navigateToNextExercise();
                        },
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
    WakeLockService.setEnabled(false);
    BreathingUtils.cancelBreathCycleTimer(breathCycleTimer);
    super.dispose();
  }
}
