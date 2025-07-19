import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';
import '../models/app_settings.dart';
import 'encryption_service.dart';

class NotesService {
  static const String _notesKey = 'notes_data';
  static const String _notesFileName = 'notes.json';

  Future<List<Note>> loadNotes(AppSettings settings, [String? password]) async {
    try {
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

  Future<void> saveNotes(
    List<Note> notes,
    AppSettings settings, [
    String? password,
  ]) async {
    try {
      if (settings.storageLocation == 'shared_preferences') {
        await _saveToSharedPreferences(notes, settings, password);
      } else {
        await _saveToFile(notes, settings, password);
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
      if (salt == null) {
        salt = EncryptionService.generateSalt();
        await prefs.setString('encryption_salt', salt);
      }
      notesJson = EncryptionService.encrypt(notesJson, password, salt);
    }

    await prefs.setString(_notesKey, notesJson);
  }

  Future<List<Note>> _loadFromFile(
    AppSettings settings, [
    String? password,
  ]) async {
    final filePath = await _getNotesFilePath(settings);
    final file = File(filePath);

    if (!await file.exists()) {
      return [];
    }

    String content = await file.readAsString();

    // Decrypt if encryption is enabled
    if (settings.encryptionEnabled && password != null) {
      try {
        // For file storage, we store salt in a separate file
        final saltFile = File('$filePath.salt');
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

  Future<void> _saveToFile(
    List<Note> notes,
    AppSettings settings, [
    String? password,
  ]) async {
    final filePath = await _getNotesFilePath(settings);
    final file = File(filePath);

    // Ensure directory exists
    await file.parent.create(recursive: true);

    String notesJson = json.encode(notes.map((note) => note.toJson()).toList());

    // Encrypt if encryption is enabled
    if (settings.encryptionEnabled && password != null) {
      // For file storage, we store salt in a separate file
      final saltFile = File('$filePath.salt');
      String? salt;

      if (await saltFile.exists()) {
        salt = await saltFile.readAsString();
      } else {
        salt = EncryptionService.generateSalt();
        await saltFile.writeAsString(salt);
      }

      notesJson = EncryptionService.encrypt(notesJson, password, salt);
    }

    await file.writeAsString(notesJson);
  }

  Future<String> _getNotesFilePath(AppSettings settings) async {
    String directoryPath;

    switch (settings.storageLocation) {
      case 'documents':
        final documentsDir = await getApplicationDocumentsDirectory();
        directoryPath = '${documentsDir.path}/jotDown';
        break;
      case 'home':
        final homeDir = Platform.environment['HOME'] ?? '';
        directoryPath = '$homeDir/jotDown';
        break;
      case 'custom':
        directoryPath = settings.customPath;
        break;
      default:
        // Fallback to documents
        final documentsDir = await getApplicationDocumentsDirectory();
        directoryPath = '${documentsDir.path}/jotDown';
        break;
    }

    return '$directoryPath/$_notesFileName';
  }

  Future<void> saveNote(
    Note note,
    List<Note> existingNotes,
    AppSettings settings, [
    String? password,
  ]) async {
    final index = existingNotes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      existingNotes[index] = note;
    } else {
      existingNotes.add(note);
    }
    await saveNotes(existingNotes, settings, password);
  }

  Future<void> deleteNote(
    String noteId,
    List<Note> existingNotes,
    AppSettings settings, [
    String? password,
  ]) async {
    existingNotes.removeWhere((note) => note.id == noteId);
    await saveNotes(existingNotes, settings, password);
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
