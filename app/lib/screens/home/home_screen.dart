import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../custom/theme.dart';
import 'homeInmediateWidgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/app_styles.dart';
import '../../utils/utils.dart';
import '../settings/settings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();

}

class _HomeScreenState extends State<HomeScreen> {
  int selectedTabIndex = 0;
  int fragmentSize = 5; 

  String? selectedFilePath;
  String? selectedOutputPath;
  String encryptionLevel = 'Total';
  String? password;
  String? selectedSeedGlobal;
  int? selectedSeedIndexGlobal;
  String? recomposePassword;
  String? selectedRecomposeOutputPath;
  String? repeatPassword;
  final TextEditingController repeatPasswordController = TextEditingController();


  final TextEditingController recomposePasswordController = TextEditingController();


  final TextEditingController passwordController = TextEditingController();

  Future<void> refreshPrefsFromStorage() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      selectedOutputPath = prefs.getString('selectedOutputPath')?? null;
      selectedRecomposeOutputPath = prefs.getString('selectedRecomposeOutputPath') ?? null;
      fragmentSize = prefs.getInt('fragmentSize') ?? 5;
      encryptionLevel = prefs.getString('encryptionLevel') ?? 'Total';
    });
  }

    Future<bool> hasRecomposePathInPrefs() async {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('selectedRecomposeOutputPath');
      return saved != null && saved.isNotEmpty;
    }



@override
void initState() {
  super.initState();

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedOutputPath = prefs.getString(kSelectedOutputPathKey);
      selectedRecomposeOutputPath = prefs.getString(kRecomposeOutputPathKey);
      fragmentSize = prefs.getInt(kFragmentSizeKey) ?? 5;
      encryptionLevel = prefs.getString(kEncryptionLevelKey) ?? 'Total';
    });

    final filePath = await loadSelectedFilePath();
    setState(() {
      selectedFilePath = filePath;
    });
  });

  passwordController.text = password ?? '';
  recomposePasswordController.text = recomposePassword ?? '';
}








  static const _tabs = [
    (label: 'Home', icon: Icons.home_outlined),
    (label: 'Settings', icon: Icons.settings_outlined),
    (label: 'Tutorial', icon: Icons.menu_book_outlined),
    (label: 'About', icon: Icons.info_outline),
  ];

  Future<void> _selectTab(int index) async {
    setState(() => selectedTabIndex = index);
    // Back on Home: pick up defaults changed in Settings.
    if (index == 0) await refreshPrefsFromStorage();
  }

  Widget _tabBar() {
    return LayoutBuilder(builder: (context, c) {
      final showIcons = c.maxWidth >= 520;
      return Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.lessGrey)),
        ),
        child: Row(
          children: [
            for (var i = 0; i < _tabs.length; i++)
              Expanded(
                child: InkWell(
                  onTap: () => _selectTab(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: selectedTabIndex == i ? AppTheme.accent : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (showIcons) ...[
                          Icon(_tabs[i].icon,
                              size: 18,
                              color: selectedTabIndex == i ? AppTheme.white : AppTheme.shadow),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            _tabs[i].label,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: selectedTabIndex == i ? FontWeight.bold : FontWeight.normal,
                              color: selectedTabIndex == i ? AppTheme.white : AppTheme.shadow,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Repaint when the theme or accent colour changes (they are applied live).
    context.watch<ThemeNotifier>();
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            appHeader(),
            _tabBar(),
            Expanded(
              child: getTabContent(
                selectedTabIndex: selectedTabIndex,
                selectedFilePath: selectedFilePath,
                selectedOutputPath: selectedOutputPath,
                password: password,
                passwordController: passwordController,
                onFileSelected: (path) {
                  setState(() {
                    selectedFilePath = path;
                  });
                },
                onOutputPathSelected: (path) {
                  setState(() {
                    selectedOutputPath = path;
                  });
                },
                onPasswordChangedText: (value) {
                  setState(() {
                    password = value;
                  });
                },
                encryptionLevel: encryptionLevel,
                onEncryptionLevelChanged: (value) {
                  setState(() {
                    encryptionLevel = value ?? 'Total';
                  });
                },
                fragmentSize: fragmentSize,
                onFragmentSizeChanged: (val) {
                  setState(() {
                    fragmentSize = val;
                  });
                },

                // 👇 NUEVO
                selectedSeed: selectedSeedGlobal,
                selectedSeedIndex: selectedSeedIndexGlobal,
                onSeedSelected: (seed, index) async {
                  final shouldClearOutputPath = !(await hasRecomposePathInPrefs());

                  setState(() {
                    selectedSeedGlobal = index == -1 ? null : seed;
                    selectedSeedIndexGlobal = index == -1 ? null : index;

                    if (index == -1) {
                      recomposePasswordController.clear();
                      recomposePassword = null;

                      if (shouldClearOutputPath) {
                        selectedRecomposeOutputPath = null;
                      }
                    }
                  });
                },



                recomposePassword: recomposePassword,
                recomposePasswordController: recomposePasswordController,
                onRecomposePasswordChanged: (value) {
                  setState(() {
                    recomposePassword = value;
                  });
                },

                recomposeOutputPath: selectedRecomposeOutputPath,
                onRecomposeOutputPathSelected: (String newPath) {
                  setState(() {
                    selectedRecomposeOutputPath = newPath;
                  });
                },

                repeatPassword: repeatPassword,
                repeatPasswordController: repeatPasswordController,
                onRepeatPasswordChanged: (value) {
                  setState(() {
                    repeatPassword = value;
                  });
                },

              ),
            ),
          ],
        ),
      ),
    );
  }
}
