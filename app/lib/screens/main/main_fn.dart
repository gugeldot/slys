
import 'package:flutter/material.dart';
import '../../services/file_dialogs.dart';
import '../../custom/custom_widgets.dart';
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

class TargetFileSelector extends StatelessWidget {
  final void Function(String path) onFileSelected;
  final String? currentFilePath;

  const TargetFileSelector({super.key, required this.onFileSelected, this.currentFilePath});

  @override
  Widget build(BuildContext context) {
    return PathRow(
      label: 'Target file',
      value: currentFilePath,
      placeholder: 'No file selected',
      onBrowse: () async {
        final path = await pickFilePath();
        if (path != null) onFileSelected(path);
      },
    );
  }
}

class OutputPathSelector extends StatelessWidget {
  final void Function(String path) onPathSelected;
  final String? currentPath;

  const OutputPathSelector({super.key, required this.onPathSelected, this.currentPath});

  @override
  Widget build(BuildContext context) {
    return PathRow(
      label: 'Output folder (where the pieces go)',
      value: currentPath,
      placeholder: 'No folder selected',
      onBrowse: () async {
        final result = await pickDirectoryPath();
        if (result != null) onPathSelected(result);
      },
    );
  }
}

class PasswordAndEncryptionOptions extends StatelessWidget {
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

  bool get _mismatch =>
      (password?.isNotEmpty ?? false) &&
      (repeatPassword?.isNotEmpty ?? false) &&
      password != repeatPassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdaptiveRow(
          minChildWidth: 220,
          children: [
            PasswordField(
              controller: passwordController,
              label: 'Password',
              onChanged: onPasswordChangedText,
            ),
            PasswordField(
              controller: repeatPasswordController,
              label: 'Repeat password',
              onChanged: onRepeatPasswordChanged,
              errorText: _mismatch ? 'Passwords do not match' : null,
            ),
          ],
        ),
        const SizedBox(height: 14),
        InputDecorator(
          decoration: InputDecoration(
            labelText: 'File encryption',
            labelStyle: TextStyle(color: AppTheme.shadow),
            isDense: true,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: encryptionLevel,
              dropdownColor: AppTheme.grey2,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.white),
              items: encryptionOptions.entries
                  .map((e) => DropdownMenuItem<String>(
                        value: e.key,
                        child: Text(e.value, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: onEncryptionChanged,
            ),
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
    required this.repeatPassword,
  });

  /// Why the button is disabled, in plain words (null when it can be pressed).
  String? get disabledReason {
    if (selectedFilePath == null || selectedFilePath!.isEmpty) return 'Choose the file to fragment.';
    if (selectedOutputPath == null || selectedOutputPath!.isEmpty) return 'Choose where the pieces go.';
    if (password == null || password!.trim().isEmpty) return 'Write a password.';
    if (password != repeatPassword) return 'Repeat the same password.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final reason = disabledReason;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          style: primaryButtonStyle(),
          onPressed: reason != null
              ? null
              : () async {
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
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Done. The seed was saved in the Seeds list.'),
                        duration: Duration(seconds: 4),
                      ));
                    }
                    onSeedAdded?.call();
                    onClearFields?.call();
                  } else if (result is OperationEvent_Failed) {
                    await showMessage(context, 'Error', 'Fragmentation failed:\n${result.field0.message}');
                  }
                },
          child: const Text('Slys!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        if (reason != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(reason, textAlign: TextAlign.center, style: minitTextStyle()),
          ),
      ],
    );
  }
}

class SliderWidget extends StatelessWidget {
  final int currentValue;
  final ValueChanged<int> onChanged;

  const SliderWidget({super.key, required this.currentValue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Pieces', style: TextStyle(color: AppTheme.white)),
        Expanded(
          child: Slider(
            value: currentValue.clamp(2, 100).toDouble(),
            min: 2,
            max: 100,
            divisions: 98,
            label: '$currentValue',
            activeColor: AppTheme.accent,
            inactiveColor: AppTheme.grey,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        SizedBox(
          width: 32,
          child: Text('$currentValue',
              textAlign: TextAlign.end, style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
        ),
      ],
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
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (!fileExists || seeds.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 8),
        child: Column(
          children: [
            Icon(Icons.key_off_outlined, size: 36, color: AppTheme.shadow),
            const SizedBox(height: 8),
            Text('No seeds yet', style: TextStyle(fontSize: 17, color: AppTheme.white)),
            const SizedBox(height: 4),
            Text(
              'Fragment a file and its seed appears here, or add one you already have.',
              textAlign: TextAlign.center,
              style: minitTextStyle(),
            ),
          ],
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 300),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: seeds.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final seedData = seeds[index];
          final selected = widget.selectedIndex == index;
          final fg = selected ? AppTheme.onAccent : AppTheme.white;
          return Material(
            color: selected ? AppTheme.accent : AppTheme.lessGrey,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                if (selected) {
                  widget.onSeedSelected('', -1);
                } else {
                  widget.onSeedSelected(seedData.seed, index);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(seedData.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: fg, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Tooltip(
                      message: seedData.seed,
                      child: Text(seedData.seed,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: fg.withValues(alpha: 0.8), fontSize: 12, fontFamily: 'monospace')),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
    final ready = seed != null && (password?.isNotEmpty ?? false) && (inputPath?.isNotEmpty ?? false);
    return FilledButton(
      onPressed: ready
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
      style: primaryButtonStyle(),
      child: const Text('Recompose!', style: TextStyle(fontWeight: FontWeight.bold)),
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
    return OutlinedButton(
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
      style: secondaryButtonStyle().copyWith(
        foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled) ? null : Colors.redAccent),
      ),
      child: const Text('Remove', style: TextStyle(fontWeight: FontWeight.bold)),
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
    return FilledButton(
      onPressed: () => _showSeedInputDialog(context),
      style: primaryButtonStyle(),
      child: const Text('Add seed', style: TextStyle(fontWeight: FontWeight.bold)),
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


