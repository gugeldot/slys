import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../../utils/app_styles.dart';
import '../about/about_fn.dart';
import '../../custom/theme.dart';
import 'package:provider/provider.dart';
import 'dart:io';


const String kSelectedOutputPathKey = 'selectedOutputPath';
const String kRecomposeOutputPathKey = 'selectedRecomposeOutputPath';
const String kFragmentSizeKey = 'fragmentSize';
const String kEncryptionLevelKey = 'encryptionLevel';
const String kEndOutputRecomopose = 'endOutputRecomopose';
const String kWindowWidthKey = 'customWindowWidth';
const String kWindowHeightKey = 'customWindowHeight';
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

  int fragmentSize = 5;
  String encryptionLevel = 'Partial';

  final List<String> encryptionOptions = ['None', 'Partial', 'Total'];
  String accentColor = 'Purple';

  final List<String> accentOptions = ['Yellow', 'Red', 'Green', 'Purple', 'Blue'];

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
      fragmentSize = prefs.getInt(kFragmentSizeKey) ?? 5;
      encryptionLevel = prefs.getString(kEncryptionLevelKey) ?? 'Partial';
      AppTheme.isDark = prefs.getBool(kIsDarkModeKey) ?? true;
      accentColor = prefs.getString(kAccentColorKey) ?? 'Purple';


    });
  }

  Future<void> _updatePath(String key, void Function(String?) setStateCallback) async {
    String? path = await FilePicker.platform.getDirectoryPath();
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

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = context.watch<ThemeNotifier>().isDarkMode;
    return Padding(
      padding: const EdgeInsets.all(14),
      child: ListView(
        children: [
          SectionHeader("General settings (App will close to apply changes)"),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text("• Dark Mode", style: minitTextStyle()),
                  const SizedBox(width: 12),
                  Switch(
                    value: isDarkMode,
                    activeColor: AppTheme.accent,
                    onChanged: (val) async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool(kIsDarkModeKey, val);

                      if (mounted) {
                        context.read<ThemeNotifier>().toggleTheme(val);
                      }

                      await Future.delayed(const Duration(milliseconds: 100));
                      exit(0);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text("• Accent Color:", style: minitTextStyle()),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: accentColor,
                    dropdownColor: AppTheme.grey2,
                    style: TextStyle(color: AppTheme.white),
                    items: accentOptions.map((opt) {
                      return DropdownMenuItem<String>(
                        value: opt,
                        child: Text(opt),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      if (value != null) {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString(kAccentColorKey, value);

                        AppTheme.setAccentColor(value);
                        await Future.delayed(const Duration(milliseconds: 100));
                        exit(0);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),


          

          SectionHeader("Fragment settings (Changes applied instantly)"),
          const SizedBox(height: 16),

          // Output Path
          Text("• Default Output Path:", style: minitTextStyle()),
          Row(
            children: [
              Expanded(child: Text(displayPath(selectedOutputPath), style: minitTextStyle())),
              ElevatedButton(
                onPressed: () => _updatePath(kSelectedOutputPathKey, (p) => selectedOutputPath = p),
                child: const Text("Browse"),
                style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.secondBackground,         // Fondo del botón
            foregroundColor: AppTheme.white,              // Color del texto
            side: BorderSide(color: AppTheme.white),// Borde del botón
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),   // Esquinas redondeadas (opcional)
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Padding interno
          ),
              ),
              buildClearButton(kSelectedOutputPathKey, () {
                setState(() => selectedOutputPath = '');
              }),
            ],
          ),
          const SizedBox(height: 20),

          

          // Fragment Size
        

          // Encryption Level
          Text("• Default Encryption Level:", style: minitTextStyle()),
            Row(
              children: [
                DropdownButton<String>(
                  value: encryptionLevel,
                  dropdownColor: AppTheme.grey2,
                  style: TextStyle(color: AppTheme.white),
                  items: encryptionOptions.map((opt) {
                    final Map<String, String> labels = {
                      'None': 'None (Fast & Unsafe)',
                      'Partial': 'Mid (Optimal)',
                      'Total': 'High (Slow & Safer)',
                    };
                    return DropdownMenuItem<String>(
                      value: opt,
                      child: Text(labels[opt] ?? opt),
                    );
                  }).toList(),
                  onChanged: _updateEncryptionLevel,
                ),
                Spacer(),
                buildClearButton(kEncryptionLevelKey, () {
                  setState(() => encryptionLevel = 'Partial');
                }),
              ],
            ),

          const SizedBox(height: 20),

          

            // Fragment Size
        Text("• Default Fragment Size:", style: minitTextStyle()),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Slider(
                    value: fragmentSize.toDouble(),
                    min: 5,
                    max: 100,
                    //divisions: 95,
                    label: "$fragmentSize",
                    activeColor: AppTheme.accent,
                    inactiveColor: AppTheme.white,
                    onChanged: (double value) {
                      _updateFragmentSize(value.toInt());
                    },
                  ),
                  Text(
                    "Slices: $fragmentSize",
                    style:  TextStyle(color: AppTheme.white),
                  ),
                ],
              ),
            ),
            buildClearButton(kFragmentSizeKey, () {
              setState(() => fragmentSize = 5);
            }),
          ],
        ),


          const SizedBox(height: 20),


          SectionHeader("Recompose settings (Changes applied instantly)"),
           // Recompose Input Path
          Text("• Default \"Where are the slices?\":", style: minitTextStyle()),
          Row(
            children: [
              Expanded(child: Text(displayPath(recomposeOutputPath), style: minitTextStyle())),
              ElevatedButton(
                onPressed: () => _updatePath(kRecomposeOutputPathKey, (p) => recomposeOutputPath = p),
                child: const Text("Browse"),
                style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.secondBackground,         // Fondo del botón
            foregroundColor: AppTheme.white,              // Color del texto
            side: BorderSide(color: AppTheme.white),// Borde del botón
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),   // Esquinas redondeadas (opcional)
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Padding interno
          ),
              ),
              buildClearButton(kRecomposeOutputPathKey, () {
                setState(() => recomposeOutputPath = '');
              }),
            ],
          ),
          const SizedBox(height: 20),
          // Recompose Output Path
          Text("• Default Path for Recomposed File:", style: minitTextStyle()),
          Row(
            children: [
              Expanded(child: Text(displayPath(endOutputRecomopose), style: minitTextStyle())),
              ElevatedButton(
                onPressed: () => _updatePath(kEndOutputRecomopose, (p) => endOutputRecomopose = p),
                child: const Text("Browse"),
                style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.secondBackground,         // Fondo del botón
            foregroundColor: AppTheme.white,              // Color del texto
            side: BorderSide(color: AppTheme.white),// Borde del botón
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),   // Esquinas redondeadas (opcional)
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Padding interno
          ),
              ),
              buildClearButton(kEndOutputRecomopose, () {
                setState(() => endOutputRecomopose = '');
              }),
            ],
          ),
          
         
          const SizedBox(height: 20),
          

          
        ],
      ),
    );
  }
}

