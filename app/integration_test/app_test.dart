// Smoke test: the real UI builds with the real Rust core behind it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slys/custom/theme.dart';
import 'package:slys/main.dart';
import 'package:slys/src/rust/frb_generated.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home screen builds with the Rust core behind it', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await RustLib.init();
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider(create: (_) => ThemeNotifier(), child: const MyWidget()),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(find.text('Slys!'), findsWidgets);
  });

  // The layout must adapt to any window size: no overflow on any tab, from a phone-sized window
  // to an ultrawide monitor.
  for (final size in const [Size(360, 520), Size(520, 700), Size(900, 800), Size(2560, 1200)]) {
    testWidgets('no layout overflow at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ChangeNotifierProvider(create: (_) => ThemeNotifier(), child: const MyWidget()),
      );
      await tester.pump(const Duration(seconds: 1));
      for (final tab in ['Home', 'Settings', 'Tutorial', 'About']) {
        await tester.tap(find.text(tab).first);
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull, reason: '$tab at $size');
      }
    });
  }
}
