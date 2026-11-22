import 'dart:math' as math;

import 'common_passwords.dart';

/// Requirements for the password used to *fragment* (rebuilding accepts whatever was used).
///
/// Length and unpredictability are what matter against offline guessing, not which character
/// classes appear (NIST SP 800-63B, OWASP): a long phrase needs no symbol, and "Password1!" has
/// every class and is still guessed in seconds. So the rules are: long enough, not a commonly
/// used password, not weak according to the strength meter, and typed twice the same.
class PasswordRule {
  final String label;
  final bool Function(String password, String repeat) met;

  const PasswordRule(this.label, this.met);
}

const int kMinPasswordLength = 12;

enum PasswordStrength { weak, fair, good, strong }

extension PasswordStrengthLabel on PasswordStrength {
  String get label => switch (this) {
        PasswordStrength.weak => 'Weak',
        PasswordStrength.fair => 'Fair',
        PasswordStrength.good => 'Good',
        PasswordStrength.strong => 'Strong',
      };
}

/// Weakest strength that is accepted.
const PasswordStrength kMinStrength = PasswordStrength.fair;

/// Rough guessing entropy in bits. Deliberately pessimistic: every character is worth less than
/// the size of its alphabet suggests, repeats and sequences are almost free, and a repeated
/// block counts once. Words and common passwords are handled by [CommonPasswords].
double estimateBits(String password) {
  final runes = password.runes.toList();
  if (runes.isEmpty) return 0;

  // A repeated block ("abcabcabc") is worth only the block.
  for (var size = 1; size <= runes.length ~/ 2; size++) {
    if (runes.length % size != 0) continue;
    var repeats = true;
    for (var i = size; i < runes.length && repeats; i++) {
      repeats = runes[i] == runes[i - size];
    }
    if (repeats) return estimateBits(String.fromCharCodes(runes.sublist(0, size)));
  }

  var pool = 0;
  if (runes.any((r) => _isLower(r))) pool += 26;
  if (runes.any((r) => _isUpper(r))) pool += 26;
  if (runes.any((r) => r >= 0x30 && r <= 0x39)) pool += 10;
  if (runes.any((r) => r < 0x80 && !_isLower(r) && !_isUpper(r) && !(r >= 0x30 && r <= 0x39))) {
    pool += 33;
  }
  if (runes.any((r) => r >= 0x80)) pool += 64;
  final perChar = math.log(pool) / math.ln2 * 0.75;

  var bits = 0.0;
  final seen = <int>{};
  for (var i = 0; i < runes.length; i++) {
    if (i >= 1 && runes[i] == runes[i - 1]) {
      bits += 0.5;
    } else if (i >= 2 &&
        runes[i] - runes[i - 1] == runes[i - 1] - runes[i - 2] &&
        (runes[i] - runes[i - 1]).abs() == 1) {
      bits += 1;
    } else if (seen.contains(runes[i])) {
      bits += perChar * 0.5;
    } else {
      bits += perChar;
    }
    seen.add(runes[i]);
  }
  return bits;
}

bool _isLower(int r) => r >= 0x61 && r <= 0x7a;
bool _isUpper(int r) => r >= 0x41 && r <= 0x5a;

PasswordStrength passwordStrength(String password) {
  if (password.isEmpty || CommonPasswords.isCommon(password)) return PasswordStrength.weak;
  final bits = estimateBits(password);
  if (bits < 45) return PasswordStrength.weak;
  if (bits < 65) return PasswordStrength.fair;
  if (bits < 85) return PasswordStrength.good;
  return PasswordStrength.strong;
}

final List<PasswordRule> passwordRules = [
  PasswordRule('At least $kMinPasswordLength characters', (p, _) => p.runes.length >= kMinPasswordLength),
  PasswordRule('Not a commonly used password', (p, _) => p.isNotEmpty && !CommonPasswords.isCommon(p)),
  PasswordRule(
    'Strength at least ${kMinStrength.label}',
    (p, _) => passwordStrength(p).index >= kMinStrength.index,
  ),
  PasswordRule('Both passwords match', (p, r) => p.isNotEmpty && p == r),
];

/// True when every rule is met.
bool passwordMeetsRules(String? password, String? repeat) {
  final p = password ?? '';
  final r = repeat ?? '';
  return passwordRules.every((rule) => rule.met(p, r));
}
