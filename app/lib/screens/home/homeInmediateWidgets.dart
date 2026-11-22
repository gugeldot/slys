
import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'dart:io';
import 'package:intl/intl.dart';

import '../../custom/custom_widgets.dart';
import '../about/aboutInmediateWidgets.dart';
import '../../utils/app_styles.dart';
import '../main/mainInmediateWidgets.dart';
import '../tutorial/tutorial.dart';
import '../settings/settings.dart';

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
        return const SettingsScreen(); 
      case 2:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
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
        );
      case 3:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Center( 
                child: Image.asset(
                  AppTheme.isDark 
                        ? 'assets/images/logQT.png'
                        : 'assets/images/logQTINV.png',
                  height: 120,
                  fit: BoxFit.cover,
                ),),

            tutorialScreen(),
            ])
        );
      default:
        return Container();
    }
  }



Widget appBarCustom() {
  return WindowTitleBarBox(
            child: SizedBox(
              height: 40,
              child: Row(
                children: [
                  Expanded(
                    child: MoveWindow(
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Text(
                            "Slys",
                            style: TextStyle(
                              color: AppTheme.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      windowActionButton(() {
                        appWindow.minimize();
                      }, Icons.minimize),
                      windowActionButton(() {
                        appWindow.maximizeOrRestore();
                      }, Icons.check_box_outline_blank_sharp),
                      windowActionButton(() {
                        appWindow.close();
                      }, Icons.close),
                    ],
                  ),
                ],
              ),
            ),
          );
}

Widget bannerPostAppbar(double heightAppBar){
  return Container(
            height: heightAppBar,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.window_background,
              border: Border.all(color: AppTheme.black, width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // IZQUIERDA
                Row(
                  children: [
                    Image.asset(
                      AppTheme.isDark 
                        ? 'assets/images/logo_inv.png' 
                        : 'assets/images/logo.png',
                      height: 50,
                      width: 50,
                    ),

                    const SizedBox(width: 8),
                    Text(
                      "Slys Desktop",
                      style: TextStyle(fontSize: 18, color: AppTheme.white),
                    ),
                  ],
                ),

                // DERECHA
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat('dd/MM/yyyy – HH:mm').format(DateTime.now()),
                      style:  TextStyle(color: AppTheme.white),
                    ),
                    Text(
                      'Host: ${Platform.localHostname}',
                      style:  TextStyle(color: AppTheme.white),
                    ),
                    Text(
                      'OS: ${Platform.operatingSystem}',
                      style: TextStyle(color: AppTheme.white),
                    ),
                  ],
                ),
              ],
            ),
          );
}