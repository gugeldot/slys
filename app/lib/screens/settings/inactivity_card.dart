import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../custom/custom_widgets.dart';
import '../../services/operation_runner.dart';
import '../../src/rust/api/operations.dart' show SlysError;
import '../../src/rust/api/storage.dart';
import '../../utils/app_styles.dart';

/// Settings card for the opt-in inactivity wipe: switch, number of days, and what is left.
/// The rules live in the Rust core (`documentation/INACTIVITY_WIPE.md`); this only configures them.
class InactivityCard extends StatefulWidget {
  const InactivityCard({super.key});

  @override
  State<InactivityCard> createState() => _InactivityCardState();
}

class _InactivityCardState extends State<InactivityCard> {
  static const presets = [7, 30, 90, 180, 365];

  InactivitySettings? settings;
  String? loadError;
  final daysController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    daysController.dispose();
    super.dispose();
  }

  void _reload() {
    try {
      final s = inactivitySettings();
      setState(() {
        settings = s;
        loadError = null;
        daysController.text = '${s.days}';
      });
    } on SlysError catch (e) {
      setState(() => loadError = e.message);
    } catch (e) {
      setState(() => loadError = '$e');
    }
  }

  Future<void> _apply(bool enabled, int days) async {
    try {
      inactivityConfigure(enabled: enabled, days: days);
    } on SlysError catch (e) {
      if (mounted) await showMessage(context, 'Error', e.message);
    }
    _reload();
  }

  Future<void> _toggle(bool on) async {
    final s = settings;
    if (s == null) return;
    if (!on) {
      await _apply(false, s.days);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text('Turn on inactivity wipe?', style: TextStyle(color: Colors.white)),
        content: Text(
          'If you do not open SLYS for ${s.days} days, the list of seeds saved in this app will be '
          'securely erased.\n\n'
          'Your pieces and your files are not touched, but without a seed the pieces cannot be '
          'rebuilt. Make sure you have a copy of every seed somewhere else first.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Turn on')),
        ],
      ),
    );
    if (ok == true) await _apply(true, s.days);
  }

  void _setDays(int days) {
    if (days < 1 || days > 3650) return;
    _apply(true, days);
  }

  String _status(InactivitySettings s) {
    if (!s.enabled) return 'Off. Your saved seeds are never erased automatically.';
    final left = s.daysLeft ?? 0;
    final when = left == 0 ? 'in less than a day' : (left == 1 ? 'in 1 day' : 'in $left days');
    return 'On. If you do not open SLYS, the saved seeds are erased $when. '
        'Opening SLYS restarts the count.';
  }

  @override
  Widget build(BuildContext context) {
    final s = settings;
    return AppCard(
      title: 'Inactivity wipe',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Optional. Erases the list of seeds saved in this app after a period without opening it.',
            style: minitTextStyle(),
          ),
          const SizedBox(height: 8),
          if (loadError != null)
            Text('Could not read the setting: $loadError', style: const TextStyle(color: Colors.redAccent))
          else if (s == null)
            const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator())
          else ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Erase saved seeds after inactivity', style: TextStyle(color: AppTheme.white)),
              value: s.enabled,
              activeThumbColor: AppTheme.accent,
              onChanged: _toggle,
            ),
            if (s.enabled) ...[
              const SizedBox(height: 4),
              Text('Days without opening SLYS', style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final d in presets)
                    ChoiceChip(
                      label: Text('$d'),
                      selected: s.days == d,
                      onSelected: (_) => _setDays(d),
                    ),
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: daysController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: TextStyle(color: AppTheme.white),
                      decoration: const InputDecoration(
                        labelText: 'Custom',
                        suffixText: 'days',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (v) {
                        final d = int.tryParse(v);
                        if (d == null || d < 1 || d > 3650) {
                          showMessage(context, 'Days', 'Enter a number between 1 and 3650.');
                          _reload();
                        } else {
                          _setDays(d);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Text(_status(s), style: TextStyle(color: AppTheme.white)),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: AppTheme.shadow),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'It only erases this app\'s seed list: never your pieces, your files or the '
                    'program. It runs when SLYS starts, and anyone who controls this computer '
                    'controls its clock, so it is a convenience, not a guarantee.',
                    style: minitTextStyle(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
