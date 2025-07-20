import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../models/app_settings.dart';
import '../models/note.dart';
import '../services/settings_service.dart';
import '../services/notes_service.dart';
import '../services/password_manager.dart';
import '../services/backup_service.dart';

class SettingsScreen extends StatefulWidget {
  final AppSettings currentSettings;
  final Function(AppSettings) onSettingsChanged;

  const SettingsScreen({
    super.key,
    required this.currentSettings,
    required this.onSettingsChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final NotesService _notesService = NotesService();

  late AppSettings _settings;
  late TextEditingController _customPathController;
  List<String> _availableLocations = [];
  bool _isLoading = true;
  bool _isMigrating = false;

  @override
  void initState() {
    super.initState();
    _settings = widget.currentSettings;
    _customPathController = TextEditingController(text: _settings.customPath);
    _loadAvailableLocations();
  }

  @override
  void dispose() {
    _customPathController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableLocations() async {
    final locations = await _settingsService.getAvailableStorageLocations();
    setState(() {
      _availableLocations = locations;
      _isLoading = false;
    });
  }

  Future<void> _selectCustomDirectory() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      setState(() {
        _customPathController.text = selectedDirectory ?? '';
        _settings = _settings.copyWith(customPath: selectedDirectory);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error selecting directory: $e')));
    }
  }

  Future<void> _testStorageLocation(AppSettings testSettings) async {
    try {
      // Try to create a test file in the location
      final testNotes = <Note>[];
      await _notesService.saveNotes(testNotes, testSettings);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Storage location is accessible!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accessing storage location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isMigrating = true;
    });

    try {
      final oldSettings = widget.currentSettings;
      final newSettings = _settings;

      // If storage location changed, offer to migrate
      if (oldSettings.storageLocation != newSettings.storageLocation ||
          (newSettings.storageLocation == 'custom' &&
              oldSettings.customPath != newSettings.customPath)) {
        final shouldMigrate = await _showMigrationDialog();

        if (shouldMigrate == true) {
          final success = await _notesService.migrateNotes(
            oldSettings,
            newSettings,
          );

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notes migrated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Migration failed. Settings saved but notes remain in old location.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      await _settingsService.saveSettings(newSettings);
      widget.onSettingsChanged(newSettings);

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving settings: $e')));
    } finally {
      setState(() {
        _isMigrating = false;
      });
    }
  }

  Future<bool?> _showMigrationDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Migrate Notes'),
        content: const Text(
          'You\'ve changed the storage location. Would you like to migrate your existing notes to the new location?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, keep in old location'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, migrate notes'),
          ),
        ],
      ),
    );
  }

  Future<String> _getLocationPath(String location) async {
    switch (location) {
      case 'shared_preferences':
        return 'Stored in app data (no file path)';
      case 'documents':
        try {
          final documentsDir = await getApplicationDocumentsDirectory();
          return '${documentsDir.path}/jotDown/';
        } catch (e) {
          return 'Documents/jotDown/';
        }
      case 'home':
        final homeDir = Platform.environment['HOME'] ?? '';
        return '$homeDir/jotDown/';
      case 'custom':
        return _settings.customPath.isNotEmpty
            ? '${_settings.customPath}/notes.json'
            : 'No path selected';
      default:
        return 'Unknown location';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton(
            onPressed: _isMigrating ? null : _saveSettings,
            child: _isMigrating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Storage Location',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Storage location options
            ..._availableLocations.map(
              (location) => _buildStorageOption(location),
            ),

            const SizedBox(height: 24),

            // Theme selection
            const Text(
              'Theme',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildThemeOption(
              'system',
              'System Default',
              'Follows your device\'s theme setting',
            ),
            _buildThemeOption('light', 'Light Mode', 'Always use light theme'),
            _buildThemeOption('dark', 'Dark Mode', 'Always use dark theme'),

            const SizedBox(height: 24),

            // Encryption section
            const Text(
              'Security',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Enable Encryption'),
                    subtitle: const Text('Encrypt your notes with a password'),
                    value: _settings.encryptionEnabled,
                    onChanged: (value) async {
                      if (value) {
                        await _enableEncryption();
                      } else {
                        await _disableEncryption();
                      }
                    },
                  ),
                  if (_settings.encryptionEnabled) ...[
                    const Divider(),
                    ListTile(
                      title: const Text('Change Password'),
                      subtitle: const Text('Update your encryption password'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _changePassword,
                    ),
                  ],
                ],
              ),
            ),

            if (_settings.storageLocation == 'custom') ...[
              const SizedBox(height: 16),
              const Text('Custom Directory Path:'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customPathController,
                      decoration: const InputDecoration(
                        hintText: 'Select a directory...',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _selectCustomDirectory,
                    child: const Text('Browse'),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Current storage info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Storage Information',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<String>(
                      future: _getLocationPath(_settings.storageLocation),
                      builder: (context, snapshot) {
                        return Text(
                          'Location: ${_settingsService.getStorageLocationDisplayName(_settings.storageLocation)}',
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    FutureBuilder<String>(
                      future: _getLocationPath(_settings.storageLocation),
                      builder: (context, snapshot) {
                        return Text(
                          'Path: ${snapshot.data ?? 'Loading...'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => _testStorageLocation(_settings),
                      child: const Text('Test Location'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Backup & Export section
            const Text(
              'Backup & Export',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Export Notes'),
                    subtitle: const Text(
                      'Export all notes as markdown files in a zip archive',
                    ),
                    leading: const Icon(Icons.download),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _exportNotes,
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Import Notes'),
                    subtitle: const Text('Import notes from a zip archive'),
                    leading: const Icon(Icons.upload),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _importNotes,
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Create Full Backup'),
                    subtitle: const Text('Backup notes and settings together'),
                    leading: const Icon(Icons.backup),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _createFullBackup,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _enableEncryption() async {
    try {
      final passwordData = await PasswordManager.showPasswordSetupDialog(
        context,
      );
      if (passwordData == null) return; // User cancelled

      setState(() {
        _isMigrating = true;
      });

      // Re-encrypt existing notes with the new password
      final currentNotes = await _notesService.loadNotes(_settings);

      final newSettings = _settings.copyWith(
        encryptionEnabled: true,
        passwordHash: passwordData['hash'],
      );

      // Store the password salt in SharedPreferences for verification
      if (_settings.storageLocation == 'shared_preferences') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('password_salt', passwordData['salt']!);
        // Also set encryption_salt to the same value for consistency
        await prefs.setString('encryption_salt', passwordData['salt']!);
      } else {
        // For file storage, store password salt in a separate file
        final filePath = await _getLocationPath(_settings.storageLocation);
        final passwordSaltFile = File('$filePath/password.salt');
        await passwordSaltFile.parent.create(recursive: true);
        await passwordSaltFile.writeAsString(passwordData['salt']!);

        // Also ensure encryption salt file uses the same salt
        final encryptionSaltFile = File('$filePath/notes.json.salt');
        await encryptionSaltFile.writeAsString(passwordData['salt']!);
      }

      // Save notes with encryption
      await _notesService.saveNotes(
        currentNotes,
        newSettings,
        passwordData['password'],
      );

      setState(() {
        _settings = newSettings;
        _isMigrating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Encryption enabled successfully!')),
        );
      }
    } catch (e) {
      setState(() {
        _isMigrating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to enable encryption: $e')),
        );
      }
    }
  }

  Future<void> _disableEncryption() async {
    if (_settings.passwordHash == null) return;

    try {
      final password = await PasswordManager.showPasswordInputDialog(
        context,
        passwordHash: _settings.passwordHash!,
        salt: await _getSalt(),
        title: 'Confirm Disable Encryption',
        message:
            'Enter your password to disable encryption and decrypt your notes.',
      );

      if (password == null) return; // User cancelled

      setState(() {
        _isMigrating = true;
      });

      // Load and decrypt existing notes
      final currentNotes = await _notesService.loadNotes(_settings, password);

      final newSettings = _settings.copyWith(
        encryptionEnabled: false,
        passwordHash: null,
      );

      // Save notes without encryption
      await _notesService.saveNotes(currentNotes, newSettings);

      setState(() {
        _settings = newSettings;
        _isMigrating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Encryption disabled successfully!')),
        );
      }
    } catch (e) {
      setState(() {
        _isMigrating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to disable encryption: $e')),
        );
      }
    }
  }

  Future<void> _changePassword() async {
    if (_settings.passwordHash == null) return;

    try {
      final passwordData = await PasswordManager.showPasswordChangeDialog(
        context,
        currentPasswordHash: _settings.passwordHash!,
        currentSalt: await _getSalt(),
      );

      if (passwordData == null) return; // User cancelled

      setState(() {
        _isMigrating = true;
      });

      // Load notes with current password
      final currentNotes = await _notesService.loadNotes(
        _settings,
        passwordData['currentPassword'],
      );

      final newSettings = _settings.copyWith(
        passwordHash: passwordData['newHash'],
      );

      // Store the new password salt
      if (_settings.storageLocation == 'shared_preferences') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('password_salt', passwordData['newSalt']!);
        // Also update encryption salt to keep them in sync
        await prefs.setString('encryption_salt', passwordData['newSalt']!);
      } else {
        final filePath = await _getLocationPath(_settings.storageLocation);
        final passwordSaltFile = File('$filePath/password.salt');
        await passwordSaltFile.writeAsString(passwordData['newSalt']!);

        // Also update encryption salt file
        final encryptionSaltFile = File('$filePath/notes.json.salt');
        await encryptionSaltFile.writeAsString(passwordData['newSalt']!);
      }

      // Re-encrypt notes with new password
      await _notesService.saveNotes(
        currentNotes,
        newSettings,
        passwordData['newPassword'],
      );

      setState(() {
        _settings = newSettings;
        _isMigrating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully!')),
        );
      }
    } catch (e) {
      setState(() {
        _isMigrating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to change password: $e')),
        );
      }
    }
  }

  Future<String> _getSalt() async {
    if (_settings.storageLocation == 'shared_preferences') {
      final prefs = await SharedPreferences.getInstance();
      // First try to get password salt, fallback to encryption salt
      return prefs.getString('password_salt') ??
          prefs.getString('encryption_salt') ??
          '';
    } else {
      final filePath = await _getLocationPath(_settings.storageLocation);
      // First try password salt file, then encryption salt file
      final passwordSaltFile = File('$filePath/password.salt');
      if (await passwordSaltFile.exists()) {
        return await passwordSaltFile.readAsString();
      }

      final saltFile = File('$filePath/notes.json.salt');
      if (await saltFile.exists()) {
        return await saltFile.readAsString();
      }
      return '';
    }
  }

  Future<void> _exportNotes() async {
    try {
      setState(() {
        _isMigrating = true;
      });

      final backupService = BackupService();
      final password =
          _settings.encryptionEnabled ? PasswordManager.currentPassword : null;

      // Load all notes
      final notes = await _notesService.loadNotes(_settings, password);

      if (notes.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No notes to export')));
        return;
      }

      // Let user choose export location
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Notes Export',
        fileName:
            'jotdown_export_${DateTime.now().toIso8601String().split('T')[0]}.zip',
        type: FileType.any,
      );

      if (result != null) {
        final exportPath = await backupService.exportNotesToZip(
          notes: notes,
          customPath: File(result).parent.path,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notes exported to: $exportPath')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      setState(() {
        _isMigrating = false;
      });
    }
  }

  Future<void> _importNotes() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        dialogTitle: 'Select Notes Archive to Import',
      );

      if (result != null && result.files.single.path != null) {
        final shouldProceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Import Notes'),
            content: const Text(
              'This will import notes from the selected archive. '
              'Existing notes with the same ID will be updated. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Import'),
              ),
            ],
          ),
        );

        if (shouldProceed == true) {
          setState(() {
            _isMigrating = true;
          });

          final backupService = BackupService();
          final importedNotes = await backupService.importNotesFromZip(
            result.files.single.path!,
          );

          // Load current notes
          final password = _settings.encryptionEnabled
              ? PasswordManager.currentPassword
              : null;
          final currentNotes = await _notesService.loadNotes(
            _settings,
            password,
          );

          // Merge notes (imported notes take precedence)
          final mergedNotes = <String, Note>{};

          // Add existing notes
          for (final note in currentNotes) {
            mergedNotes[note.id] = note;
          }

          // Add/update with imported notes
          for (final note in importedNotes) {
            mergedNotes[note.id] = note;
          }

          // Save merged notes
          await _notesService.saveNotes(
            mergedNotes.values.toList(),
            _settings,
            password,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully imported ${importedNotes.length} notes',
              ),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    } finally {
      setState(() {
        _isMigrating = false;
      });
    }
  }

  Future<void> _createFullBackup() async {
    try {
      setState(() {
        _isMigrating = true;
      });

      final backupService = BackupService();
      final password =
          _settings.encryptionEnabled ? PasswordManager.currentPassword : null;

      // Let user choose backup location
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Full Backup',
        fileName:
            'jotdown_full_backup_${DateTime.now().toIso8601String().split('T')[0]}.zip',
        type: FileType.any,
      );

      if (result != null) {
        final backupPath = await backupService.createFullBackup(
          _settings,
          password,
        );

        // Move to user-selected location if different
        if (result != backupPath) {
          final backupFile = File(backupPath);
          final targetFile = File(result);
          await backupFile.copy(targetFile.path);
          await backupFile.delete();
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Full backup created: $result')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
    } finally {
      setState(() {
        _isMigrating = false;
      });
    }
  }

  Widget _buildStorageOption(String location) {
    return Card(
      child: RadioListTile<String>(
        title: Text(_settingsService.getStorageLocationDisplayName(location)),
        subtitle: FutureBuilder<String>(
          future: _getLocationPath(location),
          builder: (context, snapshot) {
            String description;
            switch (location) {
              case 'shared_preferences':
                description =
                    'Stored securely in app data. No file access needed.';
                break;
              case 'documents':
                description =
                    'Stored in your Documents folder for easy access.';
                break;
              case 'home':
                description = 'Stored in your home directory.';
                break;
              case 'custom':
                description = 'Choose your own storage location.';
                break;
              default:
                description = '';
            }
            return Text(description);
          },
        ),
        value: location,
        groupValue: _settings.storageLocation,
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _settings = _settings.copyWith(storageLocation: value);
            });
          }
        },
      ),
    );
  }

  Widget _buildThemeOption(String themeMode, String title, String description) {
    return Card(
      child: RadioListTile<String>(
        title: Text(title),
        subtitle: Text(description),
        value: themeMode,
        groupValue: _settings.themeMode,
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _settings = _settings.copyWith(themeMode: value);
            });
          }
        },
      ),
    );
  }
}
