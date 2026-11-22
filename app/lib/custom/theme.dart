import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../utils/app_styles.dart';

const String kIsDarkModeKey = 'isDarkMode';

class ThemeNotifier extends ChangeNotifier {
  bool get isDarkMode => AppTheme.isDark;

  void toggleTheme(bool isDarkMode) {
    AppTheme.isDark = isDarkMode;
    notifyListeners();
  }
  
}

