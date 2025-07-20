import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import '../models/note.dart';
import '../models/app_settings.dart';
import '../services/notes_service.dart';

class BackupService {
  static const String _backupFolderName = 'jotDown_Backups';

  /// Export notes to a zip file containing individual markdown files
  Future<String> exportNotesToZip({
    required List<Note> notes,
    String? customPath,
    bool includeMetadata = true,
  }) async {
    try {
      // Create archive
      final archive = Archive();

      // Add each note as a markdown file
      for (final note in notes) {
        final fileName = _sanitizeFileName('${note.title}.md');
        final markdownContent = _createMarkdownContent(note, includeMetadata);

        final file = ArchiveFile(
          fileName,
          markdownContent.length,
          markdownContent.codeUnits,
        );
        archive.addFile(file);
      }

      // Add metadata file if requested
      if (includeMetadata) {
        final metadataContent = _createMetadataJson(notes);
        final metadataFile = ArchiveFile(
          'metadata.json',
          metadataContent.length,
          metadataContent.codeUnits,
        );
        archive.addFile(metadataFile);

        // Add readme file
        final readmeContent = _createReadmeContent();
        final readmeFile = ArchiveFile(
          'README.md',
          readmeContent.length,
          readmeContent.codeUnits,
        );
        archive.addFile(readmeFile);
      }

      // Encode archive to zip
      final zipData = ZipEncoder().encode(archive);

      // Determine output path
      final outputPath = await _getBackupFilePath(customPath);

      // Write zip file
      final outputFile = File(outputPath);
      await outputFile.parent.create(recursive: true);
      await outputFile.writeAsBytes(zipData);

      return outputPath;
    } catch (e) {
      throw Exception('Failed to export notes: $e');
    }
  }

  /// Import notes from a zip file
  Future<List<Note>> importNotesFromZip(String zipPath) async {
    try {
      final file = File(zipPath);
      if (!await file.exists()) {
        throw Exception('Backup file not found: $zipPath');
      }

      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final notes = <Note>[];
      Map<String, dynamic>? metadata;

      // First, try to load metadata if available
      for (final file in archive) {
        if (file.name == 'metadata.json' && !file.isFile) {
          continue;
        }
        if (file.name == 'metadata.json') {
          final content = utf8.decode(file.content as List<int>);
          metadata = json.decode(content);
          break;
        }
      }

      // Process each file
      for (final file in archive) {
        if (file.isFile &&
            file.name.endsWith('.md') &&
            file.name != 'README.md') {
          final content = utf8.decode(file.content as List<int>);
          final note = _parseMarkdownFile(file.name, content, metadata);
          if (note != null) {
            notes.add(note);
          }
        }
      }

      return notes;
    } catch (e) {
      throw Exception('Failed to import notes: $e');
    }
  }

  /// Create a full backup of notes and settings
  Future<String> createFullBackup(
    AppSettings settings, [
    String? password,
  ]) async {
    try {
      final notesService = NotesService();
      final notes = await notesService.loadNotes(settings, password);

      // Create archive
      final archive = Archive();

      // Add notes as markdown files
      for (final note in notes) {
        final fileName = _sanitizeFileName('${note.title}.md');
        final markdownContent = _createMarkdownContent(note, true);
        final file = ArchiveFile(
          fileName,
          markdownContent.length,
          markdownContent.codeUnits,
        );
        archive.addFile(file);
      }

      // Add metadata
      final metadataContent = _createMetadataJson(notes);
      final metadataFile = ArchiveFile(
        'metadata.json',
        metadataContent.length,
        metadataContent.codeUnits,
      );
      archive.addFile(metadataFile);

      // Add settings (without password hash for security)
      final settingsContent = _createSettingsBackup(settings);
      final settingsFile = ArchiveFile(
        'settings.json',
        settingsContent.length,
        settingsContent.codeUnits,
      );
      archive.addFile(settingsFile);

      // Add readme
      final readmeContent = _createReadmeContent();
      final readmeFile = ArchiveFile(
        'README.md',
        readmeContent.length,
        readmeContent.codeUnits,
      );
      archive.addFile(readmeFile);

      // Encode and save
      final zipData = ZipEncoder().encode(archive);

      final outputPath = await _getBackupFilePath(null, 'full_backup');
      final outputFile = File(outputPath);
      await outputFile.parent.create(recursive: true);
      await outputFile.writeAsBytes(zipData);

      return outputPath;
    } catch (e) {
      throw Exception('Failed to create backup: $e');
    }
  }

  /// Get list of available backup files
  Future<List<FileSystemEntity>> listBackups() async {
    try {
      final backupDir = await _getBackupDirectory();
      if (!await backupDir.exists()) {
        return [];
      }

      return await backupDir
          .list()
          .where((entity) => entity.path.endsWith('.zip'))
          .toList();
    } catch (e) {
      return [];
    }
  }

  String _sanitizeFileName(String fileName) {
    // Remove or replace invalid filename characters
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
  }

  String _createMarkdownContent(Note note, bool includeMetadata) {
    final buffer = StringBuffer();

    if (includeMetadata) {
      buffer.writeln('---');
      buffer.writeln('id: ${note.id}');
      buffer.writeln('created: ${note.createdAt.toIso8601String()}');
      buffer.writeln('updated: ${note.updatedAt.toIso8601String()}');
      buffer.writeln('---');
      buffer.writeln();
    }

    buffer.writeln('# ${note.title}');
    buffer.writeln();
    buffer.writeln(note.content);

    return buffer.toString();
  }

  String _createMetadataJson(List<Note> notes) {
    final metadata = {
      'export_date': DateTime.now().toIso8601String(),
      'export_version': '1.0',
      'total_notes': notes.length,
      'notes': notes
          .map(
            (note) => {
              'id': note.id,
              'title': note.title,
              'created_at': note.createdAt.toIso8601String(),
              'updated_at': note.updatedAt.toIso8601String(),
              'filename': _sanitizeFileName('${note.title}.md'),
            },
          )
          .toList(),
    };

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(metadata);
  }

  String _createSettingsBackup(AppSettings settings) {
    final settingsMap = settings.toJson();
    // Remove sensitive data
    settingsMap.remove('passwordHash');

    final backupSettings = {
      'export_date': DateTime.now().toIso8601String(),
      'settings': settingsMap,
    };

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(backupSettings);
  }

  String _createReadmeContent() {
    return '''# jotDown Backup

This backup was created by jotDown on ${DateTime.now().toIso8601String()}.

## Contents

- **Individual Notes**: Each note is saved as a separate markdown file
- **metadata.json**: Contains note metadata and export information
- **settings.json**: Contains application settings (excluding passwords)
- **README.md**: This file

## Restoring Notes

You can:
1. Import this backup using jotDown's import feature
2. Manually copy the markdown files to use with other applications
3. Use the metadata.json file to reconstruct the note database

## File Format

Each note file contains:
- YAML frontmatter with metadata (id, created, updated dates)
- The note title as a level 1 heading
- The note content in markdown format

Generated by jotDown v0.1.3
''';
  }

  Note? _parseMarkdownFile(
    String fileName,
    String content,
    Map<String, dynamic>? metadata,
  ) {
    try {
      // Extract title from filename (remove .md extension)
      String title = fileName.substring(0, fileName.length - 3);

      // Parse frontmatter if present
      String? id;
      DateTime? createdAt;
      DateTime? updatedAt;
      String markdownContent = content;

      if (content.startsWith('---')) {
        final parts = content.split('---');
        if (parts.length >= 3) {
          final frontmatter = parts[1].trim();
          markdownContent = parts.skip(2).join('---').trim();

          // Parse YAML-like frontmatter
          for (final line in frontmatter.split('\n')) {
            final colonIndex = line.indexOf(':');
            if (colonIndex > 0) {
              final key = line.substring(0, colonIndex).trim();
              final value = line.substring(colonIndex + 1).trim();

              switch (key) {
                case 'id':
                  id = value;
                  break;
                case 'created':
                  createdAt = DateTime.tryParse(value);
                  break;
                case 'updated':
                  updatedAt = DateTime.tryParse(value);
                  break;
              }
            }
          }
        }
      }

      // Remove title heading if it matches filename
      if (markdownContent.startsWith('# ')) {
        final lines = markdownContent.split('\n');
        final firstLine = lines[0].substring(2).trim();
        if (firstLine == title) {
          markdownContent = lines.skip(1).join('\n').trim();
        }
      }

      // Generate missing data
      final now = DateTime.now();
      id ??= now.millisecondsSinceEpoch.toString();
      createdAt ??= now;
      updatedAt ??= now;

      return Note(
        id: id,
        title: title,
        content: markdownContent,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    } catch (e) {
      print('Failed to parse markdown file $fileName: $e');
      return null;
    }
  }

  Future<String> _getBackupFilePath(
    String? customPath, [
    String prefix = 'notes_export',
  ]) async {
    final timestamp =
        DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
    final fileName = '${prefix}_$timestamp.zip';

    if (customPath != null) {
      return '$customPath/$fileName';
    }

    final backupDir = await _getBackupDirectory();
    return '${backupDir.path}/$fileName';
  }

  Future<Directory> _getBackupDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    return Directory('${documentsDir.path}/$_backupFolderName');
  }
}
