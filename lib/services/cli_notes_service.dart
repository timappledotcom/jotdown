import 'dart:convert';
import 'dart:io';
import '../models/note.dart';
import '../models/app_settings.dart';
import 'encryption_service.dart';

class CLINotesService {
  static const String _notesFileName = 'notes.json';
  static const String _settingsFileName = 'settings.json';

  Future<AppSettings> loadSettings() async {
    try {
      // First try to load from GUI SharedPreferences format
      final guiSettings = await _loadSettingsFromSharedPreferences();
      if (guiSettings != null) {
        return guiSettings;
      }

      // Fallback to CLI-specific settings file
      final settingsFile = await _getSettingsFile();
      if (!await settingsFile.exists()) {
        return AppSettings();
      }

      final content = await settingsFile.readAsString();
      final Map<String, dynamic> settingsMap = json.decode(content);
      return AppSettings.fromJson(settingsMap);
    } catch (e) {
      print('Error loading settings: $e');
      return AppSettings();
    }
  }

  Future<AppSettings?> _loadSettingsFromSharedPreferences() async {
    try {
      final homeDir = Platform.environment['HOME'] ?? '';
      final spFile = File(
          '$homeDir/.local/share/com.example.jotdown/shared_preferences.json');

      if (!await spFile.exists()) {
        return null;
      }

      final spContent = await spFile.readAsString();
      final spData = json.decode(spContent) as Map<String, dynamic>;
      final settingsJson = spData['flutter.app_settings'] as String?;

      if (settingsJson == null) {
        return null;
      }

      final settingsMap = json.decode(settingsJson) as Map<String, dynamic>;
      return AppSettings.fromJson(settingsMap);
    } catch (e) {
      return null; // Fallback to CLI settings
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    try {
      // Check if GUI SharedPreferences file exists, if so update it
      final homeDir = Platform.environment['HOME'] ?? '';
      final spFile = File(
          '$homeDir/.local/share/com.example.jotdown/shared_preferences.json');

      if (await spFile.exists()) {
        await _saveSettingsToSharedPreferences(settings, spFile);
      } else {
        // Fallback to CLI-specific settings file
        final settingsFile = await _getSettingsFile();
        await settingsFile.parent.create(recursive: true);

        final settingsJson = json.encode(settings.toJson());
        await settingsFile.writeAsString(settingsJson);
      }
    } catch (e) {
      print('Error saving settings: $e');
    }
  }

  Future<void> _saveSettingsToSharedPreferences(
      AppSettings settings, File spFile) async {
    // Load existing SharedPreferences data
    final spContent = await spFile.readAsString();
    final spData = json.decode(spContent) as Map<String, dynamic>;

    // Update the app settings in SharedPreferences format
    final settingsJson = json.encode(settings.toJson());
    spData['flutter.app_settings'] = settingsJson;

    // Write back to SharedPreferences file
    await spFile.writeAsString(json.encode(spData));
  }

  Future<List<Note>> loadNotes([
    AppSettings? settings,
    String? password,
  ]) async {
    try {
      settings ??= await loadSettings();

      // If encryption is enabled but no password provided, return empty list
      if (settings.encryptionEnabled &&
          settings.passwordHash != null &&
          password == null) {
        print('Error: Encryption is enabled but no password provided.');
        return [];
      }

      if (settings.storageLocation == 'shared_preferences') {
        return await _loadFromSharedPreferences(settings, password);
      } else {
        return await _loadFromFile(settings, password);
      }
    } catch (e) {
      print('Error loading notes: $e');
      return [];
    }
  }

  Future<List<Note>> _loadFromSharedPreferences(
    AppSettings settings, [
    String? password,
  ]) async {
    final homeDir = Platform.environment['HOME'] ?? '';
    final spFile = File(
        '$homeDir/.local/share/com.example.jotdown/shared_preferences.json');

    if (!await spFile.exists()) {
      return [];
    }

    final spContent = await spFile.readAsString();
    final spData = json.decode(spContent) as Map<String, dynamic>;
    final notesJson = spData['flutter.notes_data'] as String?;

    if (notesJson == null) {
      return [];
    }

    String jsonData = notesJson;

    // Decrypt if encryption is enabled
    if (settings.encryptionEnabled && password != null) {
      try {
        final salt = spData['flutter.encryption_salt'] as String?;
        if (salt == null) {
          throw Exception('Encryption salt not found');
        }
        jsonData = EncryptionService.decrypt(notesJson, password, salt);
      } catch (e) {
        throw Exception('Failed to decrypt notes: $e');
      }
    }

    final List<dynamic> notesList = json.decode(jsonData);
    return notesList.map((json) => Note.fromJson(json)).toList();
  }

  Future<List<Note>> _loadFromFile(
    AppSettings settings, [
    String? password,
  ]) async {
    final notesFile = await getNotesFile(settings);

    if (!await notesFile.exists()) {
      return [];
    }

    String content = await notesFile.readAsString();

    // Decrypt if encryption is enabled
    if (settings.encryptionEnabled && password != null) {
      try {
        final saltFile = File('${notesFile.path}.salt');
        if (!await saltFile.exists()) {
          throw Exception('Encryption salt file not found');
        }
        final salt = await saltFile.readAsString();
        content = EncryptionService.decrypt(content, password, salt);
      } catch (e) {
        throw Exception('Failed to decrypt notes: $e');
      }
    }

    final List<dynamic> notesList = json.decode(content);
    return notesList.map((json) => Note.fromJson(json)).toList();
  }

  Future<void> saveNotes(
    List<Note> notes, [
    AppSettings? settings,
    String? password,
  ]) async {
    try {
      settings ??= await loadSettings();

      if (settings.storageLocation == 'shared_preferences') {
        await _saveToSharedPreferences(notes, settings, password);
      } else {
        await _saveToFile(notes, settings, password);
      }
    } catch (e) {
      print('Error saving notes: $e');
    }
  }

  Future<void> _saveToSharedPreferences(
    List<Note> notes,
    AppSettings settings, [
    String? password,
  ]) async {
    final homeDir = Platform.environment['HOME'] ?? '';
    final spFile = File(
        '$homeDir/.local/share/com.example.jotdown/shared_preferences.json');

    // Load existing SharedPreferences data
    Map<String, dynamic> spData = {};
    if (await spFile.exists()) {
      final spContent = await spFile.readAsString();
      spData = json.decode(spContent) as Map<String, dynamic>;
    }

    String notesJson = json.encode(notes.map((note) => note.toJson()).toList());

    // Encrypt if encryption is enabled
    if (settings.encryptionEnabled && password != null) {
      final salt = spData['flutter.encryption_salt'] as String?;
      if (salt == null) {
        throw Exception('Encryption salt not found');
      }
      notesJson = EncryptionService.encrypt(notesJson, password, salt);
    }

    // Update the notes data in SharedPreferences format
    spData['flutter.notes_data'] = notesJson;

    // Ensure parent directory exists
    await spFile.parent.create(recursive: true);

    // Write back to SharedPreferences file
    await spFile.writeAsString(json.encode(spData));
  }

  Future<void> _saveToFile(
    List<Note> notes,
    AppSettings settings, [
    String? password,
  ]) async {
    final notesFile = await getNotesFile(settings);
    await notesFile.parent.create(recursive: true);

    String notesJson = json.encode(
      notes.map((note) => note.toJson()).toList(),
    );

    // Encrypt if encryption is enabled
    if (settings.encryptionEnabled && password != null) {
      final saltFile = File('${notesFile.path}.salt');
      String? salt;

      if (await saltFile.exists()) {
        salt = await saltFile.readAsString();
      } else {
        salt = EncryptionService.generateSalt();
        await saltFile.writeAsString(salt);
      }

      notesJson = EncryptionService.encrypt(notesJson, password, salt);
    }

    await notesFile.writeAsString(notesJson);
  }

  Future<void> saveNote(
    Note note, [
    AppSettings? settings,
    String? password,
  ]) async {
    final notes = await loadNotes(settings, password);
    final index = notes.indexWhere((n) => n.id == note.id);

    if (index != -1) {
      notes[index] = note;
    } else {
      notes.add(note);
    }

    await saveNotes(notes, settings, password);
  }

  Future<void> deleteNote(
    String noteId, [
    AppSettings? settings,
    String? password,
  ]) async {
    final notes = await loadNotes(settings, password);
    notes.removeWhere((note) => note.id == noteId);
    await saveNotes(notes, settings, password);
  }

  Future<File> _getSettingsFile() async {
    final homeDir = Platform.environment['HOME'] ?? '';
    final configDir = Directory('$homeDir/.config/jotdown');
    return File('${configDir.path}/$_settingsFileName');
  }

  Future<File> getNotesFile([AppSettings? settings]) async {
    settings ??= await loadSettings();
    String directoryPath;

    switch (settings.storageLocation) {
      case 'documents':
        final homeDir = Platform.environment['HOME'] ?? '';
        directoryPath = '$homeDir/Documents/jotDown';
        break;
      case 'home':
        final homeDir = Platform.environment['HOME'] ?? '';
        directoryPath = '$homeDir/jotDown';
        break;
      case 'custom':
        directoryPath = settings.customPath;
        break;
      default:
        // Use ~/.local/share/com.example.jotdown to match GUI app directory
        final homeDir = Platform.environment['HOME'] ?? '';
        directoryPath = '$homeDir/.local/share/com.example.jotdown';
        break;
    }

    return File('$directoryPath/$_notesFileName');
  }

  String getStorageLocationPath(AppSettings settings) {
    switch (settings.storageLocation) {
      case 'documents':
        final homeDir = Platform.environment['HOME'] ?? '';
        return '$homeDir/Documents/jotDown';
      case 'home':
        final homeDir = Platform.environment['HOME'] ?? '';
        return '$homeDir/jotDown';
      case 'custom':
        return settings.customPath;
      default:
        final homeDir = Platform.environment['HOME'] ?? '';
        return '$homeDir/.local/share/com.example.jotdown';
    }
  }
}
