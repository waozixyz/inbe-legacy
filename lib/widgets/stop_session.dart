import 'package:flutter/material.dart';
import 'package:inner_breeze/providers/user_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

class StopSessionButton extends StatefulWidget {
  final VoidCallback? onStopSessionPressed;

  final VoidCallback? onPause;
  final VoidCallback? onResume;

  const StopSessionButton({
    this.onStopSessionPressed,
    this.onPause,
    this.onResume,
    super.key,
  });

  @override
  State<StopSessionButton> createState() => _StopSessionButtonState();
}

class _StopSessionButtonState extends State<StopSessionButton> {
  int _rounds = 1;

  @override
  void initState() {
    super.initState();
    _loadDataFromProvider();
  }


  Future<void> _loadDataFromProvider() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final sessionData = await userProvider.loadSessionData();
    
    if (sessionData != null) { 
      setState(() {
        _rounds = sessionData.rounds.length;
      });
    }
  }

  void _navigateToResults() {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);

      Navigator.of(context).pop();

      if (widget.onStopSessionPressed != null) {
        widget.onStopSessionPressed!();
      }
      else if (_rounds == 0) {
        context.go('/home');
        return;
      }
      context.go('/results');
  }

  void _showExitConfirmationDialog(BuildContext context) {
    widget.onPause?.call();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            title: Text('stop_session'.i18n()),
          content: Text('stop_session_confirm'.i18n()),
          actions: <Widget>[
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6.0,
              children: [
                OutlinedButton(
                  onPressed: () {
                    _navigateToResults();
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red),
                  ),
                  child: Text(
                      'stop_session_button'.i18n(),
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    widget.onResume?.call(); 
                    Navigator.of(context).pop();
                  },
                  child: Text('continue_session_button'.i18n()),
                ),
              ],
            ),
          ],
        );
      },
    ).then((_) {
      widget.onResume?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: TextButton(
        onPressed: () => _showExitConfirmationDialog(context),
        child: Text(
          'stop_session_button'.i18n(),
          style: TextStyle(
            fontSize: 18.0,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}
