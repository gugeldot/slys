import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/app_styles.dart';




class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:  TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.white,
          ),
        ),
        const SizedBox(height: 4),
        Divider(
          color: AppTheme.white,
          thickness: 1,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}



Widget sectionTitle(String text) {
  return Text(
    text,
    style: boldDefaultTextStyle(),
  );
}


Widget bullet(String text) {
  return Padding(
    padding: const EdgeInsets.only(left: 12, top: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "• ",
          style: defaultTextStyle(),
        ),
        Expanded(
          child: Text(
            text,
            style: defaultTextStyle(),
          ),
        ),
      ],
    ),
  );
}

Widget listNumb(String num,String text) {
  return Padding(
    padding: const EdgeInsets.only(left: 12, top: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          num,
          style: defaultTextStyle(),
        ),
        Expanded(
          child: Text(
            text,
            style: defaultTextStyle(),
          ),
        ),
      ],
    ),
  );
}

class PayPalDonateButton extends StatelessWidget {
  final String donationUrl;

  const PayPalDonateButton({
    super.key,
    required this.donationUrl,
  });

  void _launchDonationUrl() async {
    final uri = Uri.parse(donationUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch PayPal URL';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _launchDonationUrl,
      icon: const Icon(Icons.favorite, color: Colors.redAccent),
      label: const Text("Donate by PayPal"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
}
