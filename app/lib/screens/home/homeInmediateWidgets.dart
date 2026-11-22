
import 'package:flutter/material.dart';

import '../about/aboutInmediateWidgets.dart';
import '../../utils/app_styles.dart';
import '../main/mainInmediateWidgets.dart';
import '../tutorial/tutorial.dart';
import '../settings/settings.dart';
import '../../src/rust/api/version.dart';

Widget getTabContent({
  required int selectedTabIndex,
  required String? selectedFilePath,
  required void Function(String path) onFileSelected,
  required String? selectedOutputPath,
  required void Function(String path) onOutputPathSelected,
  required String encryptionLevel,
  required void Function(String? value) onEncryptionLevelChanged,
  required String? password,
  required void Function(String value) onPasswordChangedText,
  required TextEditingController passwordController,
  required int fragmentSize,
  required ValueChanged<int> onFragmentSizeChanged,
  
  // 👇 NUEVO
  required String? selectedSeed,
  required int? selectedSeedIndex,
  required void Function(String seed, int index) onSeedSelected,
  required String? recomposePassword,
  required TextEditingController recomposePasswordController,
  required void Function(String) onRecomposePasswordChanged,
    required String? recomposeOutputPath,
  required void Function(String path) onRecomposeOutputPathSelected,

  required String? repeatPassword,
  required TextEditingController repeatPasswordController,
  required void Function(String path) onRepeatPasswordChanged,
})
 {
    switch (selectedTabIndex) {
      case 0:
        return mainScreen(
          selectedFilePath: selectedFilePath,
          onFileSelected: onFileSelected,
          selectedOutputPath: selectedOutputPath,
          onOutputPathSelected: onOutputPathSelected,
          encryptionLevel: encryptionLevel,
          onEncryptionLevelChanged: onEncryptionLevelChanged,
          password: password,
          onPasswordChangedText: onPasswordChangedText,
          passwordController: passwordController,
          fragmentSize: fragmentSize,
          onFragmentSizeChanged: onFragmentSizeChanged,

          selectedSeed: selectedSeed,
          selectedSeedIndex: selectedSeedIndex,
          onSeedSelected: onSeedSelected,
          recomposePassword: recomposePassword,
          recomposePasswordController: recomposePasswordController,
          onRecomposePasswordChanged: onRecomposePasswordChanged,
          recomposeOutputPath: recomposeOutputPath,
          onRecomposeOutputPathSelected: onRecomposeOutputPathSelected,
          repeatPassword: repeatPassword,
          repeatPasswordController: repeatPasswordController,
          onRepeatPasswordChanged:onRepeatPasswordChanged,
          
        );


      case 1:
        return _page(const SettingsScreen());
      case 2:
        return _page(SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Center(
              child: Image.asset(
                AppTheme.isDark ? 'assets/images/logQT.png' : 'assets/images/logQTINV.png',
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
            tutorialScreen(),
          ]),
        ));
      case 3:
        return _page(SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              imageBlock(),
              const SizedBox(height: 24),
              whyTextBlock(),
              const SizedBox(height: 26),
              capabilitiesTextBlock(),
              const SizedBox(height: 24),
              ackTextBlock(),
              const SizedBox(height: 24),
              legalNoticeBlock(),
              const SizedBox(height: 24),
              paypalButton(),
            ],
          ),
        ));
      default:
        return Container();
    }
  }

/// Reading pages (settings, tutorial, about) stay centred and not wider than 860 px.
Widget _page(Widget child) {
  return Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 860), child: child),
  );
}

/// Slim header: logo, name and version. It shrinks gracefully; there is no fake window bar,
/// the operating system draws the real one.
Widget appHeader() {
  String version = '';
  try {
    version = 'v${versionInfo().version}';
  } catch (_) {}
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    color: AppTheme.window_background,
    child: Row(
      children: [
        Image.asset(
          AppTheme.isDark ? 'assets/images/logo_inv.png' : 'assets/images/logo.png',
          height: 36,
          width: 36,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Slys Desktop',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.white),
          ),
        ),
        Text(version, style: minitTextStyle()),
      ],
    ),
  );
}
