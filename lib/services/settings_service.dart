import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

class SettingsService {
  static const String _settingsKey = 'app_settings';

  Future<AppSettings> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);

      if (settingsJson == null) {
        return AppSettings();
      }

      final Map<String, dynamic> settingsMap = json.decode(settingsJson);
      return AppSettings.fromJson(settingsMap);
    } catch (e) {
      print('Error loading settings: $e');
      return AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = json.encode(settings.toJson());
      await prefs.setString(_settingsKey, settingsJson);
    } catch (e) {
      print('Error saving settings: $e');
    }
  }

  Future<String> getDefaultNotesDirectory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final notesDir = Directory('${directory.path}/jotDown');
      if (!await notesDir.exists()) {
        await notesDir.create(recursive: true);
      }
      return notesDir.path;
    } catch (e) {
      print('Error getting default directory: $e');
      final homeDir = Platform.environment['HOME'] ?? '';
      return '$homeDir/Documents/jotDown';
    }
  }

  Future<List<String>> getAvailableStorageLocations() async {
    final locations = <String>[];

    // Always available
    locations.add('shared_preferences');

    // Try to get common directories
    try {
      await getApplicationDocumentsDirectory();
      locations.add('documents');
    } catch (e) {
      print('Documents directory not available: $e');
    }

    try {
      final homeDir = Platform.environment['HOME'];
      if (homeDir != null) {
        locations.add('home');
      }
    } catch (e) {
      print('Home directory not available: $e');
    }

    // Custom location is always an option
    locations.add('custom');

    return locations;
  }

  String getStorageLocationDisplayName(String location) {
    switch (location) {
      case 'shared_preferences':
        return 'App Data (Shared Preferences)';
      case 'documents':
        return 'Documents Folder';
      case 'home':
        return 'Home Directory';
      case 'custom':
        return 'Custom Location';
      default:
        return location;
    }
  }
}
