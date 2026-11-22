import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../custom/custom_widgets.dart';
import '../../services/file_dialogs.dart';
import '../../utils/app_styles.dart';
import '../settings/settings.dart';
import 'main_fn.dart';

final ScrollController scrollController = ScrollController();
final GlobalKey<SeedsTableState> seedsTableKey = GlobalKey<SeedsTableState>();

/// Home screen. Two columns (Fragment | Seeds) when the window is wide, stacked when it is not.
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
  required String? recomposePassword,
  required TextEditingController recomposePasswordController,
  required void Function(String value) onRecomposePasswordChanged,
}) {
  final fragmentCard = AppCard(
    title: 'Fragment',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Split a file into encrypted pieces.', style: minitTextStyle()),
        const SizedBox(height: 16),
        TargetFileSelector(currentFilePath: selectedFilePath, onFileSelected: onFileSelected),
        const SizedBox(height: 14),
        OutputPathSelector(currentPath: selectedOutputPath, onPathSelected: onOutputPathSelected),
        const SizedBox(height: 16),
        PasswordAndEncryptionOptions(
          encryptionLevel: encryptionLevel,
          onEncryptionChanged: onEncryptionLevelChanged,
          password: password,
          onPasswordChangedText: onPasswordChangedText,
          passwordController: passwordController,
          repeatPassword: repeatPassword,
          repeatPasswordController: repeatPasswordController,
          onRepeatPasswordChanged: onRepeatPasswordChanged,
        ),
        const SizedBox(height: 12),
        SliderWidget(currentValue: fragmentSize, onChanged: onFragmentSizeChanged),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Slys doesn't store the password. If you lose it, the file cannot be recovered.",
                style: minitTextStyle(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FragButton(
          selectedFilePath: selectedFilePath,
          selectedOutputPath: selectedOutputPath,
          encryptionLevel: encryptionLevel,
          password: password,
          repeatPassword: repeatPassword,
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
            onRepeatPasswordChanged('');
            passwordController.clear();
            repeatPasswordController.clear();
          },
        ),
      ],
    ),
  );

  final seedsCard = AppCard(
    title: 'Seeds',
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (selectedSeed != null)
          IconButton.outlined(
            icon: Icon(Icons.copy, color: AppTheme.white, size: 20),
            tooltip: 'Copy seed to clipboard',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: selectedSeed));
              final ctx = seedsTableKey.currentContext;
              if (ctx != null && ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Seed copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        IconButton.outlined(
          icon: Icon(Icons.refresh, color: AppTheme.white, size: 20),
          tooltip: 'Refresh seeds',
          onPressed: () => seedsTableKey.currentState?.refreshTable(),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SeedsTable(
          key: seedsTableKey,
          selectedSeed: selectedSeed,
          selectedIndex: selectedSeedIndex,
          onSeedSelected: onSeedSelected,
        ),
        const SizedBox(height: 16),
        if (selectedSeed != null) ...[
          Divider(color: AppTheme.lessGrey),
          const SizedBox(height: 8),
          PathRow(
            label: 'Where are the pieces?',
            value: recomposeOutputPath,
            placeholder: 'No folder selected',
            onBrowse: () async {
              final picked = await pickDirectoryPath();
              if (picked != null) onRecomposeOutputPathSelected(picked);
            },
          ),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, c) {
            final field = PasswordField(
              controller: recomposePasswordController,
              label: 'Password',
              onChanged: onRecomposePasswordChanged,
            );
            final button = RecomposeButton(
              seed: selectedSeed,
              password: recomposePassword,
              onRefreshRequested: () => seedsTableKey.currentState?.refreshTable(),
              onClearFields: () {
                recomposePasswordController.clear();
                onRecomposePasswordChanged('');
                onSeedSelected('', -1);
              },
              inputPath: recomposeOutputPath,
            );
            if (c.maxWidth >= 440) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Expanded(child: field), const SizedBox(width: 12), button],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [field, const SizedBox(height: 12), button],
            );
          }),
          const SizedBox(height: 16),
        ],
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 10,
          runSpacing: 10,
          children: [
            DeleteSeedButton(
              seed: selectedSeed,
              onRefreshRequested: () => seedsTableKey.currentState?.refreshTable(),
              onClearSelection: () => onSeedSelected('', -1),
            ),
            AddSeedButton(
              onRefreshRequested: () => seedsTableKey.currentState?.refreshTable(),
            ),
          ],
        ),
      ],
    ),
  );

  return Scrollbar(
    controller: scrollController,
    thumbVisibility: true,
    child: SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(builder: (context, c) {
        if (c.maxWidth >= kWideLayout) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: fragmentCard),
              const SizedBox(width: 16),
              Expanded(child: seedsCard),
            ],
          );
        }
        return Column(
          children: [fragmentCard, const SizedBox(height: 16), seedsCard],
        );
      }),
    ),
  );
}
