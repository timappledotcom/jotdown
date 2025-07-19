import 'package:flutter/material.dart';
import '../services/encryption_service.dart';

class PasswordManager {
  static String? _currentPassword;
  static String? _currentSalt;

  /// Show password setup dialog for first-time encryption
  static Future<Map<String, String>?> showPasswordSetupDialog(
    BuildContext context,
  ) async {
    String? password;
    String? confirmPassword;

    return await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Set Encryption Password'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose a strong password to encrypt your notes. '
                'This password cannot be recovered if lost.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => password = value,
              ),
              const SizedBox(height: 12),
              TextField(
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => confirmPassword = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (password == null || password!.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password must be at least 6 characters'),
                  ),
                );
                return;
              }
              if (password != confirmPassword) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }

              final salt = EncryptionService.generateSalt();
              final hash = EncryptionService.hashPassword(password!, salt);

              _currentPassword = password;
              _currentSalt = salt;

              Navigator.pop(context, {
                'password': password!,
                'salt': salt,
                'hash': hash,
              });
            },
            child: const Text('Set Password'),
          ),
        ],
      ),
    );
  }

  /// Show password input dialog for authentication
  static Future<String?> showPasswordInputDialog(
    BuildContext context, {
    required String passwordHash,
    required String salt,
    String title = 'Enter Password',
    String message = 'Enter your password to access encrypted notes.',
  }) async {
    String? password;

    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => password = value,
              onSubmitted: (_) =>
                  _validateAndClose(context, password, passwordHash, salt),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                _validateAndClose(context, password, passwordHash, salt),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }

  static void _validateAndClose(
    BuildContext context,
    String? password,
    String passwordHash,
    String salt,
  ) {
    if (password == null || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a password')));
      return;
    }

    if (EncryptionService.verifyPassword(password, passwordHash, salt)) {
      _currentPassword = password;
      _currentSalt = salt;
      Navigator.pop(context, password);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Incorrect password')));
    }
  }

  /// Show password change dialog
  static Future<Map<String, String>?> showPasswordChangeDialog(
    BuildContext context, {
    required String currentPasswordHash,
    required String currentSalt,
  }) async {
    String? currentPassword;
    String? newPassword;
    String? confirmNewPassword;

    return await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => currentPassword = value,
              ),
              const SizedBox(height: 12),
              TextField(
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => newPassword = value,
              ),
              const SizedBox(height: 12),
              TextField(
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => confirmNewPassword = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (currentPassword == null ||
                  !EncryptionService.verifyPassword(
                    currentPassword!,
                    currentPasswordHash,
                    currentSalt,
                  )) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Current password is incorrect'),
                  ),
                );
                return;
              }

              if (newPassword == null || newPassword!.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('New password must be at least 6 characters'),
                  ),
                );
                return;
              }

              if (newPassword != confirmNewPassword) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('New passwords do not match')),
                );
                return;
              }

              final newSalt = EncryptionService.generateSalt();
              final newHash = EncryptionService.hashPassword(
                newPassword!,
                newSalt,
              );

              _currentPassword = newPassword;
              _currentSalt = newSalt;

              Navigator.pop(context, {
                'currentPassword': currentPassword!,
                'newPassword': newPassword!,
                'newSalt': newSalt,
                'newHash': newHash,
              });
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }

  /// Get current password (if authenticated)
  static String? get currentPassword => _currentPassword;

  /// Get current salt
  static String? get currentSalt => _currentSalt;

  /// Clear current password (logout)
  static void clearPassword() {
    _currentPassword = null;
    _currentSalt = null;
  }

  /// Check if user is currently authenticated
  static bool get isAuthenticated => _currentPassword != null;
}
