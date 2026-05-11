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
  final bool isFollowing;
  final bool isBlocked;

  /// Compte privé : demande d'abonnement au lieu de suivre directement.
  final String accountPrivacy;

  /// Demande envoyée (en attente d'acceptation par le compte privé).
  final bool followRequestSent;

  /// false si profil privé et viewer non abonné (données limitées côté API).
  final bool canViewContent;
  final int pendingIncomingFollowRequestsCount;
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
    this.isFollowing = false,
    this.isBlocked = false,
    this.accountPrivacy = 'public',
    this.followRequestSent = false,
    this.canViewContent = true,
    this.pendingIncomingFollowRequestsCount = 0,
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
      isFollowing: json['isFollowing'] ?? false,
      isBlocked: json['isBlocked'] ?? false,
      accountPrivacy: json['accountPrivacy']?.toString() ?? 'public',
      followRequestSent: json['followRequestSent'] == true,
      canViewContent: json['canViewContent'] != false,
      pendingIncomingFollowRequestsCount:
          json['pendingIncomingFollowRequestsCount'] ??
          json['pendingFollowRequestCount'] ??
          0,
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'])
              : null,
    );
  }

  String get fullName => '$firstName $lastName';
  String get avatarFullUrl => ApiConfig.uploadsUrl(avatarUrl);
}

class Story {
  final String id;
  final String authorId;
  final String username;
  final String profileImageUrl;
  final String mediaUrl;
  final String mediaType;
  final String caption;
  final DateTime expiresAt;
  final int viewsCount;
  final Map<String, int> reactionCounts;
  final bool isViewed;

  Story({
    required this.id,
    required this.authorId,
    required this.username,
    required this.profileImageUrl,
    required this.mediaUrl,
    required this.mediaType,
    this.caption = '',
    required this.expiresAt,
    this.viewsCount = 0,
    this.reactionCounts = const {},
    this.isViewed = false,
  });

  bool get isVideo => mediaType == 'video';

  factory Story.fromJson(Map<String, dynamic> json) {
    final author = json['author'] ?? {};
    final fName = author['firstName'] ?? '';
    final lName = author['lastName'] ?? '';
    final uName = author['username'] ?? '';
    final avatar = author['avatarUrl'] ?? '';
    final authorId =
        author['id']?.toString() ?? author['_id']?.toString() ?? '';
    final name = fName.isNotEmpty ? '$fName $lName' : uName;

    final reactionData = json['reactionCounts'] as Map<String, dynamic>? ?? {};
    final reactionCounts = reactionData.map((key, value) {
      return MapEntry(
        key.toString(),
        (value is int ? value : int.tryParse(value.toString()) ?? 0),
      );
    });

    return Story(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      authorId: authorId,
      username: name.isNotEmpty ? name : 'Utilisateur',
      profileImageUrl: ApiConfig.uploadsUrl(avatar),
      mediaUrl: ApiConfig.uploadsUrl(json['mediaUrl'] ?? ''),
      mediaType: json['mediaType']?.toString() ?? 'image',
      caption: json['caption']?.toString() ?? '',
      expiresAt:
          json['expiresAt'] != null
              ? DateTime.tryParse(json['expiresAt'].toString()) ??
                  DateTime.now()
              : DateTime.now(),
      viewsCount:
          json['viewsCount'] ?? (json['views'] as List<dynamic>?)?.length ?? 0,
      reactionCounts: reactionCounts,
      isViewed: json['isViewed'] == true || json['viewed'] == true || json['hasViewed'] == true,
    );
  }
}

class StoryViewer {
  final String id;
  final String username;
  final String fullName;
  final String avatarUrl;
  final DateTime? viewedAt;

  StoryViewer({
    required this.id,
    required this.username,
    required this.fullName,
    required this.avatarUrl,
    this.viewedAt,
  });

  String get displayName => fullName.isNotEmpty ? fullName : username;
  String get avatarFullUrl => ApiConfig.uploadsUrl(avatarUrl);

  factory StoryViewer.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final source = user ?? json;
    final fName = source['firstName']?.toString() ?? '';
    final lName = source['lastName']?.toString() ?? '';
    final uName = source['username']?.toString() ?? '';
    final name = ('$fName $lName').trim();

    return StoryViewer(
      id: source['id']?.toString() ?? source['_id']?.toString() ?? '',
      username: uName,
      fullName: name,
      avatarUrl: source['avatarUrl']?.toString() ?? '',
      viewedAt:
          json['viewedAt'] != null
              ? DateTime.tryParse(json['viewedAt'].toString())
              : null,
    );
  }
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
  bool isSaved;
  bool commentsDisabled;
  bool isPinned;

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
    this.isSaved = false,
    this.commentsDisabled = false,
    this.isPinned = false,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final author = json['author'] ?? {};
    final fName = author['firstName'] ?? '';
    final lName = author['lastName'] ?? '';
    final uName = author['username'] ?? '';
    final avatar = author['avatarUrl'] ?? '';
    final authorId =
        author['id']?.toString() ?? author['_id']?.toString() ?? '';

    final name = fName.isNotEmpty ? '$fName $lName' : uName;

    return Post(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      authorId: authorId,
      username: name.isNotEmpty ? name : 'Utilisateur',
      profileImageUrl: ApiConfig.uploadsUrl(avatar),
      content: json['content'] ?? '',
      imageUrl:
          json['image'] != null && json['image'].toString().isNotEmpty
              ? ApiConfig.uploadsUrl(json['image'])
              : null,
      timestamp:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
              : DateTime.now(),
      likes: json['likesCount'] ?? 0,
      comments: json['commentsCount'] ?? 0,
      shares: json['sharesCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      isSaved: json['isSaved'] ?? false,
      commentsDisabled: json['commentsDisabled'] ?? false,
      isPinned: json['isPinned'] ?? false,
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
  final String? replyToId;
  int likesCount;
  bool isLiked;
  bool isHidden;
  bool isPinned;
  List<Comment> replies;

  Comment({
    required this.id,
    this.authorId = '',
    required this.authorName,
    this.authorAvatar = '',
    required this.content,
    required this.createdAt,
    this.replyToId,
    this.likesCount = 0,
    this.isLiked = false,
    this.isHidden = false,
    this.isPinned = false,
    this.replies = const [],
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final author = json['author'] ?? {};
    final fName = author['firstName'] ?? '';
    final lName = author['lastName'] ?? '';
    final uName = author['username'] ?? '';
    final avatar = author['avatarUrl'] ?? '';
    final authorId =
        author['id']?.toString() ?? author['_id']?.toString() ?? '';

    final name = fName.isNotEmpty ? '$fName $lName' : uName;
    final likes = json['likes'] as List<dynamic>? ?? [];

    final repliesJson = json['replies'] as List<dynamic>? ?? [];

    return Comment(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      authorId: authorId,
      authorName: name.isNotEmpty ? name : 'Utilisateur',
      authorAvatar: ApiConfig.uploadsUrl(avatar),
      content: json['content'] ?? '',
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
              : DateTime.now(),
      replyToId: json['replyTo']?.toString(),
      likesCount: json['likesCount'] ?? likes.length,
      isLiked: json['isLiked'] ?? false,
      isHidden: json['isHidden'] ?? false,
      isPinned: json['isPinned'] ?? false,
      replies: repliesJson.map((r) => Comment.fromJson(r)).toList(),
    );
  }
}

class PrivateMessage {
  final String id;
  final String senderId;
  final String recipientId;
  final String type; // text | image | audio
  final String text;
  final String mediaUrl;
  final String mediaMime;
  final int? audioDurationMs;
  final bool isRead;
  final bool deletedForAll;
  final DateTime createdAt;

  PrivateMessage({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.type,
    required this.text,
    required this.mediaUrl,
    required this.mediaMime,
    required this.audioDurationMs,
    required this.isRead,
    required this.deletedForAll,
    required this.createdAt,
  });

  bool get hasMedia => mediaUrl.isNotEmpty;
  bool get isDeleted => deletedForAll;

  PrivateMessage copyWith({
    String? text,
    String? mediaUrl,
    bool? isRead,
    bool? deletedForAll,
  }) {
    return PrivateMessage(
      id: id,
      senderId: senderId,
      recipientId: recipientId,
      type: type,
      text: text ?? this.text,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaMime: mediaMime,
      audioDurationMs: audioDurationMs,
      isRead: isRead ?? this.isRead,
      deletedForAll: deletedForAll ?? this.deletedForAll,
      createdAt: createdAt,
    );
  }

  factory PrivateMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'];
    final recipient = json['recipient'];
    final senderId =
        json['senderId']?.toString() ?? sender?['id']?.toString() ?? sender?['_id']?.toString() ?? '';
    final recipientId =
        json['recipientId']?.toString() ?? recipient?['id']?.toString() ?? recipient?['_id']?.toString() ?? '';

    final rawMedia = json['mediaUrl']?.toString() ?? '';
    return PrivateMessage(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      senderId: senderId,
      recipientId: recipientId,
      type: json['type']?.toString() ?? 'text',
      text: json['text']?.toString() ?? '',
      mediaUrl: rawMedia.isNotEmpty ? ApiConfig.uploadsUrl(rawMedia) : '',
      mediaMime: json['mediaMime']?.toString() ?? '',
      audioDurationMs: json['audioDurationMs'] is int
          ? json['audioDurationMs'] as int
          : int.tryParse(json['audioDurationMs']?.toString() ?? ''),
      isRead: json['isRead'] == true,
      deletedForAll: json['deletedForAll'] == true,
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
              : DateTime.now(),
    );
  }
}

class Conversation {
  final User user;
  final PrivateMessage lastMessage;
  final int unreadCount;

  Conversation({
    required this.user,
    required this.lastMessage,
    required this.unreadCount,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      lastMessage: PrivateMessage.fromJson(
        json['lastMessage'] as Map<String, dynamic>,
      ),
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}

class HashtagResult {
  final String tag;
  final int count;

  HashtagResult({required this.tag, required this.count});

  factory HashtagResult.fromJson(Map<String, dynamic> json) {
    return HashtagResult(
      tag: json['tag']?.toString() ?? '',
      count: json['count'] ?? 0,
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
      createdDate:
          json['createdAt'] != null
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
      dateTime:
          json['dateTime'] != null
              ? DateTime.tryParse(json['dateTime']) ?? DateTime.now()
              : DateTime.now(),
      type: json['type'] ?? 'online',
      location: json['location'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
    );
  }
}
