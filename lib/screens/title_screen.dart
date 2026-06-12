import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inner_breeze/shared/breeze_style.dart';
import 'package:inner_breeze/widgets/breeze_bottom_nav.dart';
import 'package:localization/localization.dart';
import 'package:provider/provider.dart';
import 'package:inner_breeze/providers/user_provider.dart';

bool isOldDomain() {
  return false;
}

class DeprecationModal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('⚠️ Legacy Version Notice'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text('This Flutter version is no longer actively maintained.'),
            SizedBox(height: 10),
            Text('A new Raylib-based version is available with:'),
            SizedBox(height: 5),
            Text('• Better performance'),
            Text('• Smaller app size'),
            Text('• Native Android experience'),
            SizedBox(height: 15),
            Text('Get the new version at:'),
            SizedBox(height: 5),
            Row(
              children: [
                Icon(Icons.web, color: Colors.teal),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'https://inbe.waozi.xyz/',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.phone_android, color: Colors.teal),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'F-Droid: xyz.waozi.inbe',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('Got it'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class DeprecationBanner extends StatelessWidget {
  final VoidCallback onTap;

  const DeprecationBanner({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        color: Color(0xFFD35400),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '⚠️ Legacy Version: Tap to learn about the new Raylib version',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TitleScreen extends StatefulWidget {
  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> {
  void _navigateToExercise() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.startNewSession();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go('/exercise/step1');
    });
  }

  void _showDeprecationNotice() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DeprecationModal();
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showDeprecationNotice();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          DeprecationBanner(onTap: _showDeprecationNotice),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: Column(
                  children: [
                    SizedBox(height: 60),
                    SizedBox(
                      width: 256,
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    Text(
                      'Inner Breeze',
                      style: BreezeStyle.header,
                    ),
                    SizedBox(height: 32),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(180, 60),
                      ),
                      onPressed: _navigateToExercise,
                      child: Text(
                        "start_button".i18n(),
                        style: BreezeStyle.bodyBig,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BreezeBottomNav(),
    );
  }
}
