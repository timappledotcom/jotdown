import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
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

class _NotesListScreenState extends State<NotesListScreen>
    with WidgetsBindingObserver {
  final NotesService _notesService = NotesService();
  final SettingsService _settingsService = SettingsService();
  List<Note> _notes = [];
  AppSettings _settings = AppSettings();
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedTag;
  Timer? _refreshTimer;
  DateTime? _lastModified;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettingsAndNotes();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh when app regains focus
    if (state == AppLifecycleState.resumed) {
      _refreshNotes();
    }
  }

  void _startAutoRefresh() {
    // Check for changes every 3 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkForChanges();
    });
  }

  Future<void> _checkForChanges() async {
    try {
      DateTime? currentModified;

      if (_settings.storageLocation == 'shared_preferences') {
        // Check SharedPreferences file modification time
        final homeDir = Platform.environment['HOME'] ?? '';
        final spFile = File(
            '$homeDir/.local/share/com.example.jotdown/shared_preferences.json');

        if (await spFile.exists()) {
          final stat = await spFile.stat();
          currentModified = stat.modified;
        }
      } else {
        // Check notes file modification time for other storage types
        final notesFile = await _getNotesFile();
        if (await notesFile.exists()) {
          final stat = await notesFile.stat();
          currentModified = stat.modified;
        }
      }

      // If file was modified since last check, refresh notes
      if (currentModified != null &&
          (_lastModified == null || currentModified.isAfter(_lastModified!))) {
        _lastModified = currentModified;
        if (mounted) {
          _refreshNotes();
        }
      } else if (_lastModified == null && currentModified != null) {
        _lastModified = currentModified;
      }
    } catch (e) {
      // Ignore errors in background checking
    }
  }

  Future<File> _getNotesFile() async {
    String filePath;
    switch (_settings.storageLocation) {
      case 'documents':
        final documentsDir = await getApplicationDocumentsDirectory();
        filePath = '${documentsDir.path}/jotDown/notes.json';
        break;
      case 'home':
        final homeDir = Platform.environment['HOME'] ?? '';
        filePath = '$homeDir/jotDown/notes.json';
        break;
      case 'custom':
        filePath = '${_settings.customPath}/notes.json';
        break;
      default:
        final documentsDir = await getApplicationDocumentsDirectory();
        filePath = '${documentsDir.path}/jotDown/notes.json';
        break;
    }
    return File(filePath);
  }

  Future<void> _refreshNotes() async {
    if (!mounted) return;

    try {
      final settings = await _settingsService.loadSettings();

      String? password;
      if (settings.encryptionEnabled && settings.passwordHash != null) {
        if (PasswordManager.isAuthenticated) {
          password = PasswordManager.currentPassword;
        } else {
          // Don't prompt for password during background refresh
          return;
        }
      }

      final notes = await _notesService.loadNotes(settings, password);

      if (mounted) {
        setState(() {
          _settings = settings;
          _notes = notes..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        });
      }
    } catch (e) {
      // Ignore errors during background refresh
    }
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

      // Update file modification time for tracking changes
      await _updateLastModified(settings);

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
    final password =
        _settings.encryptionEnabled ? PasswordManager.currentPassword : null;
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
      final password =
          _settings.encryptionEnabled ? PasswordManager.currentPassword : null;
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

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline),
            SizedBox(width: 8),
            Text('How to use jotDown'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Creating Notes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('• Tap the + button to create a new note'),
              const Text('• Use Markdown formatting for rich text'),
              const Text('• Notes are automatically saved'),
              const SizedBox(height: 16),
              const Text(
                'Using Tags:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('• Add tags anywhere in your note using #tagname'),
              const Text('• Example: "Meeting about #work and #planning"'),
              const Text('• Tags appear as badges on note cards'),
              const Text('• Use the dropdown above to filter by tag'),
              const SizedBox(height: 16),
              const Text(
                'Searching:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('• Use the search bar to find notes by content'),
              const Text('• Combine with tag filtering for precise results'),
              const Text('• Search works across both titles and content'),
              const SizedBox(height: 16),
              const Text(
                'Command Line:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('• Use "jd" command in terminal for CLI access'),
              const Text('• CLI and GUI share the same notes'),
              const Text('• Type "jd --help" for full CLI documentation'),
              const SizedBox(height: 16),
              const Text(
                'Settings:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('• Configure storage location and themes'),
              const Text('• Enable encryption for sensitive notes'),
              const Text('• Export and migrate your notes'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  List<Note> get _filteredNotes {
    var filteredNotes = _notes;

    // Filter by selected tag first
    if (_selectedTag != null && _selectedTag!.isNotEmpty) {
      filteredNotes =
          filteredNotes.where((note) => note.hasTag(_selectedTag!)).toList();
    }

    // Then filter by search query
    if (_searchQuery.isNotEmpty) {
      filteredNotes = filteredNotes.where((note) {
        return note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            note.content.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return filteredNotes;
  }

  List<String> get _availableTags {
    final Set<String> allTags = {};
    for (final note in _notes) {
      allTags.addAll(note.tags);
    }
    final tagList = allTags.toList()..sort();
    return tagList;
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
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: 'Help',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadSettingsAndNotes();
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: 'Settings',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Search bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search notes...',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                // Tag filter dropdown
                Row(
                  children: [
                    const Icon(Icons.label_outline, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _selectedTag,
                        decoration: InputDecoration(
                          hintText: 'Filter by tag...',
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All notes'),
                          ),
                          ..._availableTags
                              .map((tag) => DropdownMenuItem<String?>(
                                    value: tag,
                                    child: Text('#$tag'),
                                  )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedTag = value;
                          });
                        },
                      ),
                    ),
                    if (_selectedTag != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _selectedTag = null;
                          });
                        },
                        tooltip: 'Clear filter',
                      ),
                    ],
                  ],
                ),
              ],
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
            if (note.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: note.tags.map((tag) {
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  final backgroundColor = isDark
                      ? Theme.of(context).colorScheme.surfaceVariant
                      : Theme.of(context).primaryColor.withOpacity(0.1);
                  final borderColor = isDark
                      ? Theme.of(context).colorScheme.outline
                      : Theme.of(context).primaryColor.withOpacity(0.3);
                  final textColor = isDark
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Theme.of(context).primaryColor;

                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: borderColor,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '#$tag',
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
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

  Future<void> _updateLastModified(AppSettings settings) async {
    try {
      if (settings.storageLocation == 'shared_preferences') {
        final homeDir = Platform.environment['HOME'] ?? '';
        final spFile = File(
            '$homeDir/.local/share/com.example.jotdown/shared_preferences.json');
        if (spFile.existsSync()) {
          final stat = spFile.statSync();
          _lastModified = stat.modified;
        }
      } else {
        // For file storage
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

        final notesFile = File('$directoryPath/notes.json');
        if (notesFile.existsSync()) {
          final stat = notesFile.statSync();
          _lastModified = stat.modified;
        }
      }
    } catch (e) {
      // Ignore errors in file stat checking
      print('Error updating last modified time: $e');
    }
  }
}
