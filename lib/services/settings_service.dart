import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
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

  /// Get available storage locations for the current platform
  Future<List<String>> getAvailableStorageLocations() async {
    final locations = <String>['shared_preferences'];
    
    // Add documents folder option
    try {
      await getApplicationDocumentsDirectory();
      locations.add('documents');
    } catch (e) {
      print('Documents directory not available: $e');
    }
    
    // Add home directory option (Linux/macOS)
    if (Platform.isLinux || Platform.isMacOS) {
      final homeDir = Platform.environment['HOME'];
      if (homeDir != null && homeDir.isNotEmpty) {
        locations.add('home');
      }
    }
    
    // Always add custom option
    locations.add('custom');
    
    return locations;
  }

  /// Get display name for storage location
  String getStorageLocationDisplayName(String location) {
    switch (location) {
      case 'shared_preferences':
        return 'App Data';
      case 'documents':
        return 'Documents Folder';
      case 'home':
        return 'Home Directory';
      case 'custom':
        return 'Custom Location';
      default:
        return 'Unknown';
    }
  }

  /// Get the actual storage path for a given location
  Future<String> getStoragePath(AppSettings settings) async {
    switch (settings.storageLocation) {
      case 'shared_preferences':
        return 'Stored in app data (no file path)';
      case 'documents':
        try {
          final documentsDir = await getApplicationDocumentsDirectory();
          return '${documentsDir.path}/jotdown/';
        } catch (e) {
          return 'Documents/jotdown/';
        }
      case 'home':
        final homeDir = Platform.environment['HOME'] ?? '';
        return '$homeDir/jotdown/';
      case 'custom':
        return settings.customPath.isNotEmpty
            ? '${settings.customPath}/jotdown/'
            : 'No path selected';
      default:
        return 'Unknown location';
    }
  }
}
