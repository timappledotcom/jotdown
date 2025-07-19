import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/note.dart';
import '../models/app_settings.dart';
import '../services/notes_service.dart';
import '../services/settings_service.dart';
import '../services/password_manager.dart';
import 'note_editor_screen.dart';
import 'settings_screen.dart';

class NotesListScreen extends StatefulWidget {
  final Function(AppSettings)? onSettingsChanged;

  const NotesListScreen({super.key, this.onSettingsChanged});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  final NotesService _notesService = NotesService();
  final SettingsService _settingsService = SettingsService();
  List<Note> _notes = [];
  AppSettings _settings = AppSettings();
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSettingsAndNotes();
  }

  Future<void> _loadSettingsAndNotes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final settings = await _settingsService.loadSettings();

      String? password;
      if (settings.encryptionEnabled && settings.passwordHash != null) {
        if (!PasswordManager.isAuthenticated) {
          password = await PasswordManager.showPasswordInputDialog(
            context,
            passwordHash: settings.passwordHash!,
            salt: await _getSalt(settings),
          );

          if (password == null) {
            // User cancelled password input, exit the app or show error
            setState(() {
              _isLoading = false;
            });
            return;
          }
        } else {
          password = PasswordManager.currentPassword;
        }
      }

      final notes = await _notesService.loadNotes(settings, password);
      setState(() {
        _settings = settings;
        _notes = notes..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading notes: $e')));
    }
  }

  Future<void> _saveNote(Note note) async {
    final password = _settings.encryptionEnabled
        ? PasswordManager.currentPassword
        : null;
    await _notesService.saveNote(note, _notes, _settings, password);
    _loadSettingsAndNotes();
  }

  Future<void> _deleteNote(Note note) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      final password = _settings.encryptionEnabled
          ? PasswordManager.currentPassword
          : null;
      await _notesService.deleteNote(note.id, _notes, _settings, password);
      _loadSettingsAndNotes();
    }
  }

  void _openNoteEditor([Note? note]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(note: note, onSave: _saveNote),
      ),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          currentSettings: _settings,
          onSettingsChanged: (newSettings) {
            setState(() {
              _settings = newSettings;
            });
            _loadSettingsAndNotes();
            // Notify the main app of settings change
            if (widget.onSettingsChanged != null) {
              widget.onSettingsChanged!(newSettings);
            }
          },
        ),
      ),
    );
  }

  List<Note> get _filteredNotes {
    if (_searchQuery.isEmpty) {
      return _notes;
    }
    return _notes.where((note) {
      return note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          note.content.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<String> _getSalt(AppSettings settings) async {
    if (settings.storageLocation == 'shared_preferences') {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('encryption_salt') ?? '';
    } else {
      // For file storage, we need to get the directory path first
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
          final documentsDir = await getApplicationDocumentsDirectory();
          directoryPath = '${documentsDir.path}/jotDown';
          break;
      }

      final saltFile = File('$directoryPath/notes.json.salt');
      if (await saltFile.exists()) {
        return await saltFile.readAsString();
      }
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('jotDown'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: 'Settings',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildNotesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openNoteEditor(),
        tooltip: 'Add Note',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNotesList() {
    final filteredNotes = _filteredNotes;

    if (filteredNotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.note_add, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No notes yet.\nTap + to create your first note!'
                  : 'No notes found matching "$_searchQuery"',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: filteredNotes.length,
      itemBuilder: (context, index) {
        final note = filteredNotes[index];
        return _buildNoteCard(note);
      },
    );
  }

  Widget _buildNoteCard(Note note) {
    final previewText = note.content.length > 150
        ? '${note.content.substring(0, 150)}...'
        : note.content;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        title: Text(
          note.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (previewText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                previewText,
                style: const TextStyle(fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Updated: ${_formatDate(note.updatedAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        onTap: () => _openNoteEditor(note),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              _deleteNote(note);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete),
                title: Text('Delete'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
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
}
