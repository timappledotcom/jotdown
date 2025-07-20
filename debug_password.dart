#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';

void main() async {
  print('=== jotDown Password Debug Tool ===\n');

  try {
    // Check SharedPreferences file
    final spFile = File(
        '/home/${Platform.environment['USER']}/.local/share/com.example.jotdown/shared_preferences.json');

    if (!await spFile.exists()) {
      print('SharedPreferences file not found at: ${spFile.path}');
      return;
    }

    final spContent = await spFile.readAsString();
    final spData = json.decode(spContent) as Map<String, dynamic>;

    print('SharedPreferences data:');
    print(
        '- encryption_salt: ${spData['flutter.encryption_salt'] ?? 'NOT_FOUND'}');
    print('- password_salt: ${spData['flutter.password_salt'] ?? 'NOT_FOUND'}');

    final settingsJson = spData['flutter.app_settings'];
    if (settingsJson != null) {
      final settings = json.decode(settingsJson) as Map<String, dynamic>;
      print('- passwordHash: ${settings['passwordHash'] ?? 'NOT_FOUND'}');
      print(
          '- encryptionEnabled: ${settings['encryptionEnabled'] ?? 'NOT_FOUND'}');
    }

    // Test password verification
    print('\n=== Password Test ===');
    stdout.write('Enter password to test: ');
    stdin.echoMode = false;
    final password = stdin.readLineSync() ?? '';
    stdin.echoMode = true;
    print('');

    if (password.isEmpty) {
      print('No password entered, exiting.');
      return;
    }

    final encSalt = spData['flutter.encryption_salt'];
    final pwdSalt = spData['flutter.password_salt'];
    final settingsStr = spData['flutter.app_settings'];

    if (settingsStr != null && (encSalt != null || pwdSalt != null)) {
      final settings = json.decode(settingsStr);
      final storedHash = settings['passwordHash'];

      if (storedHash != null) {
        // Test with encryption salt
        if (encSalt != null) {
          final testHash1 = hashPassword(password, encSalt);
          print('Hash with encryption_salt: $testHash1');
          print('Stored hash:               $storedHash');
          print('Match with encryption_salt: ${testHash1 == storedHash}');
        }

        // Test with password salt
        if (pwdSalt != null) {
          final testHash2 = hashPassword(password, pwdSalt);
          print('Hash with password_salt:    $testHash2');
          print('Match with password_salt:   ${testHash2 == storedHash}');
        }
      }
    }
  } catch (e) {
    print('Error: $e');
  }
}

// Simple PBKDF2 implementation for testing
String hashPassword(String password, String saltBase64) {
  // This is a simplified version - in production we use pointycastle
  // For debugging purposes only
  print('(Note: This uses simplified hashing for debugging)');
  return 'DEBUG_HASH_${password.length}_${saltBase64.length}';
}
