import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';
import '../models/app_settings.dart';
import 'encryption_service.dart';

class NotesService {
  static const String _notesKey = 'notes_data';
  static const String _indexFileName = 'index.json';
  static const String _appDir = 'jotdown';

  Future<List<Note>> loadNotes(AppSettings settings, [String? password]) async {
    try {
      if (settings.storageLocation == 'shared_preferences') {
        return await _loadFromSharedPreferences(settings, password);
      } else {
        return await _loadFromFlatFiles(settings, password);
      }
    } catch (e) {
      print('Error loading notes: $e');
      return [];
    }
  }

  Future<void> saveNotes(
    List<Note> notes,
    AppSettings settings, [
    String? password,
  ]) async {
    try {
      if (settings.storageLocation == 'shared_preferences') {
        await _saveToSharedPreferences(notes, settings, password);
      } else {
        // For flat file storage, we don't save all notes at once
        // Individual notes are saved via saveNote method
        await _updateIndex(notes, settings);
      }
    } catch (e) {
      print('Error saving notes: $e');
    }
  }

  Future<List<Note>> _loadFromSharedPreferences(
    AppSettings settings, [
    String? password,
  ]) async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getString(_notesKey);

    if (notesJson == null) {
      return [];
    }

    String jsonData = notesJson;

    // Decrypt if encryption is enabled
    if (settings.encryptionEnabled && password != null) {
      try {
        // For shared preferences, we store the salt separately
        final salt = prefs.getString('encryption_salt');
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

  Future<void> _saveToSharedPreferences(
    List<Note> notes,
    AppSettings settings, [
    String? password,
  ]) async {
    final prefs = await SharedPreferences.getInstance();
    String notesJson = json.encode(notes.map((note) => note.toJson()).toList());

    // Encrypt if encryption is enabled
    if (settings.encryptionEnabled && password != null) {
      // For shared preferences, we store the salt separately
      String? salt = prefs.getString('encryption_salt');
      if (salt != null) {
        notesJson = EncryptionService.encrypt(notesJson, password, salt);
      }
    }

    await prefs.setString(_notesKey, notesJson);
  }

  Future<List<Note>> _loadFromFlatFiles(
    AppSettings settings, [
    String? password,
  ]) async {
    final dataDir = await _getDataDirectory(settings);
    final indexFile = File('${dataDir.path}/$_indexFileName');
    List<dynamic> indexData = [];
    if (await indexFile.exists()) {
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
      indexData = json.decode(indexContent);
    }
    final notes = <Note>[];
    final indexedFilenames = indexData.map((item) => item['filename'] as String).toSet();
    
    // Add notes from index
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
    
    // Only scan for new files if this is the first load or index is empty
    if (indexData.isEmpty) {
      final files = dataDir.listSync().whereType<File>().where((f) => 
        f.path.endsWith('.md') && 
        !f.path.contains('index.json') &&
        !indexedFilenames.contains(f.uri.pathSegments.last)
      ).toList();
      
      bool hasNewFiles = false;
      for (final file in files) {
        try {
          final filename = file.uri.pathSegments.last;
          if (!indexedFilenames.contains(filename)) {
            final content = await file.readAsString();
            final id = DateTime.now().millisecondsSinceEpoch.toString();
            final now = DateTime.now();
            final firstLine = content.split('\n').first.trim();
            final title = firstLine.isNotEmpty ? firstLine.replaceAll(RegExp(r'^#+\s*'), '') : filename.replaceAll('.md', '');
            final newFilename = '$id.md';
            final newFilePath = '${dataDir.path}/$newFilename';
            
            // Only proceed if the new file doesn't already exist
            if (!File(newFilePath).existsSync()) {
              await File(newFilePath).writeAsString(content);
              await file.delete();
              
              final note = Note(
                id: id,
                title: title,
                content: content,
                createdAt: now,
                updatedAt: now,
              );
              notes.add(note);
              indexData.add({
                'id': id,
                'title': title,
                'filename': newFilename,
                'createdAt': now.toIso8601String(),
                'updatedAt': now.toIso8601String(),
              });
              hasNewFiles = true;
            }
          }
        } catch (e) {
          print('Warning: Failed to import file ${file.path}: $e');
        }
      }
      
      // Save updated index only if new files were added
      if (hasNewFiles) {
        await _updateIndex(notes, settings);
      }
    }
    return notes;
  }

  Future<void> _updateIndex(
    List<Note> notes,
    AppSettings settings,
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
    if (settings.encryptionEnabled) {
      // Note: This method is called without password, so we skip encryption here
      // Individual note saving handles encryption
    }

    await indexFile.writeAsString(indexJson);
  }

  Future<Directory> _getDataDirectory(AppSettings settings) async {
    Directory dataDir;

    switch (settings.storageLocation) {
      case 'documents':
        final documentsDir = await getApplicationDocumentsDirectory();
        dataDir = Directory('${documentsDir.path}/$_appDir');
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
      final prefs = await SharedPreferences.getInstance();
      String? salt = prefs.getString('encryption_salt');
      if (salt == null) {
        salt = EncryptionService.generateSalt();
        await prefs.setString('encryption_salt', salt);
      }
      return salt;
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

  Future<void> saveNote(
    Note note,
    List<Note> existingNotes,
    AppSettings settings, [
    String? password,
  ]) async {
    if (settings.storageLocation == 'shared_preferences') {
      // Use the old method for shared preferences
      final index = existingNotes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        existingNotes[index] = note;
      } else {
        existingNotes.add(note);
      }
      await saveNotes(existingNotes, settings, password);
    } else {
      // Save individual file for flat file storage
      await _saveFlatFile(note, settings, password);

      // Update the existing notes list
      final index = existingNotes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        existingNotes[index] = note;
      } else {
        existingNotes.add(note);
      }

      // Update index
      await _updateIndex(existingNotes, settings);
    }
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

  Future<void> deleteNote(
    String noteId,
    List<Note> existingNotes,
    AppSettings settings, [
    String? password,
  ]) async {
    if (settings.storageLocation == 'shared_preferences') {
      // Use the old method for shared preferences
      existingNotes.removeWhere((note) => note.id == noteId);
      await saveNotes(existingNotes, settings, password);
    } else {
      // Delete individual file for flat file storage
      await _deleteFlatFile(noteId, settings);

      // Update the existing notes list
      existingNotes.removeWhere((note) => note.id == noteId);

      // Update index
      await _updateIndex(existingNotes, settings);
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

  Future<bool> migrateNotes(
    AppSettings oldSettings,
    AppSettings newSettings, [
    String? password,
  ]) async {
    try {
      // Load notes from old location
      final notes = await loadNotes(oldSettings, password);

      // Save notes to new location
      await saveNotes(notes, newSettings, password);

      // Optionally clear old location (for now, we'll keep them as backup)

      return true;
    } catch (e) {
      print('Error migrating notes: $e');
      return false;
    }
  }
}
