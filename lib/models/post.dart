class Post {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String date;
  final String? detailContent; // More detailed content for the detail view

  Post({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.date,
    this.detailContent,
  });
} 