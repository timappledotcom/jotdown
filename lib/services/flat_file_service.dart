import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/note.dart';
import '../models/app_settings.dart';

/// Simple flat file storage service for Ubuntu desktop app
/// Supports multiple storage locations including Documents folder
class FlatFileService {
  static const String _appDir = 'jotdown';
  static const String _indexFile = 'index.json';
  
  /// Get the data directory based on settings
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

  /// Get the app data directory (legacy method for backward compatibility)
  Future<Directory> get _dataDirectory async {
    final homeDir = Platform.environment['HOME'] ?? '';
    final dataDir = Directory('$homeDir/.local/share/$_appDir');
    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }
    return dataDir;
  }

  /// Load all notes from the flat file system
  Future<List<Note>> loadNotes([AppSettings? settings]) async {
    try {
      final dataDir = settings != null 
          ? await _getDataDirectory(settings)
          : await _dataDirectory;
      final indexFile = File('${dataDir.path}/$_indexFile');
      
      if (!await indexFile.exists()) {
        return [];
      }

      final indexContent = await indexFile.readAsString();
      final List<dynamic> indexData = json.decode(indexContent);
      
      final notes = <Note>[];
      for (final item in indexData) {
        final noteFile = File('${dataDir.path}/${item['filename']}');
        if (await noteFile.exists()) {
          final content = await noteFile.readAsString();
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
    } catch (e) {
      print('Error loading notes: $e');
      return [];
    }
  }

  /// Save a note to the flat file system
  Future<void> saveNote(Note note, [AppSettings? settings]) async {
    try {
      final dataDir = settings != null 
          ? await _getDataDirectory(settings)
          : await _dataDirectory;
      final filename = '${note.id}.md';
      final noteFile = File('${dataDir.path}/$filename');
      
      // Save note content
      await noteFile.writeAsString(note.content);
      
      // Update index
      await _updateIndex(note, filename, settings);
    } catch (e) {
      print('Error saving note: $e');
    }
  }

  /// Delete a note from the flat file system
  Future<void> deleteNote(String noteId, [AppSettings? settings]) async {
    try {
      final dataDir = settings != null 
          ? await _getDataDirectory(settings)
          : await _dataDirectory;
      final filename = '$noteId.md';
      final noteFile = File('${dataDir.path}/$filename');
      
      // Delete note file
      if (await noteFile.exists()) {
        await noteFile.delete();
      }
      
      // Remove from index
      await _removeFromIndex(noteId, settings);
    } catch (e) {
      print('Error deleting note: $e');
    }
  }

  /// Update the index file with note metadata
  Future<void> _updateIndex(Note note, String filename, [AppSettings? settings]) async {
    final dataDir = settings != null 
        ? await _getDataDirectory(settings)
        : await _dataDirectory;
    final indexFile = File('${dataDir.path}/$_indexFile');
    
    List<Map<String, dynamic>> indexData = [];
    
    // Load existing index
    if (await indexFile.exists()) {
      final content = await indexFile.readAsString();
      final List<dynamic> existing = json.decode(content);
      indexData = existing.cast<Map<String, dynamic>>();
    }
    
    // Remove existing entry for this note
    indexData.removeWhere((item) => item['id'] == note.id);
    
    // Add updated entry
    indexData.add({
      'id': note.id,
      'title': note.title,
      'filename': filename,
      'createdAt': note.createdAt.toIso8601String(),
      'updatedAt': note.updatedAt.toIso8601String(),
    });
    
    // Sort by updated date (newest first)
    indexData.sort((a, b) => DateTime.parse(b['updatedAt']).compareTo(DateTime.parse(a['updatedAt'])));
    
    // Save index
    await indexFile.writeAsString(json.encode(indexData));
  }

  /// Remove a note from the index
  Future<void> _removeFromIndex(String noteId, [AppSettings? settings]) async {
    final dataDir = settings != null 
        ? await _getDataDirectory(settings)
        : await _dataDirectory;
    final indexFile = File('${dataDir.path}/$_indexFile');
    
    if (!await indexFile.exists()) {
      return;
    }
    
    final content = await indexFile.readAsString();
    final List<dynamic> indexData = json.decode(content);
    
    // Remove the note
    indexData.removeWhere((item) => item['id'] == noteId);
    
    // Save updated index
    await indexFile.writeAsString(json.encode(indexData));
  }

  /// Get the storage path for display
  String get storagePath {
    final homeDir = Platform.environment['HOME'] ?? '';
    return '$homeDir/.local/share/$_appDir';
  }

  /// Get the storage path for a specific settings configuration
  Future<String> getStoragePathForSettings(AppSettings settings) async {
    final dataDir = await _getDataDirectory(settings);
    return dataDir.path;
  }
}