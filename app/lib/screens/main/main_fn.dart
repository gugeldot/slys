
import 'package:flutter/material.dart';
import '../../services/file_dialogs.dart';
import '../../utils/app_styles.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/operation_runner.dart';
import '../../src/rust/api/operations.dart';
import '../../src/rust/api/storage.dart';


/// Keys are the values stored in preferences since 1.x; they map to the core's modes.
final Map<String, String> encryptionOptions = {
          'Total': 'High (Recommended)',
          'Partial': 'Mid (Light: leaves most data readable)',
          'None': 'None (Obfuscation only)',
        };

EncryptionMode encryptionModeFromKey(String key) {
  switch (key) {
    case 'Partial':
      return EncryptionMode.light;
    case 'None':
      return EncryptionMode.plain;
    default:
      return EncryptionMode.full;
  }
}

class TargetFileSelector extends StatefulWidget {
  final void Function(String path) onFileSelected;
  final String? currentFilePath; // <-- Para mostrar el archivo actual

  const TargetFileSelector({
    super.key,
    required this.onFileSelected,
    this.currentFilePath,
  });

  @override
  State<TargetFileSelector> createState() => _TargetFileSelectorState();
}

class _TargetFileSelectorState extends State<TargetFileSelector> {
  void _pickFile() async {
    final path = await pickFilePath();

    if (path != null) {
      widget.onFileSelected(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          "+ Target file:   ",
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.white),
        ),
        const SizedBox(width: 10),

        Expanded(
          child: Text(
            widget.currentFilePath ?? "No file selected",
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(color: AppTheme.white),
          ),
        ),

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.secondBackground,         // Fondo del botón
            foregroundColor: AppTheme.white,              // Color del texto
            side: BorderSide(color: AppTheme.white),// Borde del botón
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),   // Esquinas redondeadas (opcional)
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Padding interno
          ),
          onPressed: _pickFile,
          child: const Text("Browse"),
        ),
        const SizedBox(width: 10),

        
      ],
    );
  }
}



class OutputPathSelector extends StatefulWidget {
  final void Function(String path) onPathSelected;
  final String? currentPath;

  const OutputPathSelector({
    super.key,
    required this.onPathSelected,
    this.currentPath,
  });

  @override
  State<OutputPathSelector> createState() => _OutputPathSelectorState();
}

class _OutputPathSelectorState extends State<OutputPathSelector> {
  void _pickDirectory() async {
    final result = await pickDirectoryPath();

    if (result != null) {
      widget.onPathSelected(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
         Text(
          "+ Output path:",
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.white),
        ),
        const SizedBox(width: 10),
        
        Expanded(
          child: Text(
            widget.currentPath ?? "No path selected",
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style:  TextStyle(color: AppTheme.white),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.secondBackground,         // Fondo del botón
            foregroundColor: AppTheme.white,              // Color del texto
            side:  BorderSide(color: AppTheme.white),// Borde del botón
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),   // Esquinas redondeadas (opcional)
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Padding interno
          ),
          onPressed: _pickDirectory,
          child: const Text("Browse"),
        ),
        const SizedBox(width: 10),
      ],
    );
  }
}

class PasswordAndEncryptionOptions extends StatefulWidget {
  final String encryptionLevel;
  final void Function(String?) onEncryptionChanged;

  final String? password;
  final void Function(String) onPasswordChangedText;
  final TextEditingController passwordController;

  final String? repeatPassword;
  final void Function(String) onRepeatPasswordChanged;
  final TextEditingController repeatPasswordController;

  const PasswordAndEncryptionOptions({
    super.key,
    required this.encryptionLevel,
    required this.onEncryptionChanged,
    required this.password,
    required this.onPasswordChangedText,
    required this.passwordController,
    required this.repeatPassword,
    required this.onRepeatPasswordChanged,
    required this.repeatPasswordController,
  });

  @override
  State<PasswordAndEncryptionOptions> createState() =>
      _PasswordAndEncryptionOptionsState();
}

class _PasswordAndEncryptionOptionsState
    extends State<PasswordAndEncryptionOptions> {
  bool _obscurePassword = true;
  bool _obscureRepeatPassword = true;

  bool get _shouldShowError {
    return (widget.password?.isNotEmpty ?? false) &&
           (widget.repeatPassword?.isNotEmpty ?? false) &&
           widget.password != widget.repeatPassword;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text("Password:\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t ", style: TextStyle(color: AppTheme.white)),
            const SizedBox(width: 10),
            SizedBox(
              width: 180,
              child: TextField(
                controller: widget.passwordController,
                obscureText: _obscurePassword,
                onChanged: widget.onPasswordChangedText,
                style: TextStyle(color: AppTheme.white),
                decoration: InputDecoration(
                  hintText: 'Enter password',
                  hintStyle: TextStyle(color: AppTheme.shadow),
                  isDense: true,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
            ),
            const Spacer(),
            Text("File encryption:", style: TextStyle(color: AppTheme.white)),
            const SizedBox(width: 10),
            DropdownButton<String>(
              value: widget.encryptionLevel,
              dropdownColor: Colors.grey[900],
              style: TextStyle(color: AppTheme.white),
              items: encryptionOptions.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: widget.onEncryptionChanged,
            ),
            const SizedBox(width: 20),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text("Repeat password:\t  ", style: TextStyle(color: AppTheme.white)),
            const SizedBox(width: 10),
            SizedBox(
              width: 180,
              child: TextField(
                controller: widget.repeatPasswordController,
                obscureText: _obscureRepeatPassword,
                onChanged: widget.onRepeatPasswordChanged,
                style: TextStyle(color: AppTheme.white),
                decoration: InputDecoration(
                  hintText: 'Repeat password',
                  hintStyle: TextStyle(color: AppTheme.shadow),
                  isDense: true,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureRepeatPassword ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureRepeatPassword = !_obscureRepeatPassword;
                      });
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_shouldShowError)
          Padding(
            padding: const EdgeInsets.only(top: 6.0, left: 12),
            child: Row(
              children: const [
                Icon(Icons.warning, color: Colors.redAccent, size: 18),
                SizedBox(width: 6),
                Text(
                  "Passwords do not match",
                  style: TextStyle(color: Colors.redAccent),
                ),
              ],
            ),
          ),
      ],
    );
  }
}





class FragButton extends StatelessWidget {
  final String? selectedFilePath;
  final String? selectedOutputPath;
  final String encryptionLevel;
  final String? password;
  final VoidCallback? onSeedAdded;
  final int fragmentSize;
  final void Function()? onClearFields;


  final String? repeatPassword;

  const FragButton({
    super.key,
    required this.selectedFilePath,
    required this.selectedOutputPath,
    required this.encryptionLevel,
    required this.password,
    required this.fragmentSize,
    this.onSeedAdded,
    this.onClearFields,
    required this.repeatPassword, // 👈 aquí
  });



  bool get isButtonEnabled {
    return selectedFilePath != null &&
          selectedOutputPath != null &&
          password != null &&
          repeatPassword != null &&
          password!.trim().isNotEmpty &&
          password == repeatPassword;
  }


  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        
        onPressed: isButtonEnabled
    ? () async {
        final events = fragment(
          req: FragmentRequest(
            inputPath: selectedFilePath!,
            outputDir: selectedOutputPath!,
            password: password!,
            mode: encryptionModeFromKey(encryptionLevel),
            parts: fragmentSize,
            deleteOriginal: DeletePolicy.wipe,
          ),
        );
        final result = await runOperation(context, events, title: 'Slys!');
        if (!context.mounted || result == null) return;

        if (result is OperationEvent_Fragmented) {
          // The seed is saved locally (as in 1.x) so it can be picked from the list later.
          seedsAdd(seed: result.field0.seed);
          final warnings = result.field0.warnings;
          if (warnings.isNotEmpty) {
            await showMessage(context, 'Done, with warnings', warnings.join('\n'));
          }
          onSeedAdded?.call();
          onClearFields?.call();
        } else if (result is OperationEvent_Failed) {
          await showMessage(context, 'Error', 'Fragmentation failed:\n${result.field0.message}');
        }
      }
    : null,
      style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.background,         // Fondo del botón
          foregroundColor: AppTheme.secondary,              // Color del texto
          side:  BorderSide(color: AppTheme.white),// Borde del botón
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),   // Esquinas redondeadas (opcional)
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Padding interno
        ),

      child: const Text('Slys!', style:TextStyle(fontWeight: FontWeight.bold)),
    );
    
  }
}

class SliderWidget extends StatelessWidget {
  final int currentValue;
  final ValueChanged<int> onChanged;

  const SliderWidget({
    super.key,
    required this.currentValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Slider(
            value: currentValue.toDouble(),
            min: 5,
            max: 100,
            //divisions: 95,
            label: "$currentValue",
            activeColor: AppTheme.accent,
            inactiveColor: AppTheme.white,
            onChanged: (double value) {
              onChanged(value.toInt());
            },
          ),
          Text(
            "Slices: $currentValue",
            style: TextStyle(color: AppTheme.white),
          ),
        ],
      ),
    );
  }
}




class SeedsTable extends StatefulWidget {
  final String? selectedSeed;
  final int? selectedIndex;
  final void Function(String seed, int index) onSeedSelected;

  const SeedsTable({
    super.key,
    required this.selectedSeed,
    required this.selectedIndex,
    required this.onSeedSelected,
  });

  @override
  State<SeedsTable> createState() => SeedsTableState();
}


class SeedsTableState extends State<SeedsTable> {
  List<SavedSeed> seeds = [];
  bool fileExists = true;
  bool isLoading = true;
  int? selectedRowIndex; // Guarda el índice seleccionado

  String? selectedSeed;

  @override
  void initState() {
    super.initState();
    _loadSeeds();
  }

  Future<void> _loadSeeds() async {
    setState(() {
      isLoading = true;
    });
    try {
      final list = seedsList();
      setState(() {
        seeds = list;
        fileExists = true;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        seeds = [];
        fileExists = false;
        isLoading = false;
      });
    }
  }

  // 🔁 Llamar desde afuera para refrescar la tabla
  void refreshTable() {
    _loadSeeds();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!fileExists || seeds.isEmpty) {
      return Center(
        child: Text(
          'No seeds found',
          style: TextStyle(fontSize: 18, color: AppTheme.white),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 80),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppTheme.secondBackground),
          columnSpacing: 20,
          dataRowHeight: 48,
          headingTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.white,
            fontSize: 14,
          ),
          columns: const [
            DataColumn(label: Text('File')),
            DataColumn(label: Text('Seed')),
          ],
          rows: List<DataRow>.generate(
            seeds.length,
            (index) {
              final seedData = seeds[index];
              final isEvenRow = index % 2 == 0;

              return DataRow(
                selected: widget.selectedIndex == index,
                onSelectChanged: (selected) {
                  if (widget.selectedIndex == index) {
                    widget.onSeedSelected('', -1);
                  } else {
                    widget.onSeedSelected(seedData.seed, index);
                  }
                },
                color: WidgetStateProperty.resolveWith<Color?>(
                  (Set<WidgetState> states) {
                    if (widget.selectedIndex == index) {
                      return AppTheme.accent;
                    }
                    return isEvenRow ? AppTheme.grey : AppTheme.lessGrey;
                  },
                ),
                cells: [
                  DataCell(Text(seedData.name, style:  TextStyle(color: AppTheme.white))),
                  DataCell(Text(seedData.seed, style:  TextStyle(color: AppTheme.white))),
                ],
              );
            },
          ),
        ),
      ),
    );

  }
}



class RecomposeButton extends StatelessWidget {
  final String? seed;
  final String? password;
  final VoidCallback? onRefreshRequested;
  final void Function()? onClearFields;
  final String? inputPath;

  const RecomposeButton({
    super.key,
    required this.seed,
    required this.password,
    this.onRefreshRequested,
    this.onClearFields,
    this.inputPath,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: seed != null && password != null && inputPath != null
          ? () async {
              // 👉 Buscar valor persistente
              final prefs = await SharedPreferences.getInstance();
              String? outputPath = prefs.getString('endOutputRecomopose');

              // 👉 Si no existe, pedirlo manualmente
              if (outputPath == null || outputPath.isEmpty) {
                outputPath = await pickDirectoryPath();
                if (outputPath == null) return; // Usuario canceló
              }

              final events = recompose(
                req: RecomposeRequest(
                  seed: seed!.trim(),
                  password: password!,
                  fragmentsDir: inputPath!,
                  outputDir: outputPath,
                  overwrite: false,
                  deleteFragments: DeletePolicy.wipe,
                ),
              );
              if (!context.mounted) return;
              final result = await runOperation(context, events, title: 'Recompose!');
              if (!context.mounted || result == null) return;

              if (result is OperationEvent_Recomposed) {
                final out = result.field0;
                _removeSeedFromList(seed!);
                final extra = out.warnings.isEmpty ? '' : '\n\n${out.warnings.join('\n')}';
                await showMessage(
                  context,
                  'Success',
                  'File recomposed:\n${out.outputPath}$extra',
                );
              } else if (result is OperationEvent_Failed) {
                await showMessage(
                  context,
                  'Error',
                  'Failed to recompose:\n${result.field0.message}',
                );
              }

              onRefreshRequested?.call();
              onClearFields?.call();
            }
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.accent,
      ),
      child:  Text(
        "Recompose!",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

}

/// Removes a seed from the local list by its text. Returns whether it was removed.
bool _removeSeedFromList(String seed) {
  try {
    final wanted = seed.trim();
    for (final s in seedsList()) {
      if (s.seed == wanted) {
        return seedsRemove(id: s.id);
      }
    }
  } catch (_) {}
  return false;
}


class DeleteSeedButton extends StatelessWidget {
  final String? seed;
  final VoidCallback? onRefreshRequested;
  final VoidCallback? onClearSelection; // 👈 nuevo parámetro

  const DeleteSeedButton({
    super.key,
    required this.seed,
    this.onRefreshRequested,
    this.onClearSelection,
  });


  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: seed != null
          ? () async {
              final removed = _removeSeedFromList(seed!);

              if (removed) {
                await showMessage(context, "Deleted", "Seed deleted successfully.");
                onClearSelection?.call(); // 👈 deselect
              } else {
                await showMessage(context, "Error", "Failed to delete seed.");
              }


              onRefreshRequested?.call();
            }
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
      ),
      child: const Text("Delete", style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold)),
    );
  }
}

class AddSeedButton extends StatelessWidget {
  final VoidCallback? onRefreshRequested;

  const AddSeedButton({
    super.key,
    this.onRefreshRequested,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _showSeedInputDialog(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
      ),
      child: const Text("Add Seed", style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
    );
  }

  void _showSeedInputDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text("Add Seed", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Paste or type the seed here...",
            hintStyle: TextStyle(color: Colors.white54),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final seed = controller.text.trim();
              Navigator.pop(ctx);

              if (seed.isEmpty) {
                _showDialog(context, "Error", "Seed cannot be empty.");
                return;
              }

              // Catch typos right away: v2 seeds carry a checksum.
              try {
                inspectSeed(text: seed);
                seedsAdd(seed: seed);
                await showMessage(context, "Success", "Seed added successfully.");
              } on SlysError catch (e) {
                await showMessage(context, "Error", e.message);
              } catch (_) {
                await showMessage(context, "Error", "Failed to add seed.");
              }

              onRefreshRequested?.call();
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _showDialog(BuildContext context, String title, String message) {
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.grey[850],
          title: Text(title, style: const TextStyle(color: Colors.white)),
          content: Text(message, style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }
}


