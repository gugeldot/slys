import 'package:flutter/material.dart';
import '../../utils/app_styles.dart';
import '../../custom/custom_widgets.dart';
import '../about/about_fn.dart';
import 'main_fn.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import '../settings/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_styles.dart';

final ScrollController scrollController = ScrollController();
final GlobalKey<SeedsTableState> seedsTableKey = GlobalKey<SeedsTableState>();


Widget mainScreen({
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
  required String? selectedSeed,
  required int? selectedSeedIndex,
  required void Function(String seed, int index) onSeedSelected,
  required String? recomposeOutputPath,
  required void Function(String path) onRecomposeOutputPathSelected,
  required String? repeatPassword,
  required TextEditingController repeatPasswordController,
  required void Function(String value) onRepeatPasswordChanged,



  // 👇 Añade esto también:
  required String? recomposePassword,
  required TextEditingController recomposePasswordController,
  required void Function(String value) onRecomposePasswordChanged,
}) {
 return Padding(
    padding: const EdgeInsets.only(left: 12, top: 6),
    child: Scrollbar( 
      controller: scrollController, // 👈 agregado
      thumbVisibility: true,
      child: 
      ListView( 
        controller: scrollController,
      children: [
      Column(
          children: [
            const SizedBox(height: 20),
            WindowContainer(
              borderColor: AppTheme.transpartent, 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader("Fragment"),
                  Text("Select diferent settings of target fragmentation:", style: minitTextStyle(),),
                  const SizedBox(height: 20),
                  TargetFileSelector(
                    currentFilePath: selectedFilePath,
                    onFileSelected: onFileSelected,
                  ),
                  const SizedBox(height: 15),
                  OutputPathSelector(
                    currentPath: selectedOutputPath,
                    onPathSelected: onOutputPathSelected,
                  ),
                  const SizedBox(height: 10),
                  PasswordAndEncryptionOptions(
                    encryptionLevel: encryptionLevel,
                    onEncryptionChanged: onEncryptionLevelChanged,
                    password: password,
                    onPasswordChangedText: onPasswordChangedText,
                    passwordController: passwordController,

                    // 👇 Añadir estos tres para corregir el error:
                    repeatPassword: repeatPassword,
                    repeatPasswordController: repeatPasswordController,
                    onRepeatPasswordChanged: onRepeatPasswordChanged,
                  ),

                  const SizedBox(width: 60),
                  Row(
                    children: [
                      Text(
                        "⚠️ Slys doesn't store this, remember it! ⚠️",
                        style: TextStyle(color: AppTheme.white),
                        ),
                      Spacer(),
                     SliderWidget(
                        currentValue: fragmentSize,
                        onChanged: onFragmentSizeChanged,
                      ),
                      const SizedBox(width: 20),
                    ],
                  ),
                  
                  
                  

                  FragButton(
                    selectedFilePath: selectedFilePath,
                    selectedOutputPath: selectedOutputPath,
                    encryptionLevel: encryptionLevel,
                    password: password,
                    repeatPassword: repeatPassword, // 👈 ¡ESTO!
                    fragmentSize: fragmentSize,
                    onSeedAdded: () => seedsTableKey.currentState?.refreshTable(),
                    onClearFields: () async {
                      final prefs = await SharedPreferences.getInstance();

                      if (!prefs.containsKey(kSelectedOutputPathKey)) {
                        onOutputPathSelected('');
                      }
                      if (!prefs.containsKey(kFragmentSizeKey)) {
                        onFragmentSizeChanged(5);
                      }
                      if (!prefs.containsKey(kEncryptionLevelKey)) {
                        onEncryptionLevelChanged('Total');
                      }

                      onFileSelected('');
                      onPasswordChangedText('');
                      passwordController.clear();
                      repeatPasswordController.clear();
                    },
                  ),
                 
                ],
              )
            ),
            const SizedBox(height: 20),

            WindowContainer(
              borderColor: AppTheme.transpartent, 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Seeds",
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color:  AppTheme.white,
                          ),
                        ),
                       
                        SizedBox(width: 10),
                        
                        

                        Row(children: [
                          // CopyButton
                            if (selectedSeed != null)
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.secondBackground,
                              border: Border.all(color:  AppTheme.white),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                            icon: Icon(Icons.copy, color:  AppTheme.white),
                            tooltip: 'Copy seed to clipboard',
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: selectedSeed!)); // <-- cambio aquí
                              if (ScaffoldMessenger.maybeOf(seedsTableKey.currentContext!) != null) {
                                ScaffoldMessenger.of(seedsTableKey.currentContext!).showSnackBar(
                                  const SnackBar(
                                    content: Text('Seed copied to clipboard'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          ),

                        ),
                         SizedBox(width: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.secondBackground, // Fondo del botón
                              border: Border.all(color:  AppTheme.white), // Borde blanco
                              borderRadius: BorderRadius.circular(8),  // Esquinas redondeadas
                            ),
                            
                            child: IconButton(
                              icon: Icon(Icons.refresh, color:  AppTheme.white),
                              tooltip: 'Refresh Seeds Table',
                              onPressed: () {
                                seedsTableKey.currentState?.refreshTable();
                              },
                            ),
                          ),
                          SizedBox(width: 20),
                        ],),
                        
                        
                      ],
                    ),
                      const SizedBox(height: 4),
                         Divider(
                          color: AppTheme.white,
                          thickness: 1,
                        ),
                        const SizedBox(height: 12),
                  Center(child: 
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: 
                        SeedsTable(
                        key: seedsTableKey,
                        selectedSeed: selectedSeed,
                        selectedIndex: selectedSeedIndex,
                        onSeedSelected: onSeedSelected,
                      )
                    ),
                    
                  ),
                  const SizedBox(height: 10,),
                  if (selectedSeed != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 35.0),
                    child: 
                    Padding(padding: const EdgeInsets.only(right: 35.0), 
                    child: 
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: selectedSeed != null
                              ? () async {
                                  String? picked = await FilePicker.platform.getDirectoryPath();
                                  if (picked != null) {
                                    onRecomposeOutputPathSelected(picked);
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondBackground,
                            foregroundColor:  AppTheme.white,
                            side:  BorderSide(color: AppTheme.white),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text("Browse"),
                        ),
                        SizedBox(width: 10,),
                        Text(
                          "Where are the slices?:",
                          style: TextStyle(fontWeight: FontWeight.bold, color:  AppTheme.white),
                        ),
                        const SizedBox(width: 10),
                        Text(
                            recomposeOutputPath ?? "No path selected",
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(color:  AppTheme.white),
                          ),
                       
                      ],
                    ),),
                  ),
                  SizedBox(height: 15,),
                  Row(
                      children: [
                        SizedBox(
                          width: 180,
                          child: TextField(
                            controller: recomposePasswordController,
                            obscureText: true,
                            onChanged: onRecomposePasswordChanged,
                            enabled: selectedSeed != null, // 👈 Aquí lo inhabilitas si no hay seed
                            style:  TextStyle(color:  AppTheme.white),
                            decoration:  InputDecoration(
                              hintText: 'Password',
                              hintStyle: TextStyle(color: AppTheme.shadow),
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),
                        RecomposeButton(
                          seed: selectedSeed,
                          password: recomposePassword,
                          onRefreshRequested: () => seedsTableKey.currentState?.refreshTable(),
                          onClearFields: () {
                            recomposePasswordController.clear();
                            onRecomposePasswordChanged('');
                            onSeedSelected('', -1);
                          },
                          inputPath: recomposeOutputPath
                        ),

                        const Spacer(),
                        DeleteSeedButton(
                          seed: selectedSeed,
                          onRefreshRequested: () => seedsTableKey.currentState?.refreshTable(),
                          onClearSelection: () => onSeedSelected('', -1), // 👈 deselect
                        ),


                        const SizedBox(width: 10),
                        AddSeedButton(
                          onRefreshRequested: () => seedsTableKey.currentState?.refreshTable(),
                        ),

                        const SizedBox(width: 12),
                      ],
                    ),



                ],
              )
            ),

            
            const SizedBox(height: 20),
          ],
        )
    ]
  )));
}