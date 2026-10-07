class Note {
  final String id;
  final String title;
  final String content;
  final String? imagePath;
  final DateTime createdAt;
  final String userId;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.imagePath,
    required this.createdAt,
    required this.userId,
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      imagePath: map['image_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      userId: map['user_id'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'image_path': imagePath,
      'user_id': userId,
    };
  }
}