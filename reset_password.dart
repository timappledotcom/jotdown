#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';

void main() async {
  print('=== jotDown Password Reset Tool ===\n');
  print('This will reset your encryption settings due to a salt mismatch bug.');
  print('You will need to set up encryption again after running this.\n');

  stdout.write('Do you want to continue? (y/N): ');
  final response = stdin.readLineSync() ?? '';

  if (response.toLowerCase() != 'y') {
    print('Cancelled.');
    return;
  }

  try {
    final spFile = File(
        '/home/${Platform.environment['USER']}/.local/share/com.example.jotdown/shared_preferences.json');

    if (!await spFile.exists()) {
      print('SharedPreferences file not found.');
      return;
    }

    // Backup original file
    final backupFile =
        File('${spFile.path}.backup.${DateTime.now().millisecondsSinceEpoch}');
    await spFile.copy(backupFile.path);
    print('Backup created: ${backupFile.path}');

    // Read current data
    final spContent = await spFile.readAsString();
    final spData = json.decode(spContent) as Map<String, dynamic>;

    // Update settings to disable encryption
    final settingsJson = spData['flutter.app_settings'];
    if (settingsJson != null) {
      final settings = json.decode(settingsJson) as Map<String, dynamic>;
      settings['encryptionEnabled'] = false;
      settings['passwordHash'] = null;
      spData['flutter.app_settings'] = json.encode(settings);

      // Remove salt keys
      spData.remove('flutter.encryption_salt');
      spData.remove('flutter.password_salt');

      // Decrypt notes if they were encrypted
      final notesData = spData['flutter.notes_data'];
      if (notesData != null && notesData is String) {
        try {
          // Check if it's encrypted (would fail JSON decode)
          json.decode(notesData);
          print('Notes appear to be unencrypted, keeping as-is.');
        } catch (e) {
          print('Notes appear to be encrypted. Manual recovery may be needed.');
          print(
              'The notes data has been left as-is. You may lose access to encrypted notes.');
        }
      }
    }

    // Write back
    await spFile.writeAsString(json.encode(spData));

    print('\n✅ Reset complete!');
    print('- Encryption has been disabled');
    print('- Password hash removed');
    print('- Salt keys removed');
    print(
        '\nYou can now open jotDown and set up encryption again with the fixed code.');
  } catch (e) {
    print('Error: $e');
  }
}
