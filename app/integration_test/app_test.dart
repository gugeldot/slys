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
      for (final tab in ['Fragment', 'Recompose', 'Settings', 'Tutorial', 'About']) {
        await tester.tap(find.text(tab).first);
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull, reason: '$tab at $size');
      }
    });
  }

  testWidgets('inactivity wipe card is in Settings and asks before turning on', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider(create: (_) => ThemeNotifier(), child: const MyWidget()),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Settings').first);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Inactivity wipe'), findsOneWidget);
    final toggle = find.widgetWithText(SwitchListTile, 'Erase saved seeds after inactivity');
    expect(toggle, findsOneWidget);
    // Only try turning it on when it is off, so a real configuration is never changed by a test.
    if (!tester.widget<SwitchListTile>(toggle).value) {
      await tester.tap(toggle);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Turn on inactivity wipe?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.widget<SwitchListTile>(toggle).value, isFalse, reason: 'cancel changes nothing');
    }
  });

  testWidgets('changing tab slides the pages: both exist mid-way, one at the end', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider(create: (_) => ThemeNotifier(), child: const MyWidget()),
    );
    await tester.pump(const Duration(seconds: 1));

    final pages = find.byWidgetPredicate(
      (w) => w.key is ValueKey && '${(w.key as ValueKey).value}'.startsWith('tab-page-'),
    );
    expect(pages, findsOneWidget);

    await tester.tap(find.text('Recompose').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(pages, findsNWidgets(2), reason: 'the old page is still sliding out');

    // Side by side at every moment: the new page is always exactly one page width after the old
    // one (translation difference 1.0), so they never overlap and never leave a gap.
    double? shift(String key) {
      final f = find.byKey(ValueKey(key));
      return f.evaluate().isEmpty ? null : tester.widget<FractionalTranslation>(f).translation.dx;
    }

    // The test clock is the real one, so the slide may end before the last check: verify every
    // frame in which both pages exist, and require at least one.
    var checked = 0;
    for (var i = 0; i < 6; i++) {
      final oldShift = shift('tab-page-0');
      final newShift = shift('tab-page-1');
      if (oldShift == null || newShift == null) break;
      expect(newShift - oldShift, closeTo(1.0, 1e-9), reason: 'frame $i');
      expect(oldShift, lessThanOrEqualTo(0), reason: 'the old page moves out to the left');
      expect(newShift, greaterThanOrEqualTo(0), reason: 'the new page comes in from the right');
      checked++;
      await tester.pump(const Duration(milliseconds: 30));
    }
    expect(checked, greaterThanOrEqualTo(1));

    await tester.pump(const Duration(milliseconds: 400));
    expect(pages, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
