import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/note.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  final Function(Note) onSave;

  const NoteEditorScreen({super.key, this.note, required this.onSave});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isPreviewMode = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );

    _titleController.addListener(_onContentChanged);
    _contentController.addListener(_onContentChanged);
  }

  void _onContentChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    final content = _contentController.text;

    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }

    final now = DateTime.now();
    final note = Note(
      id: widget.note?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      createdAt: widget.note?.createdAt ?? now,
      updatedAt: now,
    );

    widget.onSave(note);
    setState(() {
      _hasChanges = false;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
        actions: [
          IconButton(
            icon: Icon(_isPreviewMode ? Icons.edit : Icons.preview),
            onPressed: () {
              setState(() {
                _isPreviewMode = !_isPreviewMode;
              });
            },
            tooltip: _isPreviewMode ? 'Edit' : 'Preview',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveNote,
            tooltip: 'Save',
          ),
        ],
      ),
      body: Column(
        children: [
          // Title input
          Container(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Note Title',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // Content area
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _isPreviewMode ? _buildPreview() : _buildEditor(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return TextField(
      controller: _contentController,
      decoration: InputDecoration(
        hintText: 'Write your note in Markdown...',
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[850]
            : Colors.grey[50],
      ),
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      style: TextStyle(
        fontFamily: 'monospace',
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[200]
            : Colors.black87,
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[600]!
              : Colors.grey,
        ),
        borderRadius: BorderRadius.circular(4.0),
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[850]
            : Colors.grey[50],
      ),
      child: Markdown(
        data: _contentController.text.isEmpty
            ? '*No content to preview*'
            : _contentController.text,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          h1: TextStyle(
            color: Theme.of(context).textTheme.headlineLarge?.color,
          ),
          h2: TextStyle(
            color: Theme.of(context).textTheme.headlineMedium?.color,
          ),
          h3: TextStyle(
            color: Theme.of(context).textTheme.headlineSmall?.color,
          ),
          code: TextStyle(
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.grey[200],
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.blue[300]
                : Colors.blue[700],
          ),
          codeblockDecoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
