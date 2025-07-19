#!/usr/bin/env dart

import 'dart:io';
import 'package:args/args.dart';
import 'package:jotdown/models/note.dart';
import 'package:jotdown/models/app_settings.dart';
import 'package:jotdown/services/cli_notes_service.dart';
import 'package:jotdown/services/encryption_service.dart';

/// Global password storage for the session
String? _currentPassword;

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addCommand('list')
    ..addCommand('add')
    ..addCommand('edit')
    ..addCommand('delete')
    ..addCommand('view')
    ..addCommand('search')
    ..addCommand('settings')
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Show this help message',
      negatable: false,
    )
    ..addFlag(
      'version',
      abbr: 'v',
      help: 'Show version information',
      negatable: false,
    );

  // Add subcommands
  parser.commands['add']!
    ..addOption('title', abbr: 't', help: 'Note title', mandatory: true)
    ..addOption(
      'content',
      abbr: 'c',
      help: 'Note content (use - to read from stdin)',
    )
    ..addFlag(
      'editor',
      abbr: 'e',
      help: 'Open editor for content',
      negatable: false,
    );

  parser.commands['edit']!
    ..addOption('id', help: 'Note ID to edit', mandatory: true)
    ..addOption('title', abbr: 't', help: 'New title')
    ..addOption(
      'content',
      abbr: 'c',
      help: 'New content (use - to read from stdin)',
    )
    ..addFlag(
      'editor',
      abbr: 'e',
      help: 'Open editor for content',
      negatable: false,
    );

  parser.commands['delete']!
    ..addOption('id', help: 'Note ID to delete', mandatory: true)
    ..addFlag(
      'force',
      abbr: 'f',
      help: 'Force delete without confirmation',
      negatable: false,
    );

  parser.commands['view']!
    ..addOption('id', help: 'Note ID to view', mandatory: true)
    ..addFlag('raw', abbr: 'r', help: 'Show raw markdown', negatable: false);

  parser.commands['search']!.addOption(
    'query',
    abbr: 'q',
    help: 'Search query',
    mandatory: true,
  );

  parser.commands['settings']!
    ..addOption(
      'storage',
      abbr: 's',
      help:
          'Set storage location (shared_preferences, documents, home, custom)',
    )
    ..addOption('custom-path', help: 'Set custom storage path')
    ..addOption('theme', help: 'Set theme (system, light, dark)')
    ..addFlag(
      'encrypt',
      help: 'Enable encryption (will prompt for password)',
      negatable: false,
    )
    ..addFlag(
      'decrypt',
      help: 'Disable encryption (will prompt for password)',
      negatable: false,
    )
    ..addFlag(
      'change-password',
      help: 'Change encryption password',
      negatable: false,
    )
    ..addFlag('show', help: 'Show current settings', negatable: false);

  parser.addCommand('export')
    ..addOption('output', abbr: 'o', help: 'Output file path for export')
    ..addFlag(
      'metadata',
      abbr: 'm',
      help: 'Include metadata files',
      defaultsTo: true,
      negatable: true,
    );

  parser.addCommand('import')
    ..addOption(
      'file',
      abbr: 'f',
      help: 'Backup file to import',
      mandatory: true,
    )
    ..addFlag(
      'merge',
      help: 'Merge with existing notes (default: replace)',
      defaultsTo: true,
      negatable: false,
    );

  parser
      .addCommand('backup')
      .addOption('output', abbr: 'o', help: 'Output directory for backup');

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool) {
      print('jotDown CLI - Command line interface for jotDown');
      print('');
      print(parser.usage);
      return;
    }

    if (results['version'] as bool) {
      print('jotDown CLI v1.0.0');
      return;
    }

    final cli = JotDownCLI();
    await cli.handleCommand(results);
  } catch (e) {
    print('Error: $e');
    print('Use --help for usage information');
    exit(1);
  }
}

void _showHelp(ArgParser parser) {
  print('jotDown CLI - Command line interface for jotDown');
  print('');
  print('Usage: dart bin/jotdown.dart <command> [arguments]');
  print('');
  print('Commands:');
  print('  list           List all notes');
  print('  add            Add a new note');
  print('  edit           Edit an existing note');
  print('  delete         Delete a note');
  print('  view           View a note');
  print('  search         Search notes');
  print('  settings       Manage settings');
  print('');
  print('Global options:');
  print(parser.usage);
}

void _showVersion() {
  print('jotDown CLI v1.0.0');
}

class JotDownCLI {
  final CLINotesService _notesService = CLINotesService();

  Future<void> handleCommand(ArgResults results) async {
    final command = results.command;
    if (command == null) return;

    switch (command.name) {
      case 'list':
        await _listNotes(command);
        break;
      case 'add':
        await _addNote(command);
        break;
      case 'edit':
        await _editNote(command);
        break;
      case 'delete':
        await _deleteNote(command);
        break;
      case 'view':
        await _viewNote(command);
        break;
      case 'search':
        await _searchNotes(command);
        break;
      case 'settings':
        await _manageSettings(command);
        break;
    }
  }

  Future<void> _listNotes(ArgResults command) async {
    final settings = await _notesService.loadSettings();
    final password = await _getPassword(settings);

    if (settings.encryptionEnabled && password == null) {
      exit(1);
    }

    final notes = await _notesService.loadNotes(settings, password);

    if (notes.isEmpty) {
      print('No notes found.');
      return;
    }

    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    print('Notes (${notes.length}):');
    print('');

    for (final note in notes) {
      final preview = note.content.length > 60
          ? '${note.content.substring(0, 60)}...'
          : note.content;

      print('ID: ${note.id}');
      print('Title: ${note.title}');
      print('Preview: ${preview.replaceAll('\n', ' ')}');
      print('Updated: ${_formatDate(note.updatedAt)}');
      print('=' * 50);
    }
  }

  Future<void> _addNote(ArgResults command) async {
    final title = command['title'] as String;
    String content = '';

    if (command['editor'] as bool) {
      content = await _openEditor();
    } else if (command['content'] != null) {
      final contentArg = command['content'] as String;
      if (contentArg == '-') {
        content = _readFromStdin();
      } else {
        content = contentArg;
      }
    }

    final now = DateTime.now();
    final note = Note(
      id: now.millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
    );

    final settings = await _notesService.loadSettings();
    final password = await _getPassword(settings);

    if (settings.encryptionEnabled && password == null) {
      exit(1);
    }

    await _notesService.saveNote(note, settings, password);
    print('Note added successfully!');
    print('ID: ${note.id}');
  }

  Future<void> _editNote(ArgResults command) async {
    final noteId = command['id'] as String;
    final notes = await _notesService.loadNotes();
    final noteIndex = notes.indexWhere((n) => n.id == noteId);

    if (noteIndex == -1) {
      throw 'Note not found';
    }

    final note = notes[noteIndex];

    String newTitle = (command['title'] as String?) ?? note.title;
    String newContent = note.content;

    if (command['editor'] as bool) {
      newContent = await _openEditor(note.content);
    } else if (command['content'] != null) {
      final contentArg = command['content'] as String;
      if (contentArg == '-') {
        newContent = _readFromStdin();
      } else {
        newContent = contentArg;
      }
    }

    final updatedNote = note.copyWith(
      title: newTitle,
      content: newContent,
      updatedAt: DateTime.now(),
    );

    await _notesService.saveNote(updatedNote);
    print('Note updated successfully!');
  }

  Future<void> _deleteNote(ArgResults command) async {
    final noteId = command['id'] as String;
    final force = command['force'] as bool;

    if (!force) {
      stdout.write('Are you sure you want to delete this note? (y/N): ');
      final confirmation = stdin.readLineSync()?.toLowerCase();
      if (confirmation != 'y' && confirmation != 'yes') {
        print('Deletion cancelled.');
        return;
      }
    }

    await _notesService.deleteNote(noteId);
    print('Note deleted successfully!');
  }

  Future<void> _viewNote(ArgResults command) async {
    final noteId = command['id'] as String;
    final raw = command['raw'] as bool;
    final notes = await _notesService.loadNotes();
    final noteIndex = notes.indexWhere((n) => n.id == noteId);

    if (noteIndex == -1) {
      throw 'Note not found';
    }

    final note = notes[noteIndex];

    print('Title: ${note.title}');
    print('ID: ${note.id}');
    print('Created: ${_formatDate(note.createdAt)}');
    print('Updated: ${_formatDate(note.updatedAt)}');
    print('=' * 50);

    if (raw) {
      print(note.content);
    } else {
      // Simple markdown-to-console conversion
      print(_renderMarkdown(note.content));
    }
  }

  Future<void> _searchNotes(ArgResults command) async {
    final query = command['query'] as String;
    final notes = await _notesService.loadNotes();

    final matches = notes
        .where(
          (note) =>
              note.title.toLowerCase().contains(query.toLowerCase()) ||
              note.content.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();

    if (matches.isEmpty) {
      print('No notes found matching "$query".');
      return;
    }

    print('Found ${matches.length} note(s) matching "$query":');
    print('');

    for (final note in matches) {
      final preview = note.content.length > 60
          ? '${note.content.substring(0, 60)}...'
          : note.content;

      print('ID: ${note.id}');
      print('Title: ${note.title}');
      print('Preview: ${preview.replaceAll('\n', ' ')}');
      print('=' * 30);
    }
  }

  Future<void> _manageSettings(ArgResults command) async {
    final settings = await _notesService.loadSettings();

    if (command['show'] as bool) {
      print('Current Settings:');
      print('Storage Location: ${settings.storageLocation}');
      print('Custom Path: ${settings.customPath}');
      print('Theme: ${settings.themeMode}');
      print('Storage Path: ${_notesService.getStorageLocationPath(settings)}');
      return;
    }

    var newSettings = settings;
    bool changed = false;

    if (command['storage'] != null) {
      newSettings = newSettings.copyWith(storageLocation: command['storage']);
      changed = true;
    }

    if (command['custom-path'] != null) {
      newSettings = newSettings.copyWith(customPath: command['custom-path']);
      changed = true;
    }

    if (command['theme'] != null) {
      newSettings = newSettings.copyWith(themeMode: command['theme']);
      changed = true;
    }

    if (changed) {
      await _notesService.saveSettings(newSettings);
      print('Settings updated successfully!');
    } else {
      print(
        'No settings changes specified. Use --show to view current settings.',
      );
    }
  }

  Future<String> _openEditor([String? initialContent]) async {
    final editor = Platform.environment['EDITOR'] ?? 'nano';
    final tempFile = File(
      '/tmp/jotdown_${DateTime.now().millisecondsSinceEpoch}.md',
    );

    if (initialContent != null) {
      await tempFile.writeAsString(initialContent);
    }

    final result = await Process.run(editor, [tempFile.path]);

    if (result.exitCode != 0) {
      throw 'Editor exited with code ${result.exitCode}';
    }

    final content = await tempFile.readAsString();
    await tempFile.delete();

    return content;
  }

  String _readFromStdin() {
    final lines = <String>[];
    String? line;
    while ((line = stdin.readLineSync()) != null) {
      lines.add(line!);
    }
    return lines.join('\n');
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _renderMarkdown(String content) {
    // First, handle escaped newlines
    content = content.replaceAll('\\n', '\n');

    // Simple markdown rendering for console
    return content
        .replaceAllMapped(
          RegExp(r'^# (.+)$', multiLine: true),
          (match) => '\x1b[1m\x1b[4m${match.group(1)}\x1b[0m',
        )
        .replaceAllMapped(
          RegExp(r'^## (.+)$', multiLine: true),
          (match) => '\x1b[1m${match.group(1)}\x1b[0m',
        )
        .replaceAllMapped(
          RegExp(r'\*\*(.+?)\*\*'),
          (match) => '\x1b[1m${match.group(1)}\x1b[0m',
        )
        .replaceAllMapped(
          RegExp(r'\*(.+?)\*'),
          (match) => '\x1b[3m${match.group(1)}\x1b[0m',
        )
        .replaceAllMapped(
          RegExp(r'`(.+?)`'),
          (match) => '\x1b[7m${match.group(1)}\x1b[0m',
        );
  }

  /// Prompt user for password input (hidden)
  String? _promptPassword(String prompt) {
    stdout.write('$prompt: ');
    stdin.echoMode = false;
    stdin.lineMode = false;

    List<int> password = [];
    int char;

    while ((char = stdin.readByteSync()) != 10 && char != 13) {
      // Enter key
      if (char == 8 || char == 127) {
        // Backspace
        if (password.isNotEmpty) {
          password.removeLast();
          stdout.write('\b \b');
        }
      } else if (char >= 32 && char <= 126) {
        // Printable characters
        password.add(char);
        stdout.write('*');
      }
    }

    stdin.echoMode = true;
    stdin.lineMode = true;
    stdout.writeln();

    return password.isEmpty ? null : String.fromCharCodes(password);
  }

  /// Get password for encrypted operations
  Future<String?> _getPassword(AppSettings settings) async {
    if (_currentPassword != null) {
      return _currentPassword;
    }

    if (!settings.encryptionEnabled || settings.passwordHash == null) {
      return null;
    }

    final password = _promptPassword('Enter password');
    if (password == null) {
      print('Password is required for encrypted notes.');
      return null;
    }

    // Get salt
    String salt = '';
    try {
      final service = CLINotesService();
      final notesFile = await service.getNotesFile(settings);
      final saltFile = File('${notesFile.path}.salt');
      if (await saltFile.exists()) {
        salt = await saltFile.readAsString();
      }
    } catch (e) {
      print('Error reading encryption data: $e');
      return null;
    }

    // Verify password
    if (!EncryptionService.verifyPassword(
      password,
      settings.passwordHash!,
      salt,
    )) {
      print('Incorrect password.');
      return null;
    }

    _currentPassword = password;
    return password;
  }
}
