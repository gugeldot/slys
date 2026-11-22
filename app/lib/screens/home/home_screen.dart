import 'package:flutter/material.dart';
import 'homeInmediateWidgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/app_styles.dart';
import '../../custom/custom_widgets.dart';
import '../../utils/utils.dart';
import '../settings/settings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();

}

class _HomeScreenState extends State<HomeScreen> {
  double heightAppBar = 100;
  double heightTabBar = 25;
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








  // Function for setting tabs
Widget _tabButton(String text, int index) {
  final isSelected = selectedTabIndex == index;

  return GestureDetector(
    onTap: () async {
      setState(() {
        selectedTabIndex = index;
      });

      // Si volvió a la pestaña "Home", actualizá el path desde prefs
      if (index == 0) {
        await refreshPrefsFromStorage();
      }
    },
    child: Container(
      width: 100,
      height: 50,
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.lessWhite : AppTheme.secondBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border.all(color: AppTheme.black),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ?  AppTheme.black :  AppTheme.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // Appbar
          appBarCustom(),
          // visual con el resto del alto
          bannerPostAppbar(heightAppBar),
          // TabBar
          WindowContainer(
            height: heightTabBar,
            borderColor: AppTheme.transpartent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MouseRegion(
                cursor: SystemMouseCursors.click,
                child: _tabButton("Home", 0),),
                SizedBox(width: 10),
                
               
                MouseRegion(
                cursor: SystemMouseCursors.click,
                child: _tabButton("Settings", 1)),
                SizedBox(width: 10),
                
                MouseRegion(
                cursor: SystemMouseCursors.click,
                child: _tabButton("Tutorial", 3)),
                SizedBox(width: 10),
                
                MouseRegion(
                cursor: SystemMouseCursors.click,
                child: _tabButton("About", 2)),
                

                
              ],
            ),
          ),
          Expanded(
            child: WindowContainer(
              // Selector de partes del main container
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

            

          ),
        ],
      ),
    );
  }
}
