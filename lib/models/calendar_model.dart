class Calendar {
  final String title;
  final String url;
  final String type;
  final String? description;

  Calendar({
    required this.title,
    required this.url,
    required this.type,
    this.description,
  });

  factory Calendar.fromJson(Map<String, dynamic> json) {
    return Calendar(
      title: json['title'] as String,
      url: json['url'] as String,
      type: json['type'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'url': url,
    'type': type,
    if (description != null) 'description': description,
  };
} 