import 'package:file_selector/file_selector.dart';

/// Native file dialogs (GTK on Linux, so they work inside a Flatpak sandbox; no zenity needed).
Future<String?> pickFilePath({String? initialDirectory}) async {
  final file = await openFile(initialDirectory: initialDirectory);
  return file?.path;
}

Future<String?> pickDirectoryPath({
  String? initialDirectory,
  String? confirmButtonText,
}) => getDirectoryPath(
  initialDirectory: initialDirectory,
  confirmButtonText: confirmButtonText,
);
