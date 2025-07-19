# jotDown - Ubuntu Desktop & CLI App

A simple and elegant notes application for Ubuntu with both a desktop GUI and command-line interface. jotDown allows you to create, edit, and manage your notes with Markdown support, accessible from both a beautiful desktop application and a powerful CLI.

## Features

- **Notes List**: View all your notes in a clean, organized list
- **Search**: Quickly find notes by searching in titles and content
- **Markdown Editing**: Write your notes in Markdown format
- **Live Preview**: Toggle between edit and preview modes
- **Flexible Storage**: Choose where your notes are stored
  - App Data (Shared Preferences) - Default, no file system access required
  - Documents folder - Easy access from file manager
  - Home directory - Quick access from your user folder
  - Custom location - Choose any directory you prefer
- **Note Migration**: Automatically migrate notes when changing storage location
- **Dark/Light Theme**:
  - **System Auto** - Automatically follows your system's theme setting (default)
  - **Light Mode** - Always use light theme
  - **Dark Mode** - Always use dark theme
- **Command Line Interface**: Full CLI access to all notes and settings
- **Cross-Platform Access**: Use desktop GUI or command line interface
- **Ubuntu Native**: Runs natively on Ubuntu Desktop

## Screenshots

- **Notes List**: Main screen showing all notes with search functionality
- **Note Editor**: Split view with Markdown editor and live preview
- **Markdown Support**: Full Markdown formatting including headers, lists, code blocks, etc.

## Installation

1. Make sure you have Flutter installed:
   ```bash
   sudo snap install flutter --classic
   ```

2. Clone or navigate to the project directory:
   ```bash
   cd /home/tim/Projects/jotDown
   ```

3. Get dependencies:
   ```bash
   flutter pub get
   ```

4. Run the desktop app:
   ```bash
   flutter run -d linux
   ```

5. Or use the command line interface:
   ```bash
   dart bin/jotdown.dart --help
   ```

## Usage

### Creating a New Note
- Click the "+" floating action button on the main screen
- Enter a title for your note
- Write your content using Markdown syntax
- Click the save button or use Ctrl+S

### Editing Notes
- Click on any note from the list to edit it
- Use the preview button to see how your Markdown will render
- Changes are automatically saved when you click save

### Markdown Features Supported
- Headers (# ## ###)
- **Bold** and *italic* text
- Lists (ordered and unordered)
- Code blocks and inline code
- Links and images
- Blockquotes
- Tables
- And more!

### Changing Storage Location
- Click the settings icon (gear) in the top right of the main screen
- Choose from available storage options:
  - **App Data**: Stored securely, no file access needed (default)
  - **Documents**: Stored in ~/Documents/jotDown/ folder
  - **Home**: Stored in ~/jotDown/ folder
  - **Custom**: Choose your own directory
- Click "Test Location" to verify the chosen location is accessible
- Save settings and optionally migrate existing notes to the new location

### Theme Selection
- In the settings screen, choose your preferred theme:
  - **System Default**: Automatically follows your Ubuntu system theme (recommended)
  - **Light Mode**: Always use light theme regardless of system setting
  - **Dark Mode**: Always use dark theme regardless of system setting
- Changes apply immediately when you return to the main screen

### Searching Notes
- Use the search bar at the top of the main screen
- Search works on both note titles and content
- Results update in real-time as you type

## Dependencies

- `flutter_markdown`: For rendering Markdown content
- `shared_preferences`: For local data persistence and app settings
- `path_provider`: For accessing system directories
- `file_picker`: For custom directory selection
- `json_annotation` & `json_serializable`: For data serialization

## Development

To build and run in development mode:
```bash
flutter run -d linux
```

To build a release version:
```bash
flutter build linux
```

## File Structure

```
lib/
├── main.dart                    # App entry point
├── models/
│   ├── note.dart               # Note data model
│   ├── note.g.dart            # Generated JSON serialization (Note)
│   ├── app_settings.dart       # App settings model
│   └── app_settings.g.dart     # Generated JSON serialization (Settings)
├── services/
│   ├── notes_service.dart      # Data persistence service
│   └── settings_service.dart   # Settings management service
└── screens/
    ├── notes_list_screen.dart  # Main notes list screen
    ├── note_editor_screen.dart # Note editing screen
    └── settings_screen.dart    # Settings configuration screen
```

## Contributing

This is a personal project but suggestions and improvements are welcome!

## License

This project is open source and available under the MIT License.
