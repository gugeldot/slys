import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';

import './screens/home/home_screen.dart';
import './screens/settings/settings.dart';
import 'utils/app_styles.dart';
import 'custom/theme.dart';
import 'src/rust/api/storage.dart';
import 'src/rust/frb_generated.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();

  // Opt-in inactivity wipe: must run before anything touches the seed list.
  try {
    inactivityEnforceAndTouch();
  } catch (_) {
    // Never block startup because of the local state file.
  }

  final prefs = await SharedPreferences.getInstance();
  // 1.6 changed the default to High: the old default (Mid) leaves most of the file readable.
  if (!(prefs.getBool('migrated_1_6') ?? false)) {
    await prefs.setString(kEncryptionLevelKey, 'Total');
    await prefs.setBool('migrated_1_6', true);
  }
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

