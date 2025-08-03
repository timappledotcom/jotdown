import 'package:flutter/material.dart';
import 'package:yaru/yaru.dart';
import 'screens/notes_list_screen.dart';
import 'models/app_settings.dart';
import 'services/settings_service.dart';

void main() {
  runApp(const JotDownApp());
}

class JotDownApp extends StatefulWidget {
  const JotDownApp({super.key});

  @override
  State<JotDownApp> createState() => _JotDownAppState();
}

class _JotDownAppState extends State<JotDownApp> {
  final SettingsService _settingsService = SettingsService();
  AppSettings _settings = AppSettings();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _settingsService.loadSettings();
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateSettings(AppSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });
  }

  ThemeMode _getThemeMode() {
    switch (_settings.themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        theme: _buildUbuntuLightTheme(),
        darkTheme: _buildUbuntuDarkTheme(),
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading jotDown...'),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'jotDown',
      theme: _buildUbuntuLightTheme(),
      darkTheme: _buildUbuntuDarkTheme(),
      themeMode: _getThemeMode(),
      home: NotesListScreen(onSettingsChanged: _updateSettings),
      debugShowCheckedModeBanner: false,
    );
  }

  ThemeData _buildUbuntuLightTheme() {
    // Use Yaru light theme as base
    final baseTheme = yaruLight;

    return baseTheme.copyWith(
      // Use Ubuntu's signature orange accent color
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: const Color(0xFFE95420), // Ubuntu orange
        secondary: const Color(0xFF77216F), // Ubuntu purple
      ),

      // Ubuntu-style app bar
      appBarTheme: baseTheme.appBarTheme.copyWith(
        backgroundColor: const Color(0xFFE95420),
        foregroundColor: Colors.white,
        elevation: 0, // Ubuntu prefers flat design
        centerTitle: false, // Ubuntu apps typically left-align titles
      ),

      // Ubuntu-style floating action button
      floatingActionButtonTheme: baseTheme.floatingActionButtonTheme.copyWith(
        backgroundColor: const Color(0xFFE95420),
        foregroundColor: Colors.white,
        elevation: 2, // Subtle elevation
      ),

      // Ubuntu-style cards and surfaces
      cardTheme: baseTheme.cardTheme.copyWith(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // Ubuntu's preferred radius
        ),
      ),

      // Ubuntu-style input decoration
      inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: baseTheme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: baseTheme.colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: baseTheme.colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE95420), width: 2),
        ),
      ),
    );
  }

  ThemeData _buildUbuntuDarkTheme() {
    // Use Yaru dark theme as base
    final baseTheme = yaruDark;

    return baseTheme.copyWith(
      // Use Ubuntu's signature colors for dark theme
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: const Color(0xFFE95420), // Ubuntu orange
        secondary: const Color(0xFF77216F), // Ubuntu purple
      ),

      // Ubuntu-style dark app bar
      appBarTheme: baseTheme.appBarTheme.copyWith(
        backgroundColor: const Color(0xFF2C2C2C), // Ubuntu dark header
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),

      // Ubuntu-style dark floating action button
      floatingActionButtonTheme: baseTheme.floatingActionButtonTheme.copyWith(
        backgroundColor: const Color(0xFFE95420),
        foregroundColor: Colors.white,
        elevation: 2,
      ),

      // Ubuntu-style dark cards
      cardTheme: baseTheme.cardTheme.copyWith(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Ubuntu-style dark input decoration
      inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: baseTheme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: baseTheme.colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: baseTheme.colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE95420), width: 2),
        ),
      ),
    );
  }
}
