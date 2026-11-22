import 'package:flutter/services.dart' show rootBundle;

/// Offline list of the most used passwords (built from SecLists, MIT licence; see
/// assets/data/README.md). An attacker who gets a seed tries these first, so they are refused
/// no matter how complex they look.
class CommonPasswords {
  CommonPasswords._();

  static Set<String> _words = const {};

  /// Loads the list once. Until it is loaded nothing is reported as common.
  static Future<void> load() async {
    if (_words.isNotEmpty) return;
    final raw = await rootBundle.loadString('assets/data/common_passwords.txt');
    _words = raw.split('\n').where((l) => l.isNotEmpty).toSet();
  }

  /// For tests.
  static void setForTest(Iterable<String> words) => _words = words.toSet();

  static final _tail = RegExp(r'[\d\p{P}\p{S}\s]+$', unicode: true);
  static final _head = RegExp(r'^[\d\p{P}\p{S}\s]+', unicode: true);

  /// True when the password is a listed one, alone or only dressed with digits and symbols at
  /// either end ("Dragon2024!" is just "dragon").
  static bool isCommon(String password) {
    if (_words.isEmpty) return false;
    final p = password.toLowerCase();
    if (_words.contains(p)) return true;
    final core = p.replaceFirst(_tail, '').replaceFirst(_head, '');
    return core.length >= 5 && _words.contains(core);
  }
}
