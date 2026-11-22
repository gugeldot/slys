import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../custom/custom_widgets.dart';
import '../../services/default_paths.dart';
import '../../services/file_dialogs.dart';
import '../../utils/app_styles.dart';
import '../settings/settings.dart';
import 'main_fn.dart';

// One controller per page: while switching tabs both pages exist for a moment, and a controller can
// only drive one scroll view.
final ScrollController fragmentScroll = ScrollController();
final ScrollController recomposeScroll = ScrollController();
final GlobalKey<SeedsTableState> seedsTableKey = GlobalKey<SeedsTableState>();

// ---------------------------------------------------------------- layout pieces

/// Width from which a page shows two columns separated by a divider.
const double _kTwoColumns = 860;

/// On very wide windows the content stops growing here so lines stay readable.
const double _kMaxContent = 1200;

/// A heading with a rule under it. Not a box: the sections sit directly on the page.
class _Section extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> children;

  const _Section({
    required this.title,
    this.subtitle,
    this.trailing,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 40,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.white,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: minitTextStyle()),
        ],
        const SizedBox(height: 8),
        Divider(color: AppTheme.lessGrey, height: 1),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }
}

/// A page: scrolling content filling the window, with an action bar pinned to the bottom.
/// Wide windows get two columns with a divider; narrow ones stack the sections.
Widget _page({
  required ScrollController controller,
  required List<Widget> sections,
  required Widget bar,
}) {
  return Column(
    children: [
      Expanded(
        child: Scrollbar(
          controller: controller,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _kMaxContent),
                child: LayoutBuilder(
                  builder: (context, c) {
                    if (c.maxWidth >= _kTwoColumns && sections.length == 2) {
                      // A Stack (not IntrinsicHeight, which cannot contain LayoutBuilders) draws the
                      // divider at full height between the two columns.
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: Center(
                              child: Container(
                                width: 1,
                                color: AppTheme.lessGrey,
                              ),
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 28),
                                  child: sections[0],
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 28),
                                  child: sections[1],
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < sections.length; i++) ...[
                          if (i > 0) const SizedBox(height: 28),
                          sections[i],
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
      bar,
    ],
  );
}

/// Bottom bar: why the action is not available yet (left) and the action (right).
Widget _actionBar({
  required String? reason,
  required String hint,
  required Widget button,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    decoration: BoxDecoration(
      color: AppTheme.window_background,
      border: Border(top: BorderSide(color: AppTheme.lessGrey)),
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _kMaxContent),
        child: LayoutBuilder(
          builder: (context, c) {
            final text = Text(
              reason ?? hint,
              style:
                  reason == null
                      ? minitTextStyle()
                      : TextStyle(color: AppTheme.white),
            );
            final btn = ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 200),
              child: button,
            );
            if (c.maxWidth >= 560) {
              return Row(
                children: [
                  Expanded(child: text),
                  const SizedBox(width: 16),
                  btn,
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [text, const SizedBox(height: 8), button],
            );
          },
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------- Fragment

Widget fragmentScreen({
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
  required String? repeatPassword,
  required TextEditingController repeatPasswordController,
  required void Function(String value) onRepeatPasswordChanged,
}) {
  final fragButton = FragButton(
    selectedFilePath: selectedFilePath,
    selectedOutputPath: selectedOutputPath,
    encryptionLevel: encryptionLevel,
    password: password,
    repeatPassword: repeatPassword,
    fragmentSize: fragmentSize,
    showReason: false,
    onSeedAdded: () => seedsTableKey.currentState?.refreshTable(),
    onClearFields: () async {
      final prefs = await SharedPreferences.getInstance();

      if (!prefs.containsKey(kSelectedOutputPathKey)) {
        onOutputPathSelected(defaultFragmentsDir());
      }
      if (!prefs.containsKey(kFragmentSizeKey)) {
        onFragmentSizeChanged(kDefaultPieces);
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
  );

  return _page(
    controller: fragmentScroll,
    sections: [
      _Section(
        title: 'File',
        subtitle: 'What to protect and where its pieces go.',
        children: [
          TargetFileSelector(
            currentFilePath: selectedFilePath,
            onFileSelected: onFileSelected,
          ),
          const SizedBox(height: 18),
          OutputPathSelector(
            currentPath: selectedOutputPath,
            onPathSelected: onOutputPathSelected,
          ),
        ],
      ),
      _Section(
        title: 'Protection',
        subtitle: 'The password is the only key.',
        children: [
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
          SliderWidget(
            currentValue: fragmentSize,
            onChanged: onFragmentSizeChanged,
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.amber,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Slys doesn't store the password. If you lose it, the file cannot be recovered.",
                  style: minitTextStyle(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
    bar: _actionBar(
      reason: fragButton.disabledReason,
      hint: 'Ready: the pieces will be written to the output folder.',
      button: fragButton,
    ),
  );
}

// ---------------------------------------------------------------- Recompose

Widget recomposeScreen({
  required String? selectedSeed,
  required int? selectedSeedIndex,
  required void Function(String seed, int index) onSeedSelected,
  required String? recomposeOutputPath,
  required void Function(String path) onRecomposeOutputPathSelected,
  required String? recomposePassword,
  required TextEditingController recomposePasswordController,
  required void Function(String value) onRecomposePasswordChanged,
}) {
  String? reason;
  if (selectedSeed == null) {
    reason = 'Select a seed from the list.';
  } else if (recomposeOutputPath == null || recomposeOutputPath.isEmpty) {
    reason = 'Choose the folder with the pieces.';
  } else if (recomposePassword == null || recomposePassword.isEmpty) {
    reason = 'Write the password.';
  }

  final rebuildButton = RecomposeButton(
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

  return _page(
    controller: recomposeScroll,
    sections: [
      _Section(
        title: 'Seeds',
        subtitle: 'Pick the one for the file you want back.',
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
        children: [
          SeedsTable(
            key: seedsTableKey,
            selectedSeed: selectedSeed,
            selectedIndex: selectedSeedIndex,
            onSeedSelected: onSeedSelected,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              AddSeedButton(
                onRefreshRequested:
                    () => seedsTableKey.currentState?.refreshTable(),
              ),
              DeleteSeedButton(
                seed: selectedSeed,
                onRefreshRequested:
                    () => seedsTableKey.currentState?.refreshTable(),
                onClearSelection: () => onSeedSelected('', -1),
              ),
            ],
          ),
        ],
      ),
      _Section(
        title: 'Rebuild',
        subtitle: 'What is needed to get the file back.',
        children: [
          if (selectedSeed == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                children: [
                  Icon(Icons.arrow_back, color: AppTheme.shadow),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select a seed first.',
                      style: minitTextStyle(),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            PathRow(
              label: 'Where are the pieces?',
              value: recomposeOutputPath,
              placeholder: 'No folder selected',
              dropKind: DropKind.directory,
              onDrop: onRecomposeOutputPathSelected,
              onBrowse: () async {
                final start =
                    (recomposeOutputPath != null &&
                            Directory(recomposeOutputPath).existsSync())
                        ? recomposeOutputPath
                        : desktopDir();
                final picked = await pickDirectoryPath(initialDirectory: start);
                if (picked != null) onRecomposeOutputPathSelected(picked);
              },
            ),
            const SizedBox(height: 18),
            PasswordField(
              controller: recomposePasswordController,
              label: 'Password',
              onChanged: onRecomposePasswordChanged,
            ),
            const SizedBox(height: 10),
            Text(
              'When you press Recompose! you choose where to save the file.',
              style: minitTextStyle(),
            ),
          ],
        ],
      ),
    ],
    bar: _actionBar(
      reason: reason,
      hint: 'Ready: you will choose where to save the rebuilt file.',
      button: rebuildButton,
    ),
  );
}
