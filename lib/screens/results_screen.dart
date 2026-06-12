import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inner_breeze/shared/breeze_style.dart';
import 'package:inner_breeze/widgets/breeze_app_bar.dart';
import 'package:localization/localization.dart';
import 'package:provider/provider.dart';
import 'package:inner_breeze/providers/user_provider.dart';

class ResultsScreen extends StatefulWidget {
  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool saveProgress = true;
  int rounds = 0;
  Map<int, Duration> allRoundDurations = {};

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final sessionData = await userProvider.loadSessionData();
    final roundDurations = await userProvider.loadRoundDurations();

    setState(() {
      rounds = sessionData?.rounds.length ?? 0;
      allRoundDurations = roundDurations;

      if (rounds == 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go('/home');
        });
      }
    });
  }

  Future<void> _handleClose() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!saveProgress) {
      await userProvider.deleteSessionData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return Scaffold(
      appBar: BreezeAppBar(title: 'results_title'.i18n()),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            Text(
              '${'rounds_completed'.i18n()}$rounds',
              style: BreezeStyle.bodyBig,
            ),
            SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              itemCount: allRoundDurations.length,
              itemBuilder: (context, index) {
                int roundNumber = index + 1;
                Duration? duration = allRoundDurations[roundNumber];

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        children: [
                          Text(
                            '$roundNumber',
                            style: BreezeStyle.body,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            duration != null
                                ? '${duration.inMinutes}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}'
                                : 'no_data'.i18n(),
                            style: BreezeStyle.body,
                          ),
                          SizedBox(width: 25),
                          IconButton(
                              icon: Icon(Icons.delete, color: Colors.teal),
                              onPressed: () async {
                                await userProvider.deleteRound(roundNumber);
                                final sessionData =
                                    await userProvider.loadSessionData();
                                setState(() {
                                  rounds = sessionData!.rounds.length;
                                  _loadSessions();
                                });
                              })
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        height: 140,
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 52,
              child: SwitchListTile(
                title: Text("save_progress".i18n()),
                value: saveProgress,
                onChanged: (rounds > 0)
                    ? (bool value) {
                        setState(() {
                          saveProgress = value;
                        });
                      }
                    : null,
                activeThumbColor: Colors.teal,
              ),
            ),
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: TextButton(
                onPressed: () {
                  _handleClose();
                  context.go('/home');
                },
                child: Text('close_button'.i18n(), style: BreezeStyle.bodyBig),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
