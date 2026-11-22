import 'package:file_selector/file_selector.dart';

/// Native file dialogs. They go through the desktop portal when the app runs in a Flatpak
/// sandbox, which is why this uses `file_selector` (GTK) and not a zenity-based picker.
Future<String?> pickFilePath() async {
  final file = await openFile();
  return file?.path;
}

Future<String?> pickDirectoryPath() => getDirectoryPath();
