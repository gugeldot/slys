import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../custom/theme.dart';
import 'homeInmediateWidgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/app_styles.dart';
import '../../utils/utils.dart';
import '../../services/default_paths.dart';
import '../settings/settings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedTabIndex = 0;
  int fragmentSize = kDefaultPieces;

  String? selectedFilePath;
  String? selectedOutputPath;
  String encryptionLevel = 'Total';
  String? password;
  String? selectedSeedGlobal;
  int? selectedSeedIndexGlobal;
  String? recomposePassword;
  String? selectedRecomposeOutputPath;
  String? repeatPassword;
  final TextEditingController repeatPasswordController =
      TextEditingController();

  final TextEditingController recomposePasswordController =
      TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  /// A saved folder, or `<Desktop>/slys_fragments` when none was ever chosen.
  String _pathOrDefault(String? saved) =>
      (saved == null || saved.isEmpty) ? defaultFragmentsDir() : saved;

  Future<void> refreshPrefsFromStorage() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      selectedOutputPath = _pathOrDefault(
        prefs.getString(kSelectedOutputPathKey),
      );
      selectedRecomposeOutputPath = _pathOrDefault(
        prefs.getString(kRecomposeOutputPathKey),
      );
      fragmentSize = prefs.getInt(kFragmentSizeKey) ?? kDefaultPieces;
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
        selectedOutputPath = _pathOrDefault(
          prefs.getString(kSelectedOutputPathKey),
        );
        selectedRecomposeOutputPath = _pathOrDefault(
          prefs.getString(kRecomposeOutputPathKey),
        );
        fragmentSize = prefs.getInt(kFragmentSizeKey) ?? kDefaultPieces;
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
    (label: 'Fragment', icon: Icons.call_split),
    (label: 'Recompose', icon: Icons.restore),
    (label: 'Settings', icon: Icons.settings_outlined),
    (label: 'Tutorial', icon: Icons.menu_book_outlined),
    (label: 'About', icon: Icons.info_outline),
  ];

  Future<void> _selectTab(int index) async {
    final cameFromSettings = selectedTabIndex == 2;
    setState(() => selectedTabIndex = index);
    // Back from Settings: pick up the defaults that may have changed there. (Switching between
    // Fragment and Recompose keeps whatever you already picked.)
    if (cameFromSettings && index <= 1) await refreshPrefsFromStorage();
  }

  Widget _tabBar() {
    return LayoutBuilder(
      builder: (context, c) {
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
                            color:
                                selectedTabIndex == i
                                    ? AppTheme.accent
                                    : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (showIcons) ...[
                            Icon(
                              _tabs[i].icon,
                              size: 18,
                              color:
                                  selectedTabIndex == i
                                      ? AppTheme.white
                                      : AppTheme.shadow,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                            child: Text(
                              _tabs[i].label,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: showIcons ? 14 : 12.5,
                                fontWeight:
                                    selectedTabIndex == i
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                color:
                                    selectedTabIndex == i
                                        ? AppTheme.white
                                        : AppTheme.shadow,
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
      },
    );
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
                  final shouldClearOutputPath =
                      !(await hasRecomposePathInPrefs());

                  setState(() {
                    selectedSeedGlobal = index == -1 ? null : seed;
                    selectedSeedIndexGlobal = index == -1 ? null : index;

                    if (index == -1) {
                      recomposePasswordController.clear();
                      recomposePassword = null;

                      if (shouldClearOutputPath) {
                        selectedRecomposeOutputPath = defaultFragmentsDir();
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
