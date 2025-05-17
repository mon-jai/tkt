class Discussion {
  final String id;
  final String title;
  final String content;
  final DateTime createTime;
  final String author;
  final int likes;
  final int comments;
  final String category;
  final List<String>? tags;

  Discussion({
    required this.id,
    required this.title,
    required this.content,
    required this.createTime,
    required this.author,
    this.likes = 0,
    this.comments = 0,
    required this.category,
    this.tags,
  });

  factory Discussion.fromJson(Map<String, dynamic> json) {
    return Discussion(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      createTime: DateTime.parse(json['create_time'] as String),
      author: json['author'] as String,
      likes: json['likes'] as int? ?? 0,
      comments: json['comments'] as int? ?? 0,
      category: json['category'] as String,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );
  }
}

class Comment {
  final String id;
  final String discussionId;
  final String content;
  final String author;
  final DateTime createTime;
  final int likes;

  Comment({
    required this.id,
    required this.discussionId,
    required this.content,
    required this.author,
    required this.createTime,
    this.likes = 0,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      discussionId: json['discussion_id'] as String,
      content: json['content'] as String,
      author: json['author'] as String,
      createTime: DateTime.parse(json['create_time'] as String),
      likes: json['likes'] as int? ?? 0,
    );
  }
} 