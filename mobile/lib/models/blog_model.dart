// Blog module data models

class BlogPost {
  final int id;
  final String title;
  final String cropName;
  final String description;
  final String farmerName;
  final List<String> imagePaths;
  final String videoPath;
  final String createdAt;
  final double averageRating;
  final int ratingCount;

  const BlogPost({
    required this.id,
    required this.title,
    required this.cropName,
    required this.description,
    required this.farmerName,
    required this.imagePaths,
    required this.videoPath,
    required this.createdAt,
    required this.averageRating,
    required this.ratingCount,
  });

  factory BlogPost.fromJson(Map<String, dynamic> json) {
    List<String> parsedImages = [];
    final rawImages = json['image_paths'];
    if (rawImages is List) {
      parsedImages = rawImages.map((e) => e.toString()).toList();
    }

    return BlogPost(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      cropName: json['crop_name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      farmerName: json['farmer_name'] as String? ?? '',
      imagePaths: parsedImages,
      videoPath: json['video_path'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: json['rating_count'] as int? ?? 0,
    );
  }

  /// Short preview of the description for blog card
  String get shortDescription {
    if (description.length <= 120) return description;
    return '${description.substring(0, 117)}...';
  }

  /// Formatted date string
  String get formattedDate {
    try {
      final dt = DateTime.parse(createdAt);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return createdAt;
    }
  }
}

class BlogComment {
  final int id;
  final int blogId;
  final String farmerName;
  final String comment;
  final String createdAt;

  const BlogComment({
    required this.id,
    required this.blogId,
    required this.farmerName,
    required this.comment,
    required this.createdAt,
  });

  factory BlogComment.fromJson(Map<String, dynamic> json) => BlogComment(
        id: json['id'] as int? ?? 0,
        blogId: json['blog_id'] as int? ?? 0,
        farmerName: json['farmer_name'] as String? ?? '',
        comment: json['comment'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
      );

  String get formattedDate {
    try {
      final dt = DateTime.parse(createdAt);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return createdAt;
    }
  }
}
