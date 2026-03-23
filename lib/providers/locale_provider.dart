import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('ar');

  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';

  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('language') ?? 'ar';
    _locale = Locale(lang);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', locale.languageCode);
    notifyListeners();
  }

  Future<void> toggleLocale() async {
    if (_locale.languageCode == 'ar') {
      await setLocale(const Locale('en'));
    } else {
      await setLocale(const Locale('ar'));
    }
  }
}
