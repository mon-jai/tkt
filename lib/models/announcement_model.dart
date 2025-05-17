class Announcement {
  final String title;
  final String date;
  final String link;

  Announcement({
    required this.title,
    required this.date,
    required this.link,
  });

  @override
  String toString() {
    return 'Announcement(title: $title, date: $date, link: $link)';
  }
} 