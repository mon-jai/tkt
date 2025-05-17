class Announcement {
  final String id;
  final String title;
  final String content;
  final DateTime publishDate;
  final String author;
  final String? imageUrl;
  final String category;
  final bool isImportant;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.publishDate,
    required this.author,
    this.imageUrl,
    required this.category,
    this.isImportant = false,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      publishDate: DateTime.parse(json['publish_date'] as String),
      author: json['author'] as String,
      imageUrl: json['image_url'] as String?,
      category: json['category'] as String,
      isImportant: json['is_important'] as bool? ?? false,
    );
  }
} 