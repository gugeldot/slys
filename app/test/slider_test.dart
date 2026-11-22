import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slys/screens/main/main_fn.dart';

void main() {
  testWidgets('clicking the track glides to the value, counting on the way', (tester) async {
    var value = 10;
    final seen = <int>[];
    int? ended;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => SliderWidget(
            currentValue: value,
            onChanged: (v) {
              seen.add(v);
              setState(() => value = v);
            },
            onChangeEnd: (v) => ended = v,
          ),
        ),
      ),
    ));

    // Click near the right end of the track.
    final slider = find.byType(Slider);
    final rect = tester.getRect(slider);
    await tester.tapAt(Offset(rect.right - 30, rect.center.dy));
    await tester.pump();

    // Right after the click it has not arrived yet...
    await tester.pump(const Duration(milliseconds: 60));
    expect(value, lessThan(90));
    expect(value, greaterThan(10));

    // ...it keeps counting up, and ends on the clicked value.
    await tester.pump(const Duration(milliseconds: 60));
    final later = value;
    expect(later, greaterThan(10));
    await tester.pumpAndSettle();
    expect(value, greaterThan(85));
    expect(ended, value);
    // It went through many intermediate values, not a single jump.
    expect(seen.toSet().length, greaterThan(5));
    final sorted = [...seen]..sort();
    expect(seen, sorted, reason: 'the number only goes up on the way to a larger target');
  });

  testWidgets('dragging the thumb follows immediately', (tester) async {
    var value = 50;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => SliderWidget(
            currentValue: value,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    ));
    final thumb = tester.getCenter(find.byType(Slider));
    await tester.dragFrom(thumb, const Offset(-100, 0));
    await tester.pump();
    expect(value, lessThan(50));
  });
}
