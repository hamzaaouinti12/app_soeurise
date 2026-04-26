import 'services/api_client.dart';
import 'models/models.dart';
import 'services/profile_service.dart';

// ─── Authentication Service ───
class AuthenticationService {
  AuthenticationService._();
  static final AuthenticationService instance = AuthenticationService._();

  final _api = ApiClient.instance;

  /// Login with email/username + password.
  /// Returns a map with 'success', optional 'user', and optional 'error'.
  Future<Map<String, dynamic>> login(String emailOrUsername, String password) async {
    try {
      final res = await _api.post('/auth/login', {
        'emailOrUsername': emailOrUsername,
        'password': password,
      });

      if (res.success && res.token != null) {
        await _api.saveToken(res.token!);
        final user = res.user != null ? User.fromJson(res.user!) : null;
        if (user != null) ProfileService.instance.setFromUser(user);
        return {'success': true, 'user': user};
      }

      return {'success': false, 'error': res.errorMessage};
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }

  /// Register a new account.
  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
    String? avatarPath,
  }) async {
    try {
      final fields = {
        'firstName': firstName,
        'lastName': lastName,
        'username': username,
        'email': email,
        'password': password,
        'passwordConfirm': passwordConfirm,
      };

      final res = await _api.multipartRequest(
        'POST',
        '/auth/register',
        fields: fields,
        fileField: avatarPath != null ? 'avatar' : null,
        filePath: avatarPath,
      );

      if (res.success && res.token != null) {
        await _api.saveToken(res.token!);
        final user = res.user != null ? User.fromJson(res.user!) : null;
        if (user != null) ProfileService.instance.setFromUser(user);
        return {'success': true, 'user': user};
      }

      return {'success': false, 'error': res.errorMessage};
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }

  /// Get the currently authenticated user.
  Future<User?> getMe() async {
    try {
      final res = await _api.get('/auth/me');
      if (res.success && res.user != null) {
        final user = User.fromJson(res.user!);
        ProfileService.instance.setFromUser(user);
        return user;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Logout — clears JWT token and resets profile.
  Future<bool> logout() async {
    try {
      await _api.clearToken();
      ProfileService.instance.logout();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Check if user is logged in (has a stored JWT token).
  Future<bool> get isLoggedIn => _api.isLoggedIn;
}

// ─── Validation Service ───
class ValidationService {
  static String? validateEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (email.isEmpty) return 'Email est requis';
    if (!emailRegex.hasMatch(email)) return 'Email invalide';
    return null;
  }

  static String? validatePassword(String password) {
    if (password.isEmpty) return 'Mot de passe est requis';
    if (password.length < 6) return 'Le mot de passe doit contenir au moins 6 caractères';
    return null;
  }

  static String? validateUsername(String username) {
    if (username.isEmpty) return 'Nom d\'utilisateur est requis';
    if (username.length < 3) return 'Le nom d\'utilisateur doit contenir au moins 3 caractères';
    return null;
  }

  static String? validateName(String name) {
    if (name.isEmpty) return 'Ce champ est requis';
    if (name.length < 2) return 'Minimum 2 caractères';
    return null;
  }

  static String? validatePostContent(String content) {
    if (content.isEmpty) return 'La publication ne peut pas être vide';
    if (content.length > 5000) return 'La publication doit contenir moins de 5000 caractères';
    return null;
  }
}

// ─── Notification Service ───
class NotificationService {
  static void showSuccessMessage(dynamic context, String message) {}
  static void showErrorMessage(dynamic context, String message) {}
  static void showInfoMessage(dynamic context, String message) {}
}
