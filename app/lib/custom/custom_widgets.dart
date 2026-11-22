import 'package:flutter/material.dart';
import '../utils/app_styles.dart';

/// Width from which the Home screen shows "Fragment" and "Seeds" side by side.
const double kWideLayout = 980;

/// Content never grows wider than this, so lines stay readable on big monitors.
const double kMaxContentWidth = 1280;

/// A titled panel. Adapts to whatever width it is given.
class AppCard extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;

  const AppCard({
    super.key,
    required this.title,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // A Material (not a plain decorated box) so ListTile/Switch inside can paint their ink.
    return Material(
      color: AppTheme.secondBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.lessGrey),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.white,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

ButtonStyle secondaryButtonStyle() {
  return OutlinedButton.styleFrom(
    foregroundColor: AppTheme.white,
    side: BorderSide(color: AppTheme.grey),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
  );
}

ButtonStyle primaryButtonStyle() {
  return FilledButton.styleFrom(
    backgroundColor: AppTheme.accent,
    foregroundColor: AppTheme.onAccent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
  );
}

/// "Label" on top, then the chosen path (shortened with … if it does not fit) and a Browse button.
/// Works the same at any width.
class PathRow extends StatelessWidget {
  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback? onBrowse;
  final Widget? extra;

  const PathRow({
    super.key,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onBrowse,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    final has = value != null && value!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.white),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Tooltip(
                message: has ? value! : '',
                child: Container(
                  height: 44,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    has ? value! : placeholder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: has ? AppTheme.white : AppTheme.shadow,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              style: secondaryButtonStyle(),
              onPressed: onBrowse,
              child: const Text('Browse'),
            ),
            if (extra != null) extra!,
          ],
        ),
      ],
    );
  }
}

/// Password input with a show/hide toggle.
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final String? errorText;

  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    required this.onChanged,
    this.enabled = true,
    this.errorText,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      enabled: widget.enabled,
      onChanged: widget.onChanged,
      style: TextStyle(color: AppTheme.white),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: TextStyle(color: AppTheme.shadow),
        errorText: widget.errorText,
        isDense: true,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          tooltip: _obscure ? 'Show' : 'Hide',
          icon: Icon(
            _obscure ? Icons.visibility_off : Icons.visibility,
            color: AppTheme.white,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}

/// Lays children side by side when there is room for [minChildWidth] each, one per row otherwise.
class AdaptiveRow extends StatelessWidget {
  final List<Widget> children;
  final double minChildWidth;
  final double spacing;

  const AdaptiveRow({
    super.key,
    required this.children,
    this.minChildWidth = 240,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final fits =
            c.maxWidth >=
            children.length * minChildWidth + (children.length - 1) * spacing;
        if (fits) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(width: spacing),
                Expanded(child: children[i]),
              ],
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(height: spacing),
              children[i],
            ],
          ],
        );
      },
    );
  }
}
