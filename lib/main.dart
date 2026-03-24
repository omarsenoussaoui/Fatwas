import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'providers/fatwa_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/home_screen.dart';
import 'services/share_receiver_service.dart';
import 'theme.dart';
import 'constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ShareReceiverService.init();

  // Try loading .env, but don't crash if it fails (release mode)
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env not available in release — use hardcoded default
  }

  final localeProvider = LocaleProvider();
  await localeProvider.loadLocale();

  final fatwaProvider = FatwaProvider();
  // Load API key: SharedPreferences > .env > hardcoded default
  final prefs = await SharedPreferences.getInstance();
  final apiKey = prefs.getString('groq_api_key') ??
      dotenv.env['GROQ_API_KEY'] ??
      defaultGroqApiKey;
  fatwaProvider.setApiKey(apiKey);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: fatwaProvider),
        ChangeNotifierProvider.value(value: localeProvider),
      ],
      child: const FatwasApp(),
    ),
  );
}

class FatwasApp extends StatelessWidget {
  const FatwasApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();

    return MaterialApp(
      title: 'فتاوى الشيخ بن حنيفية زين العابدين',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: localeProvider.locale,
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeScreen(),
    );
  }
}
