import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/default_paths.dart';
import '../../services/file_dialogs.dart';
import '../../utils/app_styles.dart';
import '../../custom/custom_widgets.dart';
import '../main/main_fn.dart' show encryptionOptions, SliderWidget;
import 'inactivity_card.dart';
import '../../custom/theme.dart';
import 'package:provider/provider.dart';

const String kSelectedOutputPathKey = 'selectedOutputPath';
const String kRecomposeOutputPathKey = 'selectedRecomposeOutputPath';
const String kFragmentSizeKey = 'fragmentSize';

/// Pieces a new fragmentation uses unless the user picked another number.
const int kDefaultPieces = 10;
const String kEncryptionLevelKey = 'encryptionLevel';
const String kEndOutputRecomopose = 'endOutputRecomopose';
const String kIsDarkModeKey = 'isDarkMode';
const String kAccentColorKey = 'accentColor';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? selectedOutputPath;
  String? recomposeOutputPath;
  String? endOutputRecomopose;

  int fragmentSize = kDefaultPieces;
  String encryptionLevel = 'Total';

  String accentColor = 'Purple';

  final List<String> accentOptions = [
    'Yellow',
    'Red',
    'Green',
    'Purple',
    'Blue',
  ];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedOutputPath = prefs.getString(kSelectedOutputPathKey);
      recomposeOutputPath = prefs.getString(kRecomposeOutputPathKey);
      endOutputRecomopose = prefs.getString(kEndOutputRecomopose);
      fragmentSize = prefs.getInt(kFragmentSizeKey) ?? kDefaultPieces;
      encryptionLevel = prefs.getString(kEncryptionLevelKey) ?? 'Total';
      AppTheme.isDark = prefs.getBool(kIsDarkModeKey) ?? true;
      accentColor = prefs.getString(kAccentColorKey) ?? 'Purple';
    });
  }

  Future<void> _updatePath(
    String key,
    void Function(String?) setStateCallback,
  ) async {
    String? path = await pickDirectoryPath();
    if (path != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, path);
      setState(() => setStateCallback(path));
    }
  }

  Future<void> _updateFragmentSize(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(kFragmentSizeKey, value);
    setState(() {
      fragmentSize = value;
    });
  }

  Future<void> _updateEncryptionLevel(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value != null) {
      await prefs.setString(kEncryptionLevelKey, value);
      setState(() {
        encryptionLevel = value;
      });
    }
  }

  Widget buildClearButton(String key, void Function() onCleared) {
    return IconButton(
      tooltip: "Clear",
      icon: const Icon(Icons.delete, color: Colors.redAccent),
      onPressed: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(key);
        onCleared();
      },
    );
  }

  String displayPath(String? value) {
    return (value == null || value.isEmpty) ? 'No path selected' : value;
  }

  Widget _pathSetting(
    String label,
    String? value,
    String key,
    void Function(String?) set, {
    String placeholder = 'Not set (Slys will ask each time)',
  }) {
    return PathRow(
      label: label,
      value: value,
      placeholder: placeholder,
      onBrowse: () => _updatePath(key, set),
      extra: buildClearButton(key, () => setState(() => set(''))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeNotifier>().isDarkMode;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          title: 'Appearance',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Dark mode',
                  style: TextStyle(color: AppTheme.white),
                ),
                value: isDarkMode,
                activeColor: AppTheme.accent,
                onChanged: (val) async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool(kIsDarkModeKey, val);
                  if (mounted) context.read<ThemeNotifier>().toggleTheme(val);
                },
              ),
              const SizedBox(height: 8),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Accent colour',
                  labelStyle: TextStyle(color: AppTheme.shadow),
                  isDense: true,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: accentColor,
                    dropdownColor: AppTheme.grey2,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: AppTheme.white),
                    items:
                        accentOptions
                            .map(
                              (opt) => DropdownMenuItem<String>(
                                value: opt,
                                child: Text(opt),
                              ),
                            )
                            .toList(),
                    onChanged: (value) async {
                      if (value == null) return;
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString(kAccentColorKey, value);
                      AppTheme.setAccentColor(value);
                      setState(() => accentColor = value);
                      if (mounted) context.read<ThemeNotifier>().refresh();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const InactivityCard(),
        const SizedBox(height: 16),
        AppCard(
          title: 'Fragment defaults',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Changes apply instantly.', style: minitTextStyle()),
              const SizedBox(height: 14),
              _pathSetting(
                'Default output folder',
                selectedOutputPath,
                kSelectedOutputPathKey,
                (p) => selectedOutputPath = p,
                placeholder: 'Default: ${defaultFragmentsDir()}',
              ),
              const SizedBox(height: 16),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Default encryption',
                  labelStyle: TextStyle(color: AppTheme.shadow),
                  isDense: true,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value:
                        encryptionOptions.containsKey(encryptionLevel)
                            ? encryptionLevel
                            : 'Total',
                    dropdownColor: AppTheme.grey2,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: AppTheme.white),
                    items:
                        encryptionOptions.entries
                            .map(
                              (e) => DropdownMenuItem<String>(
                                value: e.key,
                                child: Text(
                                  e.value,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: _updateEncryptionLevel,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SliderWidget(
                label: 'Default pieces',
                currentValue: fragmentSize,
                onChanged: (v) => setState(() => fragmentSize = v),
                onChangeEnd: _updateFragmentSize,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          title: 'Recompose defaults',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Changes apply instantly.', style: minitTextStyle()),
              const SizedBox(height: 14),
              _pathSetting(
                'Default folder with the pieces',
                recomposeOutputPath,
                kRecomposeOutputPathKey,
                (p) => recomposeOutputPath = p,
                placeholder: 'Default: ${defaultFragmentsDir()}',
              ),
              const SizedBox(height: 16),
              _pathSetting(
                'Where the folder dialog opens for the rebuilt file',
                endOutputRecomopose,
                kEndOutputRecomopose,
                (p) => endOutputRecomopose = p,
                placeholder: 'Default: your Desktop (${desktopDir()})',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
