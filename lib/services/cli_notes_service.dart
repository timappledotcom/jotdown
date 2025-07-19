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

  Future<void> saveSettings(AppSettings settings) async {
    try {
      final settingsFile = await _getSettingsFile();
      await settingsFile.parent.create(recursive: true);

      final settingsJson = json.encode(settings.toJson());
      await settingsFile.writeAsString(settingsJson);
    } catch (e) {
      print('Error saving settings: $e');
    }
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
    } catch (e) {
      print('Error loading notes: $e');
      return [];
    }
  }

  Future<void> saveNotes(
    List<Note> notes, [
    AppSettings? settings,
    String? password,
  ]) async {
    try {
      settings ??= await loadSettings();
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
    } catch (e) {
      print('Error saving notes: $e');
    }
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
        // Use ~/.local/share/jotdown for shared_preferences equivalent
        final homeDir = Platform.environment['HOME'] ?? '';
        directoryPath = '$homeDir/.local/share/jotdown';
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
        return '$homeDir/.local/share/jotdown';
    }
  }
}
