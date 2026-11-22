import 'package:flutter_test/flutter_test.dart';
import 'package:slys/utils/password_rules.dart';

void main() {
  bool rule(int i, String p, [String r = '']) => passwordRules[i].met(p, r);

  test('length counts characters, not bytes', () {
    expect(rule(0, 'a' * 9), isFalse);
    expect(rule(0, 'a' * 10), isTrue);
    expect(rule(0, 'ñ' * 10), isTrue);
  });

  test('character classes, including non-English letters', () {
    expect(rule(1, 'abc'), isFalse);
    expect(rule(1, 'abC'), isTrue);
    expect(rule(1, 'Ñandú'), isTrue);
    expect(rule(2, 'ABC'), isFalse);
    expect(rule(2, 'ABc'), isTrue);
    expect(rule(3, 'abc'), isFalse);
    expect(rule(3, 'abc1'), isTrue);
    expect(rule(4, 'abc123 '), isFalse, reason: 'space is not a symbol');
    expect(rule(4, 'abc!'), isTrue);
    expect(rule(4, 'abc_'), isTrue);
  });

  test('match rule needs a non-empty equal repeat', () {
    expect(rule(5, '', ''), isFalse);
    expect(rule(5, 'x', 'y'), isFalse);
    expect(rule(5, 'x', 'x'), isTrue);
  });

  test('a good password passes, a weak one does not', () {
    const good = 'Correct-Horse-Battery-9';
    expect(passwordMeetsRules(good, good), isTrue);
    expect(passwordMeetsRules(good, 'other'), isFalse);
    expect(passwordMeetsRules('password', 'password'), isFalse);
    expect(passwordMeetsRules(null, null), isFalse);
  });
}
