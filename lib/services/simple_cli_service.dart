import '../models/note.dart';
import 'flat_file_service.dart';

/// Simple CLI service that uses the same flat file storage as the GUI
class SimpleCLIService {
  final FlatFileService _fileService = FlatFileService();

  Future<List<Note>> loadNotes() async {
    return await _fileService.loadNotes();
  }

  Future<void> saveNote(Note note) async {
    await _fileService.saveNote(note);
  }

  Future<void> deleteNote(String noteId) async {
    await _fileService.deleteNote(noteId);
  }

  String get storagePath => _fileService.storagePath;
}