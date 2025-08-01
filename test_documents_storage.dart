#!/usr/bin/env dart

import 'dart:io';
import 'lib/models/app_settings.dart';
import 'lib/models/note.dart';
import 'lib/services/notes_service.dart';
import 'lib/services/settings_service.dart';

void main() async {
  print('=== Testing Documents Folder Storage ===\n');

  // Create settings for documents storage
  final settings = AppSettings(
    storageLocation: 'documents',
    themeMode: 'system',
    encryptionEnabled: false,
  );

  final notesService = NotesService();
  final settingsService = SettingsService();

  try {
    // Get the storage path
    final storagePath = await settingsService.getStoragePath(settings);
    print('Storage path: $storagePath');

    // Create a test note
    final testNote = Note(
      id: 'test-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Test Note in Documents',
      content: '# Test Note\n\nThis note is stored in the Documents/jotdown folder!\n\nCreated at: ${DateTime.now()}',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    print('\nCreating test note...');
    await notesService.saveNotes([testNote], settings);
    print('✓ Note saved successfully');

    // Load notes back
    print('\nLoading notes...');
    final loadedNotes = await notesService.loadNotes(settings);
    print('✓ Loaded ${loadedNotes.length} note(s)');

    if (loadedNotes.isNotEmpty) {
      final note = loadedNotes.first;
      print('\nNote details:');
      print('  ID: ${note.id}');
      print('  Title: ${note.title}');
      print('  Content preview: ${note.content.substring(0, 50)}...');
      print('  Created: ${note.createdAt}');
    }

    // Check if the file actually exists
    final documentsPath = await settingsService.getStoragePath(settings);
    final notesFile = File('$documentsPath/notes.json');
    if (await notesFile.exists()) {
      print('\n✓ Notes file exists at: ${notesFile.path}');
      final fileSize = await notesFile.length();
      print('  File size: $fileSize bytes');
    } else {
      print('\n✗ Notes file not found');
    }

    print('\n=== Test completed successfully! ===');
    print('\nYou can now:');
    print('1. Open the jotdown app');
    print('2. Go to Settings');
    print('3. Select "Documents Folder" as storage location');
    print('4. Your notes will be stored in: $storagePath');

  } catch (e) {
    print('Error during test: $e');
    exit(1);
  }
}