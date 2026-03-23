import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'providers/fatwa_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  final localeProvider = LocaleProvider();
  await localeProvider.loadLocale();

  final fatwaProvider = FatwaProvider();
  // Load API key from shared preferences
  final prefs = await SharedPreferences.getInstance();
  final apiKey = prefs.getString('groq_api_key') ??
      dotenv.env['GROQ_API_KEY'] ??
      '';
  if (apiKey.isNotEmpty) {
    fatwaProvider.setApiKey(apiKey);
  }

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
