import 'package:flutter/material.dart';

import '../../custom/custom_widgets.dart';
import '../../utils/app_styles.dart';

/// Tutorial: two short visual flows (fragment, recompose) and one reminder.
Widget tutorialScreen() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdaptiveRow(
          minChildWidth: 380,
          spacing: 16,
          children: const [
            _Flow(
              title: 'Fragment a file',
              icon: Icons.call_split,
              steps: [
                _StepData(
                  Icons.insert_drive_file_outlined,
                  'Pick the file',
                  'Browse, or drag it onto the box.',
                ),
                _StepData(
                  Icons.folder_open_outlined,
                  'Pick where the pieces go',
                  'By default the Desktop, in a folder called slys_fragments.',
                ),
                _StepData(
                  Icons.lock_outline,
                  'Set a password',
                  'High encryption is recommended. SLYS never stores it.',
                ),
                _StepData(
                  Icons.bolt,
                  'Press Slys!',
                  'You get a seed, saved in the Recompose tab.',
                ),
              ],
            ),
            _Flow(
              title: 'Rebuild it',
              icon: Icons.restore,
              steps: [
                _StepData(
                  Icons.key_outlined,
                  'Select the seed',
                  'In the Recompose tab, or paste it with Add seed.',
                ),
                _StepData(
                  Icons.folder_copy_outlined,
                  'Point to the pieces',
                  'The folder where they are (drag it onto the box).',
                ),
                _StepData(
                  Icons.password,
                  'Enter the password',
                  'The same one you used to fragment.',
                ),
                _StepData(
                  Icons.check_circle_outline,
                  'Press Recompose!',
                  'You choose where to save it (Desktop by default); it is checked before the pieces are removed.',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _Reminder(),
      ],
    ),
  );
}

class _StepData {
  final IconData icon;
  final String title;
  final String hint;

  const _StepData(this.icon, this.title, this.hint);
}

class _Flow extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_StepData> steps;

  const _Flow({required this.title, required this.icon, required this.steps});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: title,
      trailing: Icon(icon, color: AppTheme.accent),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            _Step(number: i + 1, data: steps[i], last: i == steps.length - 1),
        ],
      ),
    );
  }
}

/// A numbered circle joined to the next one by a line, with an icon, a title and a one-line hint.
class _Step extends StatelessWidget {
  final int number;
  final _StepData data;
  final bool last;

  const _Step({required this.number, required this.data, required this.last});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$number',
                    style: TextStyle(
                      color: AppTheme.onAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!last)
                  Expanded(child: Container(width: 2, color: AppTheme.grey)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(data.icon, color: AppTheme.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(data.hint, style: minitTextStyle()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Reminder extends StatelessWidget {
  const _Reminder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: Colors.amber),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Keep three things: the pieces, the seed and the password. '
              'Without any one of them the file cannot be recovered.',
              style: TextStyle(color: AppTheme.white),
            ),
          ),
        ],
      ),
    );
  }
}
