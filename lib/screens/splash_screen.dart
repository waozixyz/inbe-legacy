import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Future<bool> _checkTutorialCompletion() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    return prefs.getBool('$userId/tutorialComplete') ?? false;
  }

  @override
  void initState() {
    super.initState();
    _checkTutorialCompletion().then((isComplete) {
      if (!mounted) {
        return;
      }
      if (isComplete) {
        context.go('/home');
      } else {
        context.go('/guide/lang');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
