/// Note model used in the UI layer.
class Note {
  const Note({
    required this.id,
    required this.title,
    required this.content,
  });

  final int id;
  final String title;
  final String content;

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
    );
  }
}
