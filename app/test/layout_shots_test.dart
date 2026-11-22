// Developer tool: renders the real UI at several window sizes to test/shots/*.png so you can look
// at it without a display. Needs the bridge library, so it is skipped unless SLYS_BRIDGE_LIB is set:
//   SLYS_BRIDGE_LIB=../target/debug/libslys_bridge.so \
//   FLUTTER_FONTS=<flutter>/bin/cache/artifacts/material_fonts \
//   SLYS_CONFIG_DIR=$(mktemp -d) flutter test test/layout_shots_test.dart --update-goldens
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slys/custom/theme.dart';
import 'package:slys/main.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:slys/src/rust/frb_generated.dart';

Future<void> _font(String family, String path) async {
  final bytes = File(path).readAsBytesSync();
  final loader = FontLoader(family)..addFont(Future.value(ByteData.view(bytes.buffer)));
  await loader.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fonts = Platform.environment['FLUTTER_FONTS'];

  final sizes = <String, Size>{
    'wide': const Size(1400, 900),
    'medium': const Size(800, 900),
    'narrow': const Size(380, 800),
  };

  for (final e in sizes.entries) {
    testWidgets('home ${e.key}', skip: Platform.environment['SLYS_BRIDGE_LIB'] == null, (tester) async {
      SharedPreferences.setMockInitialValues({});
      final lib = Platform.environment['SLYS_BRIDGE_LIB'];
      await tester.runAsync(() async {
        try {
          await RustLib.init(externalLibrary: lib == null ? null : ExternalLibrary.open(lib));
        } catch (e) {
          // ignore: avoid_print
          print('RUSTLIB INIT: $e');
        }
      });
      if (fonts != null) {
        await tester.runAsync(() async {
          await _font('Roboto', '$fonts/Roboto-Regular.ttf');
          await _font('MaterialIcons', '$fonts/MaterialIcons-Regular.otf');
        });
      }
      tester.view.physicalSize = e.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ChangeNotifierProvider(create: (_) => ThemeNotifier(), child: const MyWidget()),
      );
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/home_${e.key}.png'));

      for (final tab in ['Recompose', 'Settings', 'Tutorial', 'About']) {
        await tester.tap(find.text(tab).first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$tab at ${e.key}');
        await expectLater(
            find.byType(MaterialApp), matchesGoldenFile('shots/${tab.toLowerCase()}_${e.key}.png'));
      }
    });
  }
}
