import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';

import './screens/home/home_screen.dart';
import './screens/settings/settings.dart';
import 'utils/app_styles.dart'; 
import 'custom/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  AppTheme.isDark = prefs.getBool('isDarkMode') ?? true;

  String accentColor = prefs.getString(kAccentColorKey) ?? 'Purple';
  AppTheme.setAccentColor(accentColor);

   runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const MyWidget(),
    ),
  );



  doWhenWindowReady(() {
    final screenSize = window.physicalSize / window.devicePixelRatio;
    final width = screenSize.width;

    Size initialSize;
    Size minSize;

    if (width >= 3840) {
      initialSize = const Size(1600, 1000);
    } else if (width >= 2560) {
      initialSize = const Size(950, 900);
    } else if (width >= 1920) {
      initialSize = const Size(700, 600);
    } else {
      initialSize = const Size(950, 900);
    }

    minSize = const Size(650, 400);

    appWindow.minSize = minSize;
    appWindow.size = initialSize;
    appWindow.alignment = Alignment.center;
    appWindow.title = "";
    appWindow.show();
  });
}

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeNotifier>(context).isDarkMode;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: isDark ? ThemeData.dark() : ThemeData.light(),
      home: const HomeScreen(),
    );
  }
}

