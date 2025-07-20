import 'package:json_annotation/json_annotation.dart';

part 'note.g.dart';

@JsonSerializable()
class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Extracts tags from the note content (words starting with #)
  List<String> get tags {
    final tagRegex = RegExp(r'#(\w+)');
    final matches = tagRegex.allMatches(content);
    return matches
        .map((match) => match.group(1)!.toLowerCase())
        .toSet()
        .toList();
  }

  /// Returns true if this note contains the specified tag
  bool hasTag(String tag) {
    return tags.contains(tag.toLowerCase());
  }

  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Note.fromJson(Map<String, dynamic> json) => _$NoteFromJson(json);
  Map<String, dynamic> toJson() => _$NoteToJson(this);
}
