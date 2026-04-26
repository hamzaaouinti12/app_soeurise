import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

/// Central API client with JWT token management.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const _tokenKey = 'jwt_token';
  String? _cachedToken;

  // ─── Token management ───

  Future<void> saveToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenKey);
    return _cachedToken;
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<bool> get isLoggedIn async => (await getToken()) != null;

  // ─── Headers ───

  Future<Map<String, String>> _headers({bool json = true}) async {
    final h = <String, String>{};
    if (json) h['Content-Type'] = 'application/json';
    final token = await getToken();
    if (token != null) h['Authorization'] = 'Bearer $token';
    return h;
  }

  // ─── HTTP methods ───

  Future<ApiResponse> get(String path) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final response = await http.get(uri, headers: await _headers());
    return _parse(response);
  }

  Future<ApiResponse> post(String path, [Map<String, dynamic>? body]) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final response = await http.post(
      uri,
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _parse(response);
  }

  Future<ApiResponse> put(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final response = await http.put(
      uri,
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _parse(response);
  }

  Future<ApiResponse> patch(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final response = await http.patch(
      uri,
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _parse(response);
  }

  Future<ApiResponse> delete(String path) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final response = await http.delete(uri, headers: await _headers());
    return _parse(response);
  }

  /// Multipart upload (for avatars / images).
  Future<ApiResponse> multipartRequest(
    String method,
    String path, {
    Map<String, String> fields = const {},
    String? fileField,
    String? filePath,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final request = http.MultipartRequest(method, uri);

    final token = await getToken();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    request.fields.addAll(fields);

    if (fileField != null && filePath != null) {
      request.files.add(await http.MultipartFile.fromPath(fileField, filePath));
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _parse(response);
  }

  /// Convenience POST multipart upload.
  Future<ApiResponse> multipartPost(
    String path, {
    Map<String, String> fields = const {},
    File? file,
    String fileField = 'file',
  }) async {
    return multipartRequest(
      'POST',
      path,
      fields: fields,
      fileField: file != null ? fileField : null,
      filePath: file?.path,
    );
  }

  // ─── Response parsing ───

  ApiResponse _parse(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      body = {'success': false, 'message': response.body};
    }
    return ApiResponse(
      statusCode: response.statusCode,
      success: body['success'] == true,
      data: body['data'],
      user: body['user'] as Map<String, dynamic>?,
      token: body['token'] as String?,
      message: body['message'] as String?,
      errors: (body['errors'] as List?)?.cast<String>(),
      raw: body,
    );
  }
}

/// Typed wrapper around a backend JSON response.
class ApiResponse {
  final int statusCode;
  final bool success;
  final dynamic data;
  final Map<String, dynamic>? user;
  final String? token;
  final String? message;
  final List<String>? errors;
  final Map<String, dynamic> raw;

  ApiResponse({
    required this.statusCode,
    required this.success,
    this.data,
    this.user,
    this.token,
    this.message,
    this.errors,
    required this.raw,
  });

  String get errorMessage =>
      errors?.join(', ') ?? message ?? 'Erreur inconnue';
}
