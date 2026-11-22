import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './screens/home/home_screen.dart';
import './screens/settings/settings.dart';
import 'utils/app_styles.dart';
import 'custom/theme.dart';
import 'services/startup_state.dart';
import 'src/rust/api/storage.dart';
import 'src/rust/frb_generated.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();

  // Opt-in inactivity wipe: must run before anything touches the seed list.
  try {
    inactivityWipedAtStartup = inactivityEnforceAndTouch();
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
}

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeNotifier>(context).isDarkMode;

    final brightness = isDark ? Brightness.dark : Brightness.light;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SLYS',
      theme: ThemeData(
        brightness: brightness,
        colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.accent, brightness: brightness),
        scaffoldBackgroundColor: AppTheme.background,
      ),
      home: const HomeScreen(),
    );
  }
}

