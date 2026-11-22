import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slys/screens/main/main_fn.dart';

/// Two steps: the first frame starts the icon cross-fade, the second lets it finish.
/// (pumpAndSettle would never return: the text caret blinks forever.)
Future<void> settle(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('unmet requirements are neutral, turn red while a password field has the cursor, '
      'and no error line pops in', (tester) async {
    final pw = TextEditingController();
    final repeat = TextEditingController();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: PasswordAndEncryptionOptions(
              encryptionLevel: 'Total',
              onEncryptionChanged: (_) {},
              password: pw.text,
              onPasswordChangedText: (_) => setState(() {}),
              passwordController: pw,
              repeatPassword: repeat.text,
              onRepeatPasswordChanged: (_) => setState(() {}),
              repeatPasswordController: repeat,
            ),
          ),
        ),
      ),
    ));

    // Nothing focused: all six are neutral circles, none red or green.
    expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(6));
    expect(find.byIcon(Icons.cancel), findsNothing);
    expect(find.byIcon(Icons.check_circle), findsNothing);

    // Cursor in the first field: everything unmet turns red.
    await tester.tap(find.byType(TextField).first);
    await settle(tester);
    expect(find.byIcon(Icons.cancel), findsNWidgets(6));

    // Typing makes the ones that are met green and leaves the rest red.
    await tester.enterText(find.byType(TextField).first, 'Abcdefghij1!');
    await settle(tester);
    expect(find.byIcon(Icons.check_circle), findsNWidgets(5));
    expect(find.byIcon(Icons.cancel), findsOneWidget); // "Both passwords match"

    // A different repeat does not add an error line (it would push the page down).
    await tester.tap(find.byType(TextField).at(1));
    await tester.enterText(find.byType(TextField).at(1), 'different');
    await settle(tester);
    expect(find.text('Passwords do not match'), findsNothing);
    expect(find.byIcon(Icons.cancel), findsOneWidget);

    // The same repeat: all six green.
    await tester.enterText(find.byType(TextField).at(1), 'Abcdefghij1!');
    await settle(tester);
    expect(find.byIcon(Icons.check_circle), findsNWidgets(6));
  });
}
