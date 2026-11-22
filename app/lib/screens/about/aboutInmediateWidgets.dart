import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../custom/custom_widgets.dart';
import '../../src/rust/api/version.dart';
import '../../utils/app_styles.dart';
import 'about_fn.dart';

/// About page: version first (it is what a bug report needs), then a short "why", what SLYS does,
/// and the legal notice folded away.
Widget aboutScreen() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const VersionCard(),
        const SizedBox(height: 16),
        _whyCard(),
        const SizedBox(height: 16),
        _featuresCard(),
        const SizedBox(height: 16),
        _legalCard(),
        const SizedBox(height: 20),
        paypalButton(),
        const SizedBox(height: 8),
      ],
    ),
  );
}

/// Version, build and format at a glance, with a button that copies them for bug reports.
class VersionCard extends StatelessWidget {
  const VersionCard({super.key});

  @override
  Widget build(BuildContext context) {
    VersionInfo? v;
    try {
      v = versionInfo();
    } catch (_) {}
    final known = v != null && v.commit != 'unknown';
    final summary =
        v == null
            ? 'SLYS (version unavailable)'
            : 'SLYS ${v.version}${known ? ' · ${v.commit}' : ''} · seed format ${v.seedFormat}';

    return AppCard(
      title: 'SLYS',
      trailing: IconButton.outlined(
        icon: Icon(Icons.copy, size: 20, color: AppTheme.white),
        tooltip: 'Copy version info (for bug reports)',
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: summary));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Version info copied'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fragment and encrypt your files. Rebuild them with a seed and a password.',
            style: minitTextStyle(),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(Icons.sell_outlined, 'Version', v?.version ?? '?'),
              if (known) _InfoChip(Icons.commit, 'Build', v.commit),
              _InfoChip(
                Icons.key_outlined,
                'Seed format',
                v == null ? '?' : 'v${v.seedFormat}',
              ),
              const _InfoChip(
                Icons.balance_outlined,
                'License',
                'GPL-3.0-or-later',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.lessGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppTheme.accent),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: AppTheme.shadow),
              ),
              SelectableText(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Point extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _Point(this.icon, this.title, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(text, style: minitTextStyle()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _whyCard() {
  return AppCard(
    title: 'Why',
    child: Column(
      children: const [
        _Point(
          Icons.visibility_off_outlined,
          'Your files, your control',
          'Pieces are useless on their own: nobody can read them without your password.',
        ),
        _Point(
          Icons.vpn_key_outlined,
          'Three things to rebuild',
          'The pieces, the seed and the password. Lose one and the file is gone.',
        ),
        _Point(
          Icons.restore,
          'Reinstall any time',
          'Install SLYS again, enter the seed and the password, and your file is back.',
        ),
      ],
    ),
  );
}

Widget _featuresCard() {
  return AppCard(
    title: 'What it does',
    child: Column(
      children: const [
        _Point(
          Icons.call_split,
          'Fragments and encrypts',
          'AES-256-GCM, with the key derived from your password using Argon2id.',
        ),
        _Point(
          Icons.fact_check_outlined,
          'Detects any change',
          'Edited, missing, reordered or swapped pieces are reported; nothing is rebuilt wrongly.',
        ),
        _Point(
          Icons.verified_outlined,
          'Verifies before deleting',
          'The original is removed only after the pieces are proven to rebuild it.',
        ),
        _Point(
          Icons.history,
          'Reads old seeds',
          'Seeds made by SLYS 1.x still work.',
        ),
        _Point(
          Icons.schedule,
          'Planned',
          'Optional wipe of the saved-seeds list after a period of inactivity.',
        ),
      ],
    ),
  );
}

Widget _legalCard() {
  return Material(
    color: AppTheme.secondBackground,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: AppTheme.lessGrey),
    ),
    clipBehavior: Clip.antiAlias,
    child: Theme(
      data: ThemeData(dividerColor: Colors.transparent),
      child: ExpansionTile(
        iconColor: AppTheme.white,
        collapsedIconColor: AppTheme.white,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          'Legal notice',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: AppTheme.white,
          ),
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The SLYS platform provides a decentralized tool for fragmenting and reconstructing '
            'sensitive information through the use of cryptographic keys.\n'
            'It is the sole responsibility of the user to securely store and manage the keys '
            'generated by the application.\n'
            'Loss, accidental deletion, or mishandling of these keys may result in permanent loss '
            'of access to the fragmented data.\n'
            'Neither the development team nor the application shall be held liable for any damages, '
            'data loss, or consequences arising from the mismanagement, loss, or deletion of the '
            'keys by the user.\n'
            'By using SLYS, you acknowledge and accept full responsibility for the preservation and '
            'confidentiality of your cryptographic keys.',
            style: minitTextStyle(),
          ),
        ],
      ),
    ),
  );
}

Widget paypalButton() {
  return Center(
    child: PayPalDonateButton(
      donationUrl:
          "https://www.paypal.com/donate/?hosted_button_id=HKANXJYJZND7G",
    ),
  );
}
