import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String THEME_KEY = 'theme_mode';
  static const String LANGUAGE_KEY = 'language';
  static const String QR_SIZE_KEY = 'qr_size';
  static const String AUTO_COPY_KEY = 'auto_copy';
  static const String DEFAULT_AMOUNT_KEY = 'default_amount';

  ThemeMode _themeMode = ThemeMode.dark;
  String _language = 'en';
  double _qrSize = 250; // medium
  bool _autoCopy = false;
  String _defaultAmount = '';

  ThemeMode get themeMode => _themeMode;
  String get language => _language;
  double get qrSize => _qrSize;
  bool get autoCopy => _autoCopy;
  String get defaultAmount => _defaultAmount;

  ThemeProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load theme
    final isDark = prefs.getBool(THEME_KEY) ?? true;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    
    // Load language
    _language = prefs.getString(LANGUAGE_KEY) ?? 'en';
    
    // Load QR size
    _qrSize = prefs.getDouble(QR_SIZE_KEY) ?? 250;
    
    // Load auto copy
    _autoCopy = prefs.getBool(AUTO_COPY_KEY) ?? false;
    
    // Load default amount
    _defaultAmount = prefs.getString(DEFAULT_AMOUNT_KEY) ?? '';
    
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(THEME_KEY, mode == ThemeMode.dark);
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(LANGUAGE_KEY, lang);
  }

  Future<void> setQrSize(double size) async {
    _qrSize = size;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(QR_SIZE_KEY, size);
  }

  Future<void> setAutoCopy(bool value) async {
    _autoCopy = value;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AUTO_COPY_KEY, value);
  }

  Future<void> setDefaultAmount(String amount) async {
    _defaultAmount = amount;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(DEFAULT_AMOUNT_KEY, amount);
  }

  void toggleTheme() {
    setThemeMode(_themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}