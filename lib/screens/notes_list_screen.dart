import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yaru/yaru.dart';
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
  final List<String> _selectedTags = []; // Changed to support hierarchical tag selection
  bool _showSidebar = true; // Show sidebar by default
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
    // Refresh when app regains focus or becomes active
    if (state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive) {
      print('App lifecycle changed to $state, refreshing notes...');
      _forceRefresh();
    }
  }

  void _startAutoRefresh() {
    // Check for changes every 1 second for better responsiveness
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
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

      // Also check if the number of notes changed as a fallback
      final currentSettings = await _settingsService.loadSettings();
      String? password;
      if (currentSettings.encryptionEnabled &&
          currentSettings.passwordHash != null) {
        if (PasswordManager.isAuthenticated) {
          password = PasswordManager.currentPassword;
        }
      }

      final currentNotes =
          await _notesService.loadNotes(currentSettings, password);
      final notesCountChanged = currentNotes.length != _notes.length;

      // If file was modified since last check or note count changed, refresh notes
      if ((currentModified != null &&
              (_lastModified == null ||
                  currentModified.isAfter(_lastModified!))) ||
          notesCountChanged) {
        print(
            'Change detected: file modified or note count changed (${_notes.length} -> ${currentNotes.length})');
        _lastModified = currentModified;
        if (mounted) {
          await _refreshNotes();
        }
      } else if (_lastModified == null && currentModified != null) {
        _lastModified = currentModified;
      }
    } catch (e) {
      print('Error checking for changes: $e');
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

  Future<void> _forceRefresh() async {
    if (!mounted) return;

    try {
      final settings = await _settingsService.loadSettings();

      String? password;
      if (settings.encryptionEnabled && settings.passwordHash != null) {
        if (PasswordManager.isAuthenticated) {
          password = PasswordManager.currentPassword;
        } else {
          // For manual refresh, we still need to authenticate
          password = await PasswordManager.showPasswordInputDialog(
            context,
            passwordHash: settings.passwordHash!,
            salt: await _getSalt(settings),
          );

          if (password == null) {
            return; // User cancelled
          }
        }
      }

      final notes = await _notesService.loadNotes(settings, password);

      // Force update the last modified time
      await _updateLastModified(settings);

      if (mounted) {
        setState(() {
          _settings = settings;
          _notes = notes..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        });

        // Show feedback that refresh completed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notes refreshed'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing notes: $e')),
        );
      }
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
        title: Row(
          children: [
            Icon(Icons.help_outline, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            const Text('How to use jotDown'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHelpSection(
                  '📝 Creating Notes',
                  [
                    'Tap the + button to create a new note',
                    'Use Markdown formatting for rich text',
                    'Notes are automatically saved as you type',
                    'Tap any note to open and edit it',
                  ],
                ),
                _buildHelpSection(
                  '🏷️ Using Tags',
                  [
                    'Add tags anywhere in your note using #tagname',
                    'Example: "Meeting about #work and #planning"',
                    'Tags appear as colored badges on note cards',
                    'Click the tag icon in the toolbar to open the tags sidebar',
                    'Select multiple tags to refine your search hierarchically',
                    'Use "Back" to remove the last tag or "Clear All" to reset',
                    'No spaces allowed in tag names',
                  ],
                ),
                _buildHelpSection(
                  '🔍 Searching & Filtering',
                  [
                    'Use the search bar to find notes by content',
                    'Search works across both titles and note content',
                    'Open the tags sidebar for hierarchical tag filtering',
                    'Select multiple tags to narrow down results progressively',
                    'Combine text search with tag filtering for precise results',
                    'Tag counts show how many notes match each filter',
                  ],
                ),
                _buildHelpSection(
                  '⌨️ Command Line Interface',
                  [
                    'Use "jd" command in terminal for CLI access',
                    'CLI and GUI share the same notes seamlessly',
                    'Type "jd --help" for full CLI documentation',
                    'Perfect for automation and quick note-taking',
                  ],
                ),
                _buildHelpSection(
                  '⚙️ Settings & Features',
                  [
                    'Click the gear icon to access settings',
                    'Choose your preferred storage location',
                    'Enable encryption for sensitive notes',
                    'Switch between light, dark, and system themes',
                    'Export and migrate your notes easily',
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Pro tip: Tags are case-insensitive and automatically extracted from your note content!',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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

  Widget _buildHelpSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 12),
      ],
    );
  }

  List<Note> get _filteredNotes {
    var filteredNotes = _notes;

    // Filter by selected tags (all selected tags must be present)
    if (_selectedTags.isNotEmpty) {
      filteredNotes = filteredNotes.where((note) {
        return _selectedTags.every((tag) => note.hasTag(tag));
      }).toList();
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

  /// Get tags that appear in the currently filtered notes (for refinement)
  List<String> get _refinementTags {
    if (_selectedTags.isEmpty) return _availableTags;
    
    final Set<String> refinementTags = {};
    for (final note in _filteredNotes) {
      refinementTags.addAll(note.tags);
    }
    
    // Remove already selected tags
    refinementTags.removeWhere((tag) => _selectedTags.contains(tag));
    
    final tagList = refinementTags.toList()..sort();
    return tagList;
  }

  /// Get tag counts for display
  Map<String, int> get _tagCounts {
    final Map<String, int> counts = {};
    final tagsToCount = _selectedTags.isEmpty ? _availableTags : _refinementTags;
    
    for (final tag in tagsToCount) {
      counts[tag] = _notes.where((note) {
        // For refinement tags, count notes that have all selected tags plus this tag
        if (_selectedTags.isNotEmpty) {
          return _selectedTags.every((selectedTag) => note.hasTag(selectedTag)) && 
                 note.hasTag(tag);
        }
        // For initial tags, just count notes with this tag
        return note.hasTag(tag);
      }).length;
    }
    
    return counts;
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
        title: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.edit_note,
                size: 16,
                color: Color(0xFFE95420),
              ),
            ),
            const Text('jotDown'),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: _showSidebar 
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(
                _showSidebar ? Icons.label : Icons.label_outline,
                color: _showSidebar 
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : null,
              ),
              onPressed: () {
                setState(() {
                  _showSidebar = !_showSidebar;
                });
              },
              tooltip: _showSidebar ? 'Hide Tags Sidebar' : 'Show Tags Sidebar',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: 'Help',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _forceRefresh();
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
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Search bar with Ubuntu styling
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search notes...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Tags Sidebar
                if (_showSidebar) _buildTagsSidebar(),
                // Main content
                Expanded(child: _buildNotesList()),
              ],
            ),
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
            Icon(
              Icons.note_add,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyStateMessage(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            if (_selectedTags.isNotEmpty || _searchQuery.isNotEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedTags.clear();
                    _searchQuery = '';
                  });
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Filters'),
              ),
            ],
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
      elevation: 1, // Ubuntu prefers subtle elevation
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // Ubuntu's preferred radius
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.edit_note,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 20,
          ),
        ),
        title: Text(
          note.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500), // Ubuntu uses medium weight
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
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
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
          icon: const Icon(Icons.more_vert),
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

  Widget _buildTagsSidebar() {
    final tagCounts = _tagCounts;
    final tagsToShow = _selectedTags.isEmpty ? _availableTags : _refinementTags;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.label,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tags',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),

          // Selected tags breadcrumb
          if (_selectedTags.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: _selectedTags.asMap().entries.map((entry) {
                      final index = entry.key;
                      final tag = entry.value;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '#$tag',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedTags.removeRange(index, _selectedTags.length);
                                });
                              },
                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (_selectedTags.length > 1)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedTags.removeLast();
                            });
                          },
                          icon: const Icon(Icons.arrow_back, size: 16),
                          label: const Text('Back'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 32),
                          ),
                        ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedTags.clear();
                          });
                        },
                        icon: const Icon(Icons.clear_all, size: 16),
                        label: const Text('Clear All'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 32),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ],

          // Available tags list
          Expanded(
            child: tagsToShow.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _selectedTags.isEmpty
                            ? 'No tags found in your notes.\nAdd tags to your notes using #tagname'
                            : 'No additional tags available\nfor further refinement.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: tagsToShow.length,
                    itemBuilder: (context, index) {
                      final tag = tagsToShow[index];
                      final count = tagCounts[tag] ?? 0;
                      
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.label,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          '#$tag',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            count.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedTags.add(tag);
                          });
                        },
                      );
                    },
                  ),
          ),

          // Footer with stats
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredNotes.length} notes',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${tagsToShow.length} tags',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getEmptyStateMessage() {
    if (_notes.isEmpty) {
      return 'No notes yet.\nTap + to create your first note!';
    }
    
    if (_selectedTags.isNotEmpty && _searchQuery.isNotEmpty) {
      return 'No notes found with tags ${_selectedTags.map((t) => '#$t').join(', ')}\nand matching "$_searchQuery"';
    }
    
    if (_selectedTags.isNotEmpty) {
      return 'No notes found with tags:\n${_selectedTags.map((t) => '#$t').join(', ')}';
    }
    
    if (_searchQuery.isNotEmpty) {
      return 'No notes found matching "$_searchQuery"';
    }
    
    return 'No notes to display';
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
