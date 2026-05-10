import 'dart:io';
import 'package:flutter/foundation.dart';
import '../constants.dart';
import '../models/models.dart';
import 'api_client.dart';
import 'socket_service.dart';
import 'notification_service.dart';

class Profile {
  String id;
  String firstName;
  String lastName;
  String username;
  String email;
  String bio;
  String profileImageUrl; // full URL or empty
  File? profileImageFile;
  String accountType;
  int eventsRegistered;
  int masterclassesWatched;
  int communitiesJoined;
  int followersCount;
  int followingCount;
  /// public | private
  String accountPrivacy;
  int cacheVersion; // Used to force refresh avatar cache (public for access)

  Profile({
    this.id = '',
    this.firstName = '',
    this.lastName = '',
    required this.username,
    required this.email,
    this.bio = '',
    this.profileImageUrl = '',
    this.accountType = 'user',
    this.profileImageFile,
    this.eventsRegistered = 0,
    this.masterclassesWatched = 0,
    this.communitiesJoined = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.accountPrivacy = 'public',
    this.cacheVersion = 0,
  });

  bool get isPrivateAccount => accountPrivacy == 'private';

  /// Returns the profile image URL with cache-busting parameter.
  String get profileImageUrlWithCache {
    if (profileImageUrl.isEmpty) return '';
    final separator = profileImageUrl.contains('?') ? '&' : '?';
    return '$profileImageUrl${separator}v=$cacheVersion';
  }

  String get fullName {
    if (firstName.isEmpty && lastName.isEmpty) return username;
    return '$firstName $lastName'.trim();
  }
}

class ProfileService {
  ProfileService._privateConstructor();
  static final ProfileService instance = ProfileService._privateConstructor();

  final _api = ApiClient.instance;

  final ValueNotifier<Profile> profile = ValueNotifier(
    Profile(username: 'Invité', email: '', bio: ''),
  );
  final ValueNotifier<Map<String, bool>> followStates = ValueNotifier({});
  final ValueNotifier<Map<String, bool>> followRequestSentStates = ValueNotifier({});
  final ValueNotifier<int> pendingFollowRequestsCount = ValueNotifier(0);

  /// Populate profile from a backend User model (called after login/register).
  void setFromUser(User user) {
    final p = profile.value;
    p.firstName = user.firstName;
    p.lastName = user.lastName;
    p.username = user.username;
    p.email = user.email;
    p.profileImageUrl = user.avatarFullUrl;
    p.accountType = user.role;
    // Re-assign to trigger listeners + increment cache version
    profile.value = Profile(
      id: user.id,
      firstName: user.firstName,
      lastName: user.lastName,
      username: user.username,
      email: user.email,
      bio: p.bio,
      profileImageUrl: user.avatarFullUrl,
      accountType: user.role,
      eventsRegistered: p.eventsRegistered,
      masterclassesWatched: p.masterclassesWatched,
      communitiesJoined: p.communitiesJoined,
      followersCount: user.followersCount,
      followingCount: user.followingCount,
      accountPrivacy: user.accountPrivacy,
      cacheVersion: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<bool> refreshProfile() => loadProfile();

  /// Fetch profile from backend.
  Future<bool> loadProfile() async {
    try {
      final res = await _api.get('/users/me');
      if (res.success && res.data != null) {
        final user = User.fromJson(res.data!['user'] ?? res.data!);
        setFromUser(user);
        // Load pending follow requests count for private accounts
        if (user.accountPrivacy == 'private') {
          await loadPendingFollowRequestsCount();
        }
        return true;
      } else if (res.success && res.user != null) {
        final user = User.fromJson(res.user!);
        setFromUser(user);
        // Load pending follow requests count for private accounts
        if (user.accountPrivacy == 'private') {
          await loadPendingFollowRequestsCount();
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Update profile on the backend.
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    String? accountPrivacy,
  }) async {
    try {
      final p = profile.value;
      final body = <String, dynamic>{};
      // Always send all required fields (backend requires all)
      body['firstName'] = firstName ?? p.firstName;
      body['lastName'] = lastName ?? p.lastName;
      body['username'] = username ?? p.username;
      body['email'] = email ?? p.email;
      if (accountPrivacy != null) body['accountPrivacy'] = accountPrivacy;

      final res = await _api.put('/users/me', body);
      if (res.success) {
        final userMap =
            res.data?['user'] as Map<String, dynamic>? ??
            res.raw['data']?['user'] as Map<String, dynamic>?;
        if (userMap != null) {
          setFromUser(User.fromJson(userMap));
        } else {
          profile.value = Profile(
            id: p.id,
            firstName: body['firstName'] as String,
            lastName: body['lastName'] as String,
            username: body['username'] as String,
            email: body['email'] as String,
            bio: p.bio,
            profileImageUrl: p.profileImageUrl,
            profileImageFile: p.profileImageFile,
            accountType: p.accountType,
            eventsRegistered: p.eventsRegistered,
            masterclassesWatched: p.masterclassesWatched,
            communitiesJoined: p.communitiesJoined,
            followersCount: p.followersCount,
            followingCount: p.followingCount,
            accountPrivacy: accountPrivacy ?? p.accountPrivacy,
            cacheVersion: p.cacheVersion,
          );
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Upload a new avatar - returns (success, errorMessage)
  Future<(bool, String?)> updateAvatarWithError(String filePath) async {
    try {
      final res = await _api.multipartRequest(
        'PUT',
        '/users/me/avatar',
        fileField: 'avatar',
        filePath: filePath,
      );
      if (res.success) {
        // Get the new avatar URL directly from the response
        final userData =
            res.data?['user'] as Map<String, dynamic>? ??
            res.raw['data']?['user'] as Map<String, dynamic>? ??
            {};
        final newAvatarUrl = userData['avatarUrl']?.toString() ?? '';
        final normalizedAvatarUrl = ApiConfig.uploadsUrl(newAvatarUrl);

        // Update profile immediately with new URL without triggering loadProfile
        // (avoids Hero widget stack overflow during navigation)
        final p = profile.value;
        profile.value = Profile(
          id: p.id,
          firstName: p.firstName,
          lastName: p.lastName,
          username: p.username,
          email: p.email,
          bio: p.bio,
          profileImageUrl:
              normalizedAvatarUrl.isNotEmpty
                  ? normalizedAvatarUrl
                  : p.profileImageUrl,
          profileImageFile: null,
          accountType: p.accountType,
          eventsRegistered: p.eventsRegistered,
          masterclassesWatched: p.masterclassesWatched,
          communitiesJoined: p.communitiesJoined,
          followersCount: p.followersCount,
          followingCount: p.followingCount,
          accountPrivacy: p.accountPrivacy,
          cacheVersion: DateTime.now().millisecondsSinceEpoch,
        );
        return (true, null);
      }
      final errorMsg = res.errorMessage;
      print('Upload failed: $errorMsg');
      print('Raw response: ${res.raw}');
      return (false, errorMsg);
    } catch (e) {
      print('Exception during avatar upload: $e');
      return (false, 'Erreur réseau: $e');
    }
  }

  /// Upload a new avatar - legacy method for backwards compatibility
  Future<bool> updateAvatar(String filePath) async {
    final (success, _) = await updateAvatarWithError(filePath);
    return success;
  }

  /// Delete avatar.
  Future<bool> deleteAvatar() async {
    try {
      final res = await _api.delete('/users/me/avatar');
      if (res.success) {
        final p = profile.value;
        // Create new object to trigger ValueNotifier listeners
        profile.value = Profile(
          firstName: p.firstName,
          lastName: p.lastName,
          username: p.username,
          email: p.email,
          bio: p.bio,
          profileImageUrl: '',
          profileImageFile: null,
          accountType: p.accountType,
          eventsRegistered: p.eventsRegistered,
          masterclassesWatched: p.masterclassesWatched,
          communitiesJoined: p.communitiesJoined,
          followersCount: p.followersCount,
          followingCount: p.followingCount,
          accountPrivacy: p.accountPrivacy,
          cacheVersion: DateTime.now().millisecondsSinceEpoch,
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void incrementEventRegistered() {
    final p = profile.value;
    profile.value = Profile(
      id: p.id,
      firstName: p.firstName,
      lastName: p.lastName,
      username: p.username,
      email: p.email,
      bio: p.bio,
      profileImageUrl: p.profileImageUrl,
      profileImageFile: p.profileImageFile,
      accountType: p.accountType,
      eventsRegistered: p.eventsRegistered + 1,
      masterclassesWatched: p.masterclassesWatched,
      communitiesJoined: p.communitiesJoined,
      followersCount: p.followersCount,
      followingCount: p.followingCount,
      accountPrivacy: p.accountPrivacy,
      cacheVersion: p.cacheVersion,
    );
  }

  void incrementMasterclassWatched() {
    final p = profile.value;
    profile.value = Profile(
      id: p.id,
      firstName: p.firstName,
      lastName: p.lastName,
      username: p.username,
      email: p.email,
      bio: p.bio,
      profileImageUrl: p.profileImageUrl,
      profileImageFile: p.profileImageFile,
      accountType: p.accountType,
      eventsRegistered: p.eventsRegistered,
      masterclassesWatched: p.masterclassesWatched + 1,
      communitiesJoined: p.communitiesJoined,
      followersCount: p.followersCount,
      followingCount: p.followingCount,
      accountPrivacy: p.accountPrivacy,
      cacheVersion: p.cacheVersion,
    );
  }

  /// Fetch another user's public profile.
  Future<User?> fetchUserProfile(String userId) async {
    try {
      final res = await _api.get('/users/$userId');
      if (res.success && res.data != null) {
        final user = User.fromJson(res.data!['user'] ?? res.data!);
        _setFollowState(user.id, user.isFollowing);
        _setFollowRequestSentState(user.id, user.followRequestSent);
        return user;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  bool? getFollowState(String userId) => followStates.value[userId];

  bool getFollowRequestSent(String userId) =>
      followRequestSentStates.value[userId] ?? false;

  void _setFollowState(String userId, bool isFollowing) {
    final next = Map<String, bool>.from(followStates.value);
    next[userId] = isFollowing;
    followStates.value = next;
  }

  void _setFollowRequestSentState(String userId, bool sent) {
    final next = Map<String, bool>.from(followRequestSentStates.value);
    next[userId] = sent;
    followRequestSentStates.value = next;
  }

  /// Toggle follow/unfollow state for a user and return latest counters.
  Future<FollowToggleResult?> toggleFollowUser(String userId) async {
    try {
      final res = await _api.post('/users/$userId/follow', {});
      if (!res.success || res.data == null) return null;
      final payload = res.data as Map<String, dynamic>;
      final isFollowing = payload['isFollowing'] == true;
      final followRequestSent = payload['followRequestSent'] == true;
      _setFollowState(userId, isFollowing);
      _setFollowRequestSentState(userId, followRequestSent);
      final p = profile.value;
      profile.value = Profile(
        id: p.id,
        firstName: p.firstName,
        lastName: p.lastName,
        username: p.username,
        email: p.email,
        bio: p.bio,
        profileImageUrl: p.profileImageUrl,
        profileImageFile: p.profileImageFile,
        accountType: p.accountType,
        eventsRegistered: p.eventsRegistered,
        masterclassesWatched: p.masterclassesWatched,
        communitiesJoined: p.communitiesJoined,
        followersCount: p.followersCount,
        followingCount: payload['followingCount'] ?? p.followingCount,
        accountPrivacy: p.accountPrivacy,
        cacheVersion: p.cacheVersion,
      );

      return FollowToggleResult(
        userId: payload['userId']?.toString() ?? userId,
        isFollowing: isFollowing,
        followRequestSent: followRequestSent,
        followersCount: payload['followersCount'] ?? 0,
        followingCount: payload['followingCount'] ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  /// Reset profile to default (used on logout).
  Future<void> logout() async {
    // 1. Clear local state
    profile.value = Profile(
      id: '',
      username: 'Invité',
      email: '',
      bio: '',
      profileImageUrl: '',
      profileImageFile: null,
      eventsRegistered: 0,
      masterclassesWatched: 0,
      communitiesJoined: 0,
      followersCount: 0,
      followingCount: 0,
      accountType: 'user',
      accountPrivacy: 'public',
      cacheVersion: DateTime.now().millisecondsSinceEpoch,
    );
    followStates.value = {};
    followRequestSentStates.value = {};
    pendingFollowRequestsCount.value = 0;

    // 2. Clear API token
    await _api.clearToken();

    // 3. Disconnect Socket
    SocketService().disconnect();

    // 4. Reset Notification count
    NotificationService.instance.unreadCount.value = 0;
  }

  /// Demandes reçues (compte privé).
  Future<List<User>> fetchIncomingFollowRequests() async {
    try {
      final res = await _api.get('/users/me/follow-requests');
      if (!res.success || res.data == null) return [];
      final list = res.data!['requests'] as List? ?? [];
      final requests = list.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
      // Update pending count
      pendingFollowRequestsCount.value = requests.length;
      return requests;
    } catch (_) {
      return [];
    }
  }

  /// Load pending follow requests count without fetching the full list.
  Future<void> loadPendingFollowRequestsCount() async {
    try {
      final res = await _api.get('/users/me/follow-requests?limit=1');
      if (res.success && res.data != null) {
        final total = res.data!['total'] as int? ?? 0;
        pendingFollowRequestsCount.value = total;
      }
    } catch (_) {
      // Silent fail
    }
  }

  /// Fetch list of followers for current user.
  Future<List<User>> fetchMyFollowers({int page = 1, int limit = 20}) async {
    try {
      final res = await _api.get('/users/me/followers?page=$page&limit=$limit');
      if (!res.success || res.data == null) return [];
      final list = res.data!['followers'] as List? ?? res.data as List? ?? [];
      return list.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetch list of followers for another user.
  Future<List<User>> fetchUserFollowers(String userId, {int page = 1, int limit = 20}) async {
    try {
      final res = await _api.get('/users/$userId/followers?page=$page&limit=$limit');
      if (!res.success || res.data == null) return [];
      final list = res.data!['followers'] as List? ?? res.data as List? ?? [];
      return list.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> acceptFollowRequest(String requesterUserId) async {
    try {
      final res = await _api.post(
        '/users/me/follow-requests/$requesterUserId/accept',
      );
      if (res.success) await loadProfile();
      return res.success;
    } catch (_) {
      return false;
    }
  }

  Future<bool> declineFollowRequest(String requesterUserId) async {
    try {
      final res = await _api.post(
        '/users/me/follow-requests/$requesterUserId/decline',
      );
      if (res.success) await loadProfile();
      return res.success;
    } catch (_) {
      return false;
    }
  }

  Future<bool> blockUser(String userId) async {
    try {
      final res = await _api.post('/users/$userId/block', {});
      if (res.success) {
        await loadProfile();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> unblockUser(String userId) async {
    try {
      final res = await _api.post('/users/$userId/unblock', {});
      if (res.success) {
        await loadProfile();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<List<User>> searchUsers(String query) async {
    if (query.length < 2) return [];
    try {
      final res = await _api.get('/users/search-users?q=$query');
      if (res.success && res.data != null) {
        final list = res.data!['users'] as List? ?? [];
        return list.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<User>> fetchBlockedUsers() async {
    try {
      final res = await _api.get('/users/me/blocked');
      print('Fetch blocked users response: ${res.success}, ${res.data}');
      if (res.success && res.data != null) {
        final list = res.data!['users'] as List? ?? [];
        print('Blocked users list length: ${list.length}');
        return list
            .map((e) => User.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching blocked users: $e');
      return [];
    }
  }
}

class FollowToggleResult {
  final String userId;
  final bool isFollowing;
  final bool followRequestSent;
  final int followersCount;
  final int followingCount;

  FollowToggleResult({
    required this.userId,
    required this.isFollowing,
    required this.followRequestSent,
    required this.followersCount,
    required this.followingCount,
  });
}
