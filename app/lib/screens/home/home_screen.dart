import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../custom/theme.dart';
import 'homeInmediateWidgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/app_styles.dart';
import '../../utils/utils.dart';
import '../../services/default_paths.dart';
import '../../services/operation_runner.dart';
import '../../services/startup_state.dart';
import '../settings/settings.dart';

/// How long the slide between tabs takes.
const Duration _kSlide = Duration(milliseconds: 300);

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
      if (inactivityWipedAtStartup && mounted) {
        inactivityWipedAtStartup = false;
        await showMessage(
          context,
          'Saved seeds erased',
          'SLYS was not opened for the number of days set in the inactivity wipe, so the list of saved '
              'seeds was erased. Your pieces were not touched. Add a seed again from the Recompose tab '
              'to rebuild a file.',
        );
      }
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

  int _slideDirection =
      1; // 1: the new tab comes from the right, -1: from the left
  bool _switching = false;
  Timer? _switchTimer;

  @override
  void dispose() {
    _switchTimer?.cancel();
    super.dispose();
  }

  Future<void> _selectTab(int index) async {
    // Ignore taps while the previous slide is still running: two copies of the same page
    // (and their GlobalKeys) must not exist at once.
    if (index == selectedTabIndex || _switching) return;
    _switching = true;
    _switchTimer = Timer(
      _kSlide + const Duration(milliseconds: 40),
      () => _switching = false,
    );
    _slideDirection = index > selectedTabIndex ? 1 : -1;
    final cameFromSettings = selectedTabIndex == 2;
    setState(() => selectedTabIndex = index);
    // Back from Settings: pick up the defaults that may have changed there. (Switching between
    // Fragment and Recompose keeps whatever you already picked.)
    if (cameFromSettings && index <= 1) await refreshPrefsFromStorage();
  }

  /// Pages slide like a carousel: the new one pushes the old one out, side by side.
  Widget _slidingTab(Widget content) => _TabSlider(
    index: selectedTabIndex,
    direction: _slideDirection,
    child: content,
  );

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
              child: _slidingTab(
                getTabContent(
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
            ),
          ],
        ),
      ),
    );
  }
}

/// Slides between pages. Both pages are opaque and move together with one curve, so they sit side
/// by side (the new one pushes the old one out) instead of fading through each other.
class _TabSlider extends StatefulWidget {
  final int index;
  final int
  direction; // 1: the new page comes from the right, -1: from the left
  final Widget child;

  const _TabSlider({
    required this.index,
    required this.direction,
    required this.child,
  });

  @override
  State<_TabSlider> createState() => _TabSliderState();
}

class _TabSliderState extends State<_TabSlider>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _kSlide,
  );
  Widget? _outgoing;
  int _outgoingIndex = 0;
  int _direction = 1;

  @override
  void didUpdateWidget(_TabSlider old) {
    super.didUpdateWidget(old);
    if (old.index == widget.index) return;
    // Keep the page we are leaving (as it was) until the slide ends.
    _outgoing = old.child;
    _outgoingIndex = old.index;
    _direction = widget.direction;
    _controller.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _outgoing = null);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _page(
    int index,
    Widget child,
    Offset offset, {
    bool interactive = true,
  }) {
    return FractionalTranslation(
      key: ValueKey('tab-page-$index'),
      translation: offset,
      child: IgnorePointer(
        ignoring: !interactive,
        // Opaque: nothing of the other page shows through.
        child: ColoredBox(color: AppTheme.background, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = Curves.easeInOutCubic.transform(_controller.value);
          final sliding = _outgoing != null;
          return Stack(
            fit: StackFit.expand,
            children: [
              if (sliding)
                _page(
                  _outgoingIndex,
                  _outgoing!,
                  Offset(-_direction * t, 0),
                  interactive: false,
                ),
              _page(
                widget.index,
                widget.child,
                sliding ? Offset(_direction * (1 - t), 0) : Offset.zero,
              ),
            ],
          );
        },
      ),
    );
  }
}
