import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {
  static const _key = 'selected_locale';
  Locale _locale = const Locale('th');
  Locale get locale => _locale;

  Future<void> load() async {
    final code =
        (await SharedPreferences.getInstance()).getString(_key) ?? 'th';
    _locale = Locale(code);
  }

  Future<void> setLocale(String code) async {
    _locale = Locale(code);
    notifyListeners();
    await (await SharedPreferences.getInstance()).setString(_key, code);
  }
}

final localeController = LocaleController();
