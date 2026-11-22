import 'package:flutter/material.dart';

class AppTheme {
  static bool isDark = true; // Default
  static const double normalTextSize = 17;
  static const double boldTextSize = 19;

  static Color get background => isDark ? const Color(0xFF121212) : const Color(0xFFFFFFFF);
  static Color get window_background => isDark ? const Color(0xFF020202) : const Color(0xFFF0F0F0);
  static Color get secondBackground => isDark ? const Color(0xFF222222) : const Color(0xFFE0E0E0);
  static Color get primary => const Color(0xFFeeff00);
  //static Color get accent => const Color(0xFF8800E3);
  static Color get secondary => const Color.fromARGB(255, 255, 153, 0);
  static Color get lessWhite => isDark ? const Color(0xFFBBBBBB) : const Color(0xFF444444);
  static Color get lessGrey => isDark ? const Color(0xFF333333) : const Color(0xFFCCCCCC);
  static Color get grey => isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA);
  static Color get transpartent => Colors.transparent;
  static Color get white => isDark ? Colors.white : Colors.black;
  static Color get black => isDark ? Colors.black : Colors.white;
  static Color get grey2 => isDark ? const Color.fromARGB(255, 33, 33,33): const Color.fromARGB(200, 177, 177,177) ;
  static Color get black3 => isDark ? Colors.white24 : Colors.black;
  static Color get shadow => isDark ? Colors.white54 : const Color.fromARGB(255, 33, 33,33);
  static Color _accentColor = const Color(0xFF8800E3); // Default (morado)

  static Color get accent => _accentColor;

  /// Text colour that stays readable on top of the accent colour (yellow needs dark text).
  static Color get onAccent =>
      ThemeData.estimateBrightnessForColor(_accentColor) == Brightness.dark ? Colors.white : Colors.black;

  static void setAccentColor(String colorName) {
    switch (colorName) {
      case 'Red':
        _accentColor = Colors.red;
        break;
      case 'Yellow':
        _accentColor = Colors.yellow;
        break;
      case 'Green':
        _accentColor = Colors.green;
        break;
      case 'Blue':
        _accentColor = Colors.blue;
        break;
      case 'Purple':
      default:
        _accentColor = const Color(0xFF8800E3);
        break;
    }
  }

}

TextStyle minitTextStyle() {
  return TextStyle(
    color: AppTheme.white,
    fontSize: AppTheme.normalTextSize - 2,
  );
}


TextStyle defaultTextStyle() {
  return TextStyle(
    color: AppTheme.white,
    height: 1.5,
    fontSize: AppTheme.normalTextSize,
  );
}

TextStyle boldDefaultTextStyle() {
  return TextStyle(
    color:AppTheme.white,
    height: 1.5,
    fontWeight: FontWeight.bold,
    fontSize: AppTheme.boldTextSize,
  );
}
