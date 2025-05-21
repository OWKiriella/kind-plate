class Campaign {
  final String id;
  final String title;
  final String location;
  final String description;
  final String imageUrl;
  final String timeAgo;
  final String urgencyLabel;
  final List<String> requiredItems;
  final int donatedAmount;
  final int targetAmount;
  final double progress;
  final String status;

  Campaign({
    required this.id,
    required this.title,
    required this.location,
    required this.description,
    required this.imageUrl,
    required this.timeAgo,
    required this.urgencyLabel,
    required this.requiredItems,
    required this.donatedAmount,
    required this.targetAmount,
    required this.progress,
    this.status = 'active',
  });
} 

//Fields constructor 
//required keyword ensures that all fields must be provided