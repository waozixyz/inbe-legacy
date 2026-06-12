import 'dart:async';
import 'package:flutter/material.dart';
import 'package:inner_breeze/providers/user_provider.dart';
import 'package:inner_breeze/shared/breeze_style.dart';
import 'package:inner_breeze/widgets/stop_session.dart';
import 'package:inner_breeze/widgets/stopwatch.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:provider/provider.dart';
import 'package:inner_breeze/models/session.dart';
import 'package:inner_breeze/utils/wake_lock_service.dart';

class ExerciseStep2 extends StatefulWidget {
  ExerciseStep2({super.key});

  @override
  State<ExerciseStep2> createState() => _ExerciseStep2State();
}

class _ExerciseStep2State extends State<ExerciseStep2> {
  Duration duration = Duration(seconds: 0);
  late Timer timer;
  int rounds = 1;
  bool isPaused = false;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(Duration(milliseconds: 10), (Timer t) {
      setState(() {
        if (isPaused) return;
        duration = duration + Duration(milliseconds: 10);
      });
    });
    _loadDataFromPreferences();
  }

  Future<void> _loadDataFromPreferences() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userPreferences = await userProvider
        .loadUserPreferences(['breaths', 'tempo', 'volume', 'sessionId', 'screenAlwaysOn']);
    final sessionData = await userProvider.loadSessionData();

    if (!mounted) return;

    await WakeLockService.setEnabled(userPreferences.screenAlwaysOn);

    int tempo = userPreferences.tempo;
    duration = Duration(milliseconds: tempo);

    setState(() {
      rounds = sessionData!.rounds.length;
    });
  }

  void _onStopSessionPressed() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    Session? currentSession = await userProvider.loadSessionData();

    if (currentSession != null) {
      currentSession.rounds[rounds + 1] = duration;
      userProvider.saveSessionData(currentSession);
    }
  }

  void pauseTimer() {
    isPaused = true;
  }

  void resumeTimer() {
    isPaused = false;
  }

  void _navigateToNextExercise() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onStopSessionPressed();
      context.go('/exercise/step3');
    });
  }

  @override
  void dispose() {
    WakeLockService.setEnabled(false);
    timer.cancel();
    super.dispose();
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
                'breath_hold'.i18n(),
                style: BreezeStyle.header,
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _navigateToNextExercise,
                      child: CustomTimer(duration: duration),
                    ),
                  ),
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
                        onPause: pauseTimer,
                        onResume: resumeTimer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ElevatedButton(
                        onPressed: _navigateToNextExercise,
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
                          'finish_hold'.i18n(),
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
}
