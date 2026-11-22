import 'package:flutter_test/flutter_test.dart';
import 'package:slys/utils/common_passwords.dart';
import 'package:slys/utils/password_rules.dart';

void main() {
  setUp(() => CommonPasswords.setForTest(['password', 'dragon', 'iloveyou123456', 'qwertyuiop12']));

  bool rule(int i, String p, [String r = '']) => passwordRules[i].met(p, r);

  test('length counts characters, not bytes, and is 12', () {
    expect(rule(0, 'a' * 11), isFalse);
    expect(rule(0, 'a' * 12), isTrue);
    expect(rule(0, 'ñ' * 12), isTrue);
  });

  test('common passwords are refused, also with digits and symbols around', () {
    expect(CommonPasswords.isCommon('PASSWORD'), isTrue);
    expect(CommonPasswords.isCommon('Dragon2024!'), isTrue);
    expect(CommonPasswords.isCommon('1!dragon'), isTrue);
    expect(CommonPasswords.isCommon('IloveYou123456'), isTrue);
    expect(CommonPasswords.isCommon('purple-dragon-lamp'), isFalse);
    expect(rule(1, 'qwertyuiop12'), isFalse);
    expect(rule(1, 'Tr4vel-Mug-Sunny'), isTrue);
  });

  test('strength: no character classes needed for a long phrase', () {
    expect(passwordStrength('aaaaaaaaaaaa'), PasswordStrength.weak);
    expect(passwordStrength('abcabcabcabc'), PasswordStrength.weak);
    expect(passwordStrength('123456789012'), PasswordStrength.weak);
    expect(passwordStrength('Password1!'), PasswordStrength.weak);
    expect(passwordStrength('correct horse battery staple').index, greaterThanOrEqualTo(PasswordStrength.good.index));
    expect(passwordStrength('Tr4vel-Mug-Sunny#92').index, greaterThanOrEqualTo(PasswordStrength.good.index));
    expect(passwordStrength(''), PasswordStrength.weak);
  });

  test('match rule needs a non-empty equal repeat', () {
    expect(rule(3, '', ''), isFalse);
    expect(rule(3, 'x', 'y'), isFalse);
    expect(rule(3, 'x', 'x'), isTrue);
  });

  test('a good password passes, a weak one does not', () {
    const good = 'correct horse battery staple';
    expect(passwordMeetsRules(good, good), isTrue);
    expect(passwordMeetsRules(good, 'other'), isFalse);
    expect(passwordMeetsRules('password', 'password'), isFalse);
    expect(passwordMeetsRules('aaaaaaaaaaaa', 'aaaaaaaaaaaa'), isFalse);
    expect(passwordMeetsRules(null, null), isFalse);
  });
}
