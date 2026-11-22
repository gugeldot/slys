import 'package:shared_preferences/shared_preferences.dart';

const String savedFilePathKey = "selectedFilePath";

Future<void> saveSelectedFilePath(String path) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(savedFilePathKey, path);
}

Future<String?> loadSelectedFilePath() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(savedFilePathKey);
}

