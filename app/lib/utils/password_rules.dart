/// Requirements for the password used to *fragment* (rebuilding accepts whatever was used).
///
/// Length is what matters most against offline guessing; the character classes keep people from
/// picking a long but trivial word. Relax or extend the list here: the UI and the Slys! button
/// both read it.
class PasswordRule {
  final String label;
  final bool Function(String password, String repeat) met;

  const PasswordRule(this.label, this.met);
}

const int kMinPasswordLength = 12;

final _upper = RegExp(r'\p{Lu}', unicode: true);
final _lower = RegExp(r'\p{Ll}', unicode: true);
final _digit = RegExp(r'\p{Nd}', unicode: true);
final _symbol = RegExp(r'[^\p{L}\p{Nd}\s]', unicode: true);

final List<PasswordRule> passwordRules = [
  PasswordRule('At least $kMinPasswordLength characters', (p, _) => p.runes.length >= kMinPasswordLength),
  PasswordRule('An uppercase letter', (p, _) => _upper.hasMatch(p)),
  PasswordRule('A lowercase letter', (p, _) => _lower.hasMatch(p)),
  PasswordRule('A number', (p, _) => _digit.hasMatch(p)),
  PasswordRule('A symbol (such as ! ? # - _ . @)', (p, _) => _symbol.hasMatch(p)),
  PasswordRule('Both passwords match', (p, r) => p.isNotEmpty && p == r),
];

/// True when every rule is met.
bool passwordMeetsRules(String? password, String? repeat) {
  final p = password ?? '';
  final r = repeat ?? '';
  return passwordRules.every((rule) => rule.met(p, r));
}
