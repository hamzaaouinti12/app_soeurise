import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'api_client.dart';

class Profile {
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

  Profile({
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
  });

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

  /// Populate profile from a backend User model (called after login/register).
  void setFromUser(User user) {
    final p = profile.value;
    p.firstName = user.firstName;
    p.lastName = user.lastName;
    p.username = user.username;
    p.email = user.email;
    p.profileImageUrl = user.avatarFullUrl;
    p.accountType = user.role;
    // Re-assign to trigger listeners
    profile.value = Profile(
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
    );
  }

  /// Fetch profile from backend.
  Future<bool> loadProfile() async {
    try {
      final res = await _api.get('/users/me');
      if (res.success && res.data != null) {
        final user = User.fromJson(res.data!['user'] ?? res.data!);
        setFromUser(user);
        return true;
      } else if (res.success && res.user != null) {
        final user = User.fromJson(res.user!);
        setFromUser(user);
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
  }) async {
    try {
      final body = <String, dynamic>{};
      if (firstName != null) body['firstName'] = firstName;
      if (lastName != null) body['lastName'] = lastName;
      if (username != null) body['username'] = username;
      if (email != null) body['email'] = email;

      final res = await _api.put('/users/me', body);
      if (res.success) {
        // Update local profile
        final p = profile.value;
        if (firstName != null) p.firstName = firstName;
        if (lastName != null) p.lastName = lastName;
        if (username != null) p.username = username;
        if (email != null) p.email = email;
        profile.value = p;
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Upload a new avatar.
  Future<bool> updateAvatar(String filePath) async {
    try {
      final res = await _api.multipartRequest(
        'PUT',
        '/users/me/avatar',
        fileField: 'avatar',
        filePath: filePath,
      );
      if (res.success) {
        await loadProfile(); // Refresh to get new avatar URL
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Delete avatar.
  Future<bool> deleteAvatar() async {
    try {
      final res = await _api.delete('/users/me/avatar');
      if (res.success) {
        final p = profile.value;
        p.profileImageUrl = '';
        p.profileImageFile = null;
        profile.value = p;
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void incrementEventRegistered() {
    final p = profile.value;
    p.eventsRegistered += 1;
    profile.value = p;
  }

  void incrementMasterclassWatched() {
    final p = profile.value;
    p.masterclassesWatched += 1;
    profile.value = p;
  }

  /// Reset profile to default (used on logout).
  void logout() {
    profile.value = Profile(
      username: 'Invité',
      email: '',
      bio: '',
      profileImageUrl: '',
      profileImageFile: null,
      eventsRegistered: 0,
      masterclassesWatched: 0,
      communitiesJoined: 0,
      accountType: 'user',
    );
  }
}
