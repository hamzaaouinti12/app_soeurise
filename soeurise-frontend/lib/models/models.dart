import 'dart:io';
import '../constants.dart';

/// Backend user model — maps to the User mongoose schema.
class User {
  final String id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String avatarUrl;
  final String role;
  final bool isActive;
  final int followingCount;
  final int followersCount;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    this.avatarUrl = '',
    this.role = 'user',
    this.isActive = true,
    this.followingCount = 0,
    this.followersCount = 0,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      role: json['role'] ?? 'user',
      isActive: json['isActive'] ?? true,
      followingCount: json['followingCount'] ?? 0,
      followersCount: json['followersCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  String get fullName => '$firstName $lastName';
  String get avatarFullUrl => ApiConfig.uploadsUrl(avatarUrl);
}

class Post {
  final String id;
  final String authorId;
  final String username;
  final String profileImageUrl;
  final String content;
  final String? imageUrl;
  final File? localImageFile;
  final DateTime timestamp;
  int likes;
  int comments;
  int shares;
  bool isLiked;

  Post({
    required this.id,
    this.authorId = '',
    required this.username,
    required this.profileImageUrl,
    required this.content,
    this.imageUrl,
    this.localImageFile,
    required this.timestamp,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.isLiked = false,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final author = json['author'] ?? {};
    final fName = author['firstName'] ?? '';
    final lName = author['lastName'] ?? '';
    final uName = author['username'] ?? '';
    final avatar = author['avatarUrl'] ?? '';
    final authorId = author['id']?.toString() ?? author['_id']?.toString() ?? '';

    final name = fName.isNotEmpty ? '$fName $lName' : uName;

    return Post(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      authorId: authorId,
      username: name.isNotEmpty ? name : 'Utilisateur',
      profileImageUrl: ApiConfig.uploadsUrl(avatar),
      content: json['content'] ?? '',
      imageUrl: json['image'] != null && json['image'].toString().isNotEmpty
          ? ApiConfig.uploadsUrl(json['image'])
          : null,
      timestamp: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      likes: json['likesCount'] ?? 0,
      comments: json['commentsCount'] ?? 0,
      shares: json['sharesCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
    );
  }
}

class Comment {
  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String content;
  final DateTime createdAt;
  int likesCount;
  bool isLiked;
  List<Comment> replies;

  Comment({
    required this.id,
    this.authorId = '',
    required this.authorName,
    this.authorAvatar = '',
    required this.content,
    required this.createdAt,
    this.likesCount = 0,
    this.isLiked = false,
    this.replies = const [],
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final author = json['author'] ?? {};
    final fName = author['firstName'] ?? '';
    final lName = author['lastName'] ?? '';
    final uName = author['username'] ?? '';
    final avatar = author['avatarUrl'] ?? '';
    final authorId = author['id']?.toString() ?? author['_id']?.toString() ?? '';

    final name = fName.isNotEmpty ? '$fName $lName' : uName;
    final likes = json['likes'] as List<dynamic>? ?? [];

    final repliesJson = json['replies'] as List<dynamic>? ?? [];

    return Comment(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      authorId: authorId,
      authorName: name.isNotEmpty ? name : 'Utilisateur',
      authorAvatar: ApiConfig.uploadsUrl(avatar),
      content: json['content'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      likesCount: likes.length,
      isLiked: false,
      replies: repliesJson.map((r) => Comment.fromJson(r)).toList(),
    );
  }
}

/// Backend group model — maps to the Group mongoose schema.
class Community {
  final String id;
  final String name;
  final String description;
  int members;
  final String imageUrl;
  final bool isPublic;
  final bool requiresSubscription;

  Community({
    required this.id,
    required this.name,
    required this.description,
    required this.members,
    required this.imageUrl,
    this.isPublic = true,
    this.requiresSubscription = false,
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      members: json['memberCount'] ?? 0,
      imageUrl: ApiConfig.uploadsUrl(json['imageUrl'] ?? ''),
      isPublic: json['isPublic'] ?? true,
      requiresSubscription: json['requiresSubscription'] ?? false,
    );
  }
}

class Masterclass {
  final String id;
  final String title;
  final String description;
  final String instructorName;
  final DateTime createdDate;
  final String videoUrl;
  final String thumbnailUrl;

  Masterclass({
    required this.id,
    required this.title,
    required this.description,
    required this.instructorName,
    required this.createdDate,
    required this.videoUrl,
    required this.thumbnailUrl,
  });

  factory Masterclass.fromJson(Map<String, dynamic> json) {
    return Masterclass(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      instructorName: json['instructorName'] ?? '',
      createdDate: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      videoUrl: json['videoUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
    );
  }
}

class Event {
  final String id;
  final String title;
  final DateTime dateTime;
  final String type;
  final String location;
  final String imageUrl;

  Event({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.type,
    required this.location,
    required this.imageUrl,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title'] ?? '',
      dateTime: json['dateTime'] != null
          ? DateTime.tryParse(json['dateTime']) ?? DateTime.now()
          : DateTime.now(),
      type: json['type'] ?? 'online',
      location: json['location'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
    );
  }
}
