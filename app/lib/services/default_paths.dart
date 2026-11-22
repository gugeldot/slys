import 'dart:io';

import 'package:path/path.dart' as p;

/// The user's Desktop folder, found without asking the OS anything exotic:
/// * Linux: `XDG_DESKTOP_DIR` from `user-dirs.dirs` (so "Escritorio", "Schreibtisch"... work),
///   then `~/Desktop`.
/// * Windows: the OneDrive-redirected Desktop if there is one, else `%USERPROFILE%\Desktop`.
/// * macOS: `~/Desktop`.
/// Falls back to the home folder when no Desktop exists.
String desktopDir() {
  final env = Platform.environment;
  final home = Platform.isWindows ? env['USERPROFILE'] : env['HOME'];
  if (home == null || home.isEmpty) return Directory.current.path;

  final candidates = <String>[];
  if (Platform.isLinux) {
    final fromXdg = _xdgDesktop(home, env['XDG_CONFIG_HOME']);
    if (fromXdg != null) candidates.add(fromXdg);
  }
  if (Platform.isWindows) {
    final oneDrive = env['OneDrive'];
    if (oneDrive != null && oneDrive.isNotEmpty)
      candidates.add(p.join(oneDrive, 'Desktop'));
  }
  candidates.add(p.join(home, 'Desktop'));

  for (final c in candidates) {
    try {
      if (Directory(c).existsSync()) return c;
    } catch (_) {}
  }
  return home;
}

String? _xdgDesktop(String home, String? configHome) {
  final re = RegExp(r'^\s*XDG_DESKTOP_DIR\s*=\s*"?([^"]*)"?\s*$');
  for (final base in [
    if (configHome != null && configHome.isNotEmpty) configHome,
    p.join(home, '.config'),
  ]) {
    try {
      for (final line
          in File(p.join(base, 'user-dirs.dirs')).readAsLinesSync()) {
        final m = re.firstMatch(line);
        if (m != null) {
          final dir = m.group(1)!.replaceAll(r'$HOME', home);
          if (dir.isNotEmpty) return dir;
        }
      }
    } catch (_) {
      // missing or unreadable: try the next place
    }
  }
  return null;
}

/// Where fragments go (and are looked for) unless the user chose something else.
String defaultFragmentsDir() => p.join(desktopDir(), 'slys_fragments');
