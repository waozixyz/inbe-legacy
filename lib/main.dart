import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:inner_breeze/providers/user_provider.dart';
import 'package:inner_breeze/widgets/centered_max_width_widget.dart';
import 'package:localization/localization.dart';
import 'package:provider/provider.dart';
import 'router/router.dart';

const String title = 'Inner Breeze';
final GlobalKey<AppState> appKey = GlobalKey();

void run() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => UserProvider(),
      child: App(key: appKey),
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  run();
}

final _darkTheme = ThemeData.from(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.teal,
    brightness: Brightness.dark,
  ),
);

final _lightTheme = ThemeData.from(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.teal,
    brightness: Brightness.light,
  ),
);

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => AppState();
}

class AppState extends State<App> {
  Locale _currentLocale;
  AppState() : _currentLocale = Locale('en');

  @override
  void initState() {
    super.initState();
    initializeLocale();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _preloadAssets(context);
      }
    });
  }

  Future<void> initializeLocale() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    String languageCode = await userProvider.getLanguagePreference();
    if (!mounted) {
      return;
    }
    setState(() {
      _currentLocale = Locale(languageCode);
    });
  }

  Future<void> _preloadAssets(BuildContext context) async {
    final imageExtensions = ['.png', '.jpg', '.jpeg'];

    final imageAssetFilenames = [
      'angel.jpg',
      'begin.jpg',
      'logo.png',
    ];

    // Construct full paths for image assets
    final imageAssetPaths = imageAssetFilenames
        .map((filename) => 'assets/images/$filename')
        .toList();

    for (final assetPath in imageAssetPaths) {
      if (imageExtensions.any((ext) => assetPath.endsWith(ext))) {
        await precacheImage(AssetImage(assetPath), context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    LocalJsonLocalization.delegate.directories = ['lib/i18n'];

    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        LocalJsonLocalization.delegate,
      ],
      supportedLocales: [
        Locale('en', 'US'),
        Locale('de', 'DE'),
        Locale('es', 'ES'),
        Locale('fr', 'FR'),
        Locale('pl', 'PL'),
        Locale('it', 'IT'),
        Locale('id', 'ID'),
        Locale('ru', 'RU'),
        Locale('zh', 'CN'),
      ],
      locale: _currentLocale,
      title: title,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: ThemeMode.dark,
      builder: (context, child) {
        var backgroundColor = Theme.of(context).colorScheme.surface;

        return Container(
          color: backgroundColor,
          child: CenteredMaxWidthWidget(child: child!),
        );
      },
    );
  }
}
