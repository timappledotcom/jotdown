import 'dart:convert';
import 'dart:io';
import '../models/note.dart';
import '../models/app_settings.dart';
import 'encryption_service.dart';

class CLINotesService {
  static const String _notesFileName = 'notes.json';
  static const String _indexFileName = 'index.json';
  static const String _settingsFileName = 'settings.json';
  static const String _appDir = 'jotdown';

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
    final dataDir = await _getDataDirectory(settings);
    final indexFile = File('${dataDir.path}/$_indexFileName');

    if (!await indexFile.exists()) {
      return [];
    }

    String indexContent = await indexFile.readAsString();

    // Decrypt index if encryption is enabled
    if (settings.encryptionEnabled && password != null) {
      try {
        final salt = await _getSalt(settings);
        indexContent = EncryptionService.decrypt(indexContent, password, salt);
      } catch (e) {
        throw Exception('Failed to decrypt index: $e');
      }
    }

    final List<dynamic> indexData = json.decode(indexContent);
    final notes = <Note>[];

    for (final item in indexData) {
      final noteFile = File('${dataDir.path}/${item['filename']}');
      if (await noteFile.exists()) {
        String content = await noteFile.readAsString();

        // Decrypt note content if encryption is enabled
        if (settings.encryptionEnabled && password != null) {
          try {
            final salt = await _getSalt(settings);
            content = EncryptionService.decrypt(content, password, salt);
          } catch (e) {
            print('Warning: Failed to decrypt note ${item['id']}: $e');
            continue; // Skip this note if decryption fails
          }
        }

        final note = Note(
          id: item['id'],
          title: item['title'],
          content: content,
          createdAt: DateTime.parse(item['createdAt']),
          updatedAt: DateTime.parse(item['updatedAt']),
        );
        notes.add(note);
      }
    }

    return notes;
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
    final dataDir = await _getDataDirectory(settings);

    // Save individual note files
    for (final note in notes) {
      await _saveFlatFile(note, settings, password);
    }

    // Update index
    await _updateIndex(notes, settings, password);
  }

  Future<void> _saveFlatFile(
    Note note,
    AppSettings settings,
    String? password,
  ) async {
    final dataDir = await _getDataDirectory(settings);
    final filename = '${note.id}.md';
    final noteFile = File('${dataDir.path}/$filename');

    String content = note.content;

    // Encrypt content if encryption is enabled
    if (settings.encryptionEnabled && password != null) {
      final salt = await _getSalt(settings);
      content = EncryptionService.encrypt(content, password, salt);
    }

    await noteFile.writeAsString(content);
  }

  Future<void> _updateIndex(
    List<Note> notes,
    AppSettings settings,
    String? password,
  ) async {
    final dataDir = await _getDataDirectory(settings);
    final indexFile = File('${dataDir.path}/$_indexFileName');

    // Create index data
    final indexData = notes
        .map((note) => {
              'id': note.id,
              'title': note.title,
              'filename': '${note.id}.md',
              'createdAt': note.createdAt.toIso8601String(),
              'updatedAt': note.updatedAt.toIso8601String(),
            })
        .toList();

    // Sort by updated date (newest first)
    indexData.sort((a, b) => DateTime.parse(b['updatedAt'] as String)
        .compareTo(DateTime.parse(a['updatedAt'] as String)));

    String indexJson = json.encode(indexData);

    // Encrypt index if encryption is enabled
    if (settings.encryptionEnabled && password != null) {
      final salt = await _getSalt(settings);
      indexJson = EncryptionService.encrypt(indexJson, password, salt);
    }

    await indexFile.writeAsString(indexJson);
  }

  Future<void> saveNote(
    Note note, [
    AppSettings? settings,
    String? password,
  ]) async {
    settings ??= await loadSettings();

    if (settings.storageLocation == 'shared_preferences') {
      // Use the old method for shared preferences
      final notes = await loadNotes(settings, password);
      final index = notes.indexWhere((n) => n.id == note.id);

      if (index != -1) {
        notes[index] = note;
      } else {
        notes.add(note);
      }

      await saveNotes(notes, settings, password);
    } else {
      // Save individual file for flat file storage
      await _saveFlatFile(note, settings, password);

      // Update index with current note
      final notes = await loadNotes(settings, password);
      final index = notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        notes[index] = note;
      } else {
        notes.add(note);
      }

      await _updateIndex(notes, settings, password);
    }
  }

  Future<void> deleteNote(
    String noteId, [
    AppSettings? settings,
    String? password,
  ]) async {
    settings ??= await loadSettings();

    if (settings.storageLocation == 'shared_preferences') {
      // Use the old method for shared preferences
      final notes = await loadNotes(settings, password);
      notes.removeWhere((note) => note.id == noteId);
      await saveNotes(notes, settings, password);
    } else {
      // Delete individual file for flat file storage
      await _deleteFlatFile(noteId, settings);

      // Update index
      final notes = await loadNotes(settings, password);
      notes.removeWhere((note) => note.id == noteId);
      await _updateIndex(notes, settings, password);
    }
  }

  Future<void> _deleteFlatFile(String noteId, AppSettings settings) async {
    final dataDir = await _getDataDirectory(settings);
    final filename = '$noteId.md';
    final noteFile = File('${dataDir.path}/$filename');

    if (await noteFile.exists()) {
      await noteFile.delete();
    }
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
        return '$homeDir/Documents/$_appDir';
      case 'home':
        final homeDir = Platform.environment['HOME'] ?? '';
        return '$homeDir/$_appDir';
      case 'custom':
        return '${settings.customPath}/$_appDir';
      default:
        final homeDir = Platform.environment['HOME'] ?? '';
        return '$homeDir/.local/share/$_appDir';
    }
  }

  Future<Directory> _getDataDirectory(AppSettings settings) async {
    Directory dataDir;

    switch (settings.storageLocation) {
      case 'documents':
        final homeDir = Platform.environment['HOME'] ?? '';
        dataDir = Directory('$homeDir/Documents/$_appDir');
        break;
      case 'home':
        final homeDir = Platform.environment['HOME'] ?? '';
        dataDir = Directory('$homeDir/$_appDir');
        break;
      case 'custom':
        if (settings.customPath.isEmpty) {
          throw Exception('Custom path not set');
        }
        dataDir = Directory('${settings.customPath}/$_appDir');
        break;
      default: // 'shared_preferences' or fallback
        final homeDir = Platform.environment['HOME'] ?? '';
        dataDir = Directory('$homeDir/.local/share/$_appDir');
        break;
    }

    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }
    return dataDir;
  }

  Future<String> _getSalt(AppSettings settings) async {
    if (settings.storageLocation == 'shared_preferences') {
      final homeDir = Platform.environment['HOME'] ?? '';
      final spFile = File(
          '$homeDir/.local/share/com.example.jotdown/shared_preferences.json');

      if (await spFile.exists()) {
        final spContent = await spFile.readAsString();
        final spData = json.decode(spContent) as Map<String, dynamic>;
        String? salt = spData['flutter.encryption_salt'] as String?;
        if (salt == null) {
          salt = EncryptionService.generateSalt();
          spData['flutter.encryption_salt'] = salt;
          await spFile.writeAsString(json.encode(spData));
        }
        return salt;
      } else {
        throw Exception('SharedPreferences file not found');
      }
    } else {
      final dataDir = await _getDataDirectory(settings);
      final saltFile = File('${dataDir.path}/encryption.salt');
      if (await saltFile.exists()) {
        return await saltFile.readAsString();
      } else {
        final salt = EncryptionService.generateSalt();
        await saltFile.writeAsString(salt);
        return salt;
      }
    }
  }
}
