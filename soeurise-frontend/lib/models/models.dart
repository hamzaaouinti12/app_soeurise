import 'dart:io' if (dart.library.html) 'package:soeurise/src/file_stub.dart';
import '../constants.dart';

/// Helper for robust JSON parsing
class SafeParse {
  static String asString(dynamic v, [String defaultValue = '']) {
    if (v == null) return defaultValue;
    return v.toString();
  }

  static int asInt(dynamic v, [int defaultValue = 0]) {
    if (v == null) return defaultValue;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? defaultValue;
    return defaultValue;
  }

  static bool asBool(dynamic v, [bool defaultValue = false]) {
    if (v == null) return defaultValue;
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    if (v is int) return v != 0;
    return defaultValue;
  }

  static DateTime asDateTime(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    final s = v.toString();
    final dt = DateTime.tryParse(s);
    if (dt != null) return dt;
    
    // Try timestamp
    final ts = asInt(v, -1);
    if (ts != -1) {
      if (ts > 10000000000) { // Likely milliseconds
        return DateTime.fromMillisecondsSinceEpoch(ts);
      } else { // Likely seconds
        return DateTime.fromMillisecondsSinceEpoch(ts * 1000);
      }
    }
    return DateTime.now();
  }

  static List<T> asList<T>(dynamic v, T Function(dynamic) mapper) {
    if (v is! List) return [];
    return v.map((e) {
      try {
        return mapper(e);
      } catch (e) {
        print('Error parsing list item: $e');
        return null;
      }
    }).where((e) => e != null).cast<T>().toList();
  }
  
  static Map<String, dynamic> asMap(dynamic v) {
    if (v is Map) {
      return Map<String, dynamic>.from(v);
    }
    return {};
  }
}

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
      id: SafeParse.asString(json['id'] ?? json['_id']),
      firstName: SafeParse.asString(json['firstName']),
      lastName: SafeParse.asString(json['lastName']),
      username: SafeParse.asString(json['username']),
      email: SafeParse.asString(json['email']),
      avatarUrl: SafeParse.asString(json['avatarUrl']),
      role: SafeParse.asString(json['role'], 'user'),
      isActive: SafeParse.asBool(json['isActive'], true),
      followingCount: SafeParse.asInt(json['followingCount']),
      followersCount: SafeParse.asInt(json['followersCount']),
      isFollowing: SafeParse.asBool(json['isFollowing']),
      isBlocked: SafeParse.asBool(json['isBlocked']),
      accountPrivacy: SafeParse.asString(json['accountPrivacy'], 'public'),
      followRequestSent: SafeParse.asBool(json['followRequestSent']),
      canViewContent: SafeParse.asBool(json['canViewContent'], true),
      pendingIncomingFollowRequestsCount: SafeParse.asInt(
          json['pendingIncomingFollowRequestsCount'] ??
              json['pendingFollowRequestCount']),
      createdAt: json['createdAt'] != null ? SafeParse.asDateTime(json['createdAt']) : null,
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
  final PrivateMessage? replyTo;
  final String senderName;
  final bool isEdited;
  final DateTime? editedAt;
  final List<Map<String, dynamic>> reactions;
  final String? storyImageUrl;

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
    this.replyTo,
    this.senderName = '',
    this.isEdited = false,
    this.editedAt,
    this.reactions = const [],
    this.storyImageUrl,
  });

  bool get hasMedia => mediaUrl.isNotEmpty;
  bool get isDeleted => deletedForAll;

  PrivateMessage copyWith({
    String? text,
    String? mediaUrl,
    bool? isRead,
    bool? deletedForAll,
    PrivateMessage? replyTo,
    String? senderName,
    bool? isEdited,
    DateTime? editedAt,
    List<Map<String, dynamic>>? reactions,
    String? storyImageUrl,
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
      replyTo: replyTo ?? this.replyTo,
      senderName: senderName ?? this.senderName,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      reactions: reactions ?? this.reactions,
      storyImageUrl: storyImageUrl ?? this.storyImageUrl,
    );
  }

  factory PrivateMessage.fromJson(Map<String, dynamic> json) {
    final sender = SafeParse.asMap(json['sender']);
    final recipient = SafeParse.asMap(json['recipient']);
    final senderId = SafeParse.asString(json['senderId'] ?? sender['id'] ?? sender['_id']);
    final recipientId = SafeParse.asString(json['recipientId'] ?? recipient['id'] ?? recipient['_id']);

    final rawMedia = SafeParse.asString(json['mediaUrl']);
    return PrivateMessage(
      id: SafeParse.asString(json['id'] ?? json['_id']),
      senderId: senderId,
      recipientId: recipientId,
      type: SafeParse.asString(json['type'], 'text'),
      text: SafeParse.asString(json['text']),
      mediaUrl: rawMedia.isNotEmpty ? ApiConfig.uploadsUrl(rawMedia) : '',
      mediaMime: SafeParse.asString(json['mediaMime']),
      audioDurationMs: json['audioDurationMs'] != null ? SafeParse.asInt(json['audioDurationMs']) : null,
      isRead: SafeParse.asBool(json['isRead']),
      deletedForAll: SafeParse.asBool(json['deletedForAll']),
      replyTo: (json['replyTo'] != null && json['replyTo'] is Map)
          ? PrivateMessage.fromJson(SafeParse.asMap(json['replyTo']))
          : null,
      senderName: SafeParse.asString(sender['username']),
      isEdited: SafeParse.asBool(json['isEdited']),
      editedAt: json['editedAt'] != null ? SafeParse.asDateTime(json['editedAt']) : null,
      reactions: SafeParse.asList(json['reactions'], (e) => SafeParse.asMap(e)),
      storyImageUrl: json['storyImageUrl'] != null ? ApiConfig.uploadsUrl(SafeParse.asString(json['storyImageUrl'])) : null,
      createdAt: SafeParse.asDateTime(json['createdAt'] ?? json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'recipientId': recipientId,
        'type': type,
        'text': text,
        'mediaUrl': mediaUrl,
        'mediaMime': mediaMime,
        'audioDurationMs': audioDurationMs,
        'isRead': isRead,
        'deletedForAll': deletedForAll,
        'replyTo': replyTo?.toJson(),
        'senderName': senderName,
        'isEdited': isEdited,
        'editedAt': editedAt?.toIso8601String(),
        'reactions': reactions,
        'storyImageUrl': storyImageUrl,
        'createdAt': createdAt.toIso8601String(),
      };
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
      user: User.fromJson(SafeParse.asMap(json['user'])),
      lastMessage: PrivateMessage.fromJson(SafeParse.asMap(json['lastMessage'])),
      unreadCount: SafeParse.asInt(json['unreadCount']),
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
  final String createdBy;

  Community({
    required this.id,
    required this.name,
    required this.description,
    required this.members,
    required this.imageUrl,
    this.isPublic = true,
    this.requiresSubscription = false,
    this.createdBy = '',
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: SafeParse.asString(json['id'] ?? json['_id']),
      name: SafeParse.asString(json['name']),
      description: SafeParse.asString(json['description']),
      members: SafeParse.asInt(json['memberCount']),
      imageUrl: ApiConfig.uploadsUrl(SafeParse.asString(json['imageUrl'])),
      isPublic: SafeParse.asBool(json['isPublic'], true),
      requiresSubscription: SafeParse.asBool(json['requiresSubscription']),
      createdBy: SafeParse.asString(json['createdBy']),
    );
  }
}

/// Member of a community group
class GroupMember {
  final String id;         // GroupMember document id
  final String userId;
  final String firstName;
  final String lastName;
  final String username;
  final String avatarUrl;
  final String roleInGroup; // owner | moderator | member
  final String status;      // active | banned
  final DateTime? joinedAt;

  GroupMember({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.avatarUrl,
    required this.roleInGroup,
    required this.status,
    this.joinedAt,
  });

  String get fullName {
    final n = '$firstName $lastName'.trim();
    return n.isNotEmpty ? n : username;
  }

  String get avatarFullUrl => ApiConfig.uploadsUrl(avatarUrl);

  bool get isOwner => roleInGroup == 'owner';
  bool get isModerator => roleInGroup == 'moderator';
  bool get isAdmin => isOwner || isModerator;

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: SafeParse.asString(json['id'] ?? json['_id']),
      userId: SafeParse.asString(json['userId']),
      firstName: SafeParse.asString(json['firstName']),
      lastName: SafeParse.asString(json['lastName']),
      username: SafeParse.asString(json['username']),
      avatarUrl: SafeParse.asString(json['avatarUrl']),
      roleInGroup: SafeParse.asString(json['roleInGroup'], 'member'),
      status: SafeParse.asString(json['status'], 'active'),
      joinedAt: json['joinedAt'] != null
          ? SafeParse.asDateTime(json['joinedAt'])
          : null,
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
