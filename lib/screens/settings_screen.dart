import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:inner_breeze/widgets/breeze_bottom_nav.dart';
import 'package:inner_breeze/widgets/breeze_app_bar.dart';
import 'package:inner_breeze/widgets/language_selector.dart';
import 'package:localization/localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:inner_breeze/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:inner_breeze/models/preferences.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class SettingsScreen extends StatefulWidget {
  SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const MethodChannel _exportChannel =
      MethodChannel('io.naox.inbe/export');

  bool _screenAlwaysOn = true;
  bool isLoading = false;

  String _latestVersionTag = '';
  bool _isNewVersionAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadScreenAlwaysOnPreference();
    _checkForUpdates();
  }

  void handleLanguageChange(String languageCode) async {
    setState(() => isLoading = true);
    await Future.delayed(Duration(seconds: 1)); // Wait for 1 second
    setState(() => isLoading = false);
  }

  Future<String> _fetchLatestVersion() async {
    const String url =
        'https://api.github.com/repos/waozixyz/inbe-legacy/releases/latest';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      _latestVersionTag =
          jsonResponse['tag_name']; // Store the latest version tag
      return jsonResponse['tag_name'];
    } else {
      throw Exception('Failed to fetch latest version from GitHub');
    }
  }

  int _compareVersion(String v1, String v2) {
    List<int> v1Parts = v1.split('.').map(int.parse).toList();
    List<int> v2Parts = v2.split('.').map(int.parse).toList();

    for (int i = 0; i < v1Parts.length; i++) {
      if (i >= v2Parts.length || v1Parts[i] > v2Parts[i]) {
        return 1;
      } else if (v1Parts[i] < v2Parts[i]) {
        return -1;
      }
    }
    return 0;
  }

  Future<void> _checkForUpdates() async {
    try {
      final currentVersion = await _getAppVersion();
      final latestVersion = await _fetchLatestVersion();

      if (_compareVersion(latestVersion, currentVersion) > 0) {
        setState(() {
          _isNewVersionAvailable = true;
          _latestVersionTag = latestVersion;
        });
      }
    } catch (e) {
      // Handle errors or show error notification
    }
  }

  Future<void> _loadScreenAlwaysOnPreference() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final preferences =
        await userProvider.loadUserPreferences(['screenAlwaysOn']);
    setState(() {
      _screenAlwaysOn = preferences.screenAlwaysOn;
    });
  }

  Future<void> _updateScreenAlwaysOnPreference(bool value) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final preferences = Preferences(
      screenAlwaysOn: value,
    );
    userProvider.saveUserPreferences(preferences);

    setState(() {
      _screenAlwaysOn = value;
    });
  }

  Future<void> _resetData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('confirm_reset'.i18n()),
          content: Text('reset_data_warning'.i18n()),
          actions: <Widget>[
            TextButton(
              child: Text('cancel'.i18n()),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('reset_data'.i18n(),
                  style: TextStyle(color: Colors.red)),
              onPressed: () {
                _resetData();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _importData() async {
    _showSnackBar('import_not_available'.i18n());
  }

  Future<void> _exportData() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final data = await userProvider.getAllData();
      final jsonString = jsonEncode(data);

      String formattedDate =
          DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      String fileName = 'InnerBreeze_$formattedDate.json';

      if (Platform.isAndroid) {
        await _exportChannel.invokeMethod('shareJsonExport', {
          'fileName': fileName,
          'content': jsonString,
        });
        _showSnackBar('${'data_exported_success'.i18n()} $fileName');
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(utf8.encode(jsonString));

      _showSnackBar('${'data_exported_success'.i18n()} to: $filePath');
    } catch (e) {
      _showSnackBar('${'error_exporting_data'.i18n()}: $e');
    }
  }

  Future<String> _getAppVersion() async {
    return '1.5.0';
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: SizedBox(
          width: 128.0,
          height: 128.0,
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      appBar: BreezeAppBar(title: 'settings_title'.i18n()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: SizedBox(
            width: 480,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(140, 50),
                  ),
                  child: Text(
                    'show_tutorial_button'.i18n(),
                    style: TextStyle(fontSize: 20.0),
                  ),
                  onPressed: () {
                    context.go('/guide/welcome');
                  },
                ),
                SizedBox(height: 20),
                OutlinedButton(
                  child: Text(
                    'breathing_circle_button'.i18n(),
                    style: TextStyle(fontSize: 18.0),
                  ),
                  onPressed: () {
                    context.go('/breathing');
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Text('language_title'.i18n(),
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      LanguageSelector(onLanguageChanged: handleLanguageChange),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                SwitchListTile(
                  title: Text('keep_screen_on_label'.i18n()),
                  value: _screenAlwaysOn,
                  onChanged: (bool value) {
                    _updateScreenAlwaysOnPreference(value);
                  },
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text('data_management_title'.i18n(),
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: _exportData,
                      child: Text("export_data_button".i18n()),
                    ),
                    OutlinedButton(
                      onPressed: _importData,
                      child: Text("import_data_button".i18n()),
                    ),
                  ],
                ),

                SizedBox(height: 20),
                TextButton(
                  onPressed: _showResetConfirmation,
                  child: Text("reset_data_button".i18n(),
                      style: TextStyle(color: Colors.red)),
                ),
                // Links Section
                SizedBox(height: 40),
                FutureBuilder<String>(
                  future: _getAppVersion(),
                  builder:
                      (BuildContext context, AsyncSnapshot<String> snapshot) {
                    List<Widget> versionWidgets = [];
                    if (snapshot.hasData) {
                      versionWidgets.add(Text(
                          '${'app_version_text'.i18n()}: ${snapshot.data}'));
                      if (_isNewVersionAvailable) {
                        versionWidgets.add(Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                              '${'new_version_available'.i18n()}: $_latestVersionTag'),
                        ));
                        versionWidgets.add(TextButton(
                          onPressed: () {
                            launchUrl(Uri.parse(
                                'https://github.com/waozixyz/inbe-legacy/releases/tag/$_latestVersionTag'));
                          },
                          child: Text('update_button'.i18n()),
                        ));
                      }
                    } else if (snapshot.hasError) {
                      versionWidgets.add(Text('Error: ${snapshot.error}'));
                    } else {
                      versionWidgets.add(CircularProgressIndicator());
                    }
                    return Column(children: versionWidgets);
                  },
                ),
                SizedBox(height: 40),

                Text('connect_support_title'.i18n(),
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 15),
                Wrap(
                  spacing: 15,
                  runSpacing: 15,
                  children: [
                    _buildIconLink(
                        Icons.web, 'Website', 'https://inbe.waozi.xyz/'),
                    _buildIconLink('assets/icons/github.svg', 'GitHub',
                        'https://github.com/waozixyz/inbe'),
                    _buildIconLink('assets/icons/telegram.svg', 'Telegram',
                        'https://t.me/lotusinbe'),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () =>
                            launchUrl(Uri.parse('https://naox.io')),
                        child:
                            Text('NaoX', style: TextStyle(color: Colors.teal)),
                      ),
                      Text('© 2024'),
                      TextButton(
                        onPressed: () => launchUrl(
                            Uri.parse('https://inbreeze.xyz/privacy-policy')),
                        child: Text('privacy_policy'.i18n(),
                            style: TextStyle(color: Colors.teal)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BreezeBottomNav(),
    );
  }

  Widget _buildIconLink(dynamic iconOrImagePath, String tooltip, String url) {
    Widget iconWidget;
    if (iconOrImagePath is IconData) {
      iconWidget = Icon(iconOrImagePath); // IconData icon
    } else if (iconOrImagePath.endsWith('.svg')) {
      iconWidget = SvgPicture.asset(
        iconOrImagePath,
        width: 24,
        height: 24,
      ); // SVG image
    } else {
      iconWidget = Image.asset(
        iconOrImagePath,
        width: 24,
        height: 24,
      ); // Raster image
    }

    return IconButton(
      icon: ColorFiltered(
        colorFilter: ColorFilter.mode(Colors.teal, BlendMode.srcIn),
        child: iconWidget,
      ),
      tooltip: tooltip,
      onPressed: () => launchUrl(Uri.parse(url)),
    );
  }
}
