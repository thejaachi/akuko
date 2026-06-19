import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:akuko/core/api/token_storage.dart';
import 'package:akuko/core/config/api_config.dart';
import 'package:akuko/core/error/exceptions.dart';

typedef UnauthorizedCallback = Future<void> Function();

/// HTTP client for the WordPress Akuko Mobile API.
class AkukoApiClient {
  AkukoApiClient({
    required this.tokenStorage,
    this.onUnauthorized,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final TokenStorage tokenStorage;
  final UnauthorizedCallback? onUnauthorized;
  final http.Client _http;

  bool _isRefreshing = false;

  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParams,
    bool auth = false,
  }) =>
      _request('GET', path, queryParams: queryParams, auth: auth);

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) =>
      _request('POST', path, body: body, auth: auth);

  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) =>
      _request('PUT', path, body: body, auth: auth);

  Future<dynamic> delete(
    String path, {
    Map<String, String>? queryParams,
    bool auth = true,
  }) =>
      _request('DELETE', path, queryParams: queryParams, auth: auth);

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool auth = false,
    bool isRetry = false,
  }) async {
    final uri = _buildUri(path, queryParams);
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (auth) {
      final token = tokenStorage.accessToken;
      if (token == null || token.isEmpty) {
        throw const AuthException('Not authenticated');
      }
      headers['Authorization'] = 'Bearer $token';
    }

    if (kDebugMode) {
      debugPrint('[AkukoApi] $method $uri');
    }

    http.Response response;
    try {
      response = await _send(method, uri, headers, body);
    } on SocketException catch (e) {
      throw NetworkException('No internet connection', e);
    } on http.ClientException catch (e) {
      throw NetworkException(e.message, e);
    }

    if (response.statusCode == 401 && auth && !isRetry) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        return _request(
          method,
          path,
          body: body,
          queryParams: queryParams,
          auth: auth,
          isRetry: true,
        );
      }
      await onUnauthorized?.call();
      throw const AuthException('Session expired');
    }

    if (response.statusCode == 401) {
      await onUnauthorized?.call();
      throw const AuthException('Unauthorized');
    }

    if (response.statusCode == 403) {
      throw AccessDeniedException(_errorMessage(response));
    }

    if (response.statusCode == 404) {
      throw NotFoundException(_errorMessage(response));
    }

    if (response.statusCode >= 500 && !isRetry) {
      for (var i = 0; i < ApiConfig.maxRetries; i++) {
        await Future<void>.delayed(Duration(milliseconds: 300 * (i + 1)));
        try {
          return await _request(
            method,
            path,
            body: body,
            queryParams: queryParams,
            auth: auth,
            isRetry: true,
          );
        } on ServerException {
          if (i == ApiConfig.maxRetries - 1) rethrow;
        }
      }
    }

    if (response.statusCode >= 400) {
      throw _exceptionForResponse(response);
    }

    return _parseBody(response);
  }

  Future<http.Response> _send(
    String method,
    Uri uri,
    Map<String, String> headers,
    Map<String, dynamic>? body,
  ) {
    final encoded = body == null ? null : jsonEncode(body);
    switch (method) {
      case 'GET':
        return _http.get(uri, headers: headers).timeout(ApiConfig.receiveTimeout);
      case 'POST':
        return _http
            .post(uri, headers: headers, body: encoded)
            .timeout(ApiConfig.receiveTimeout);
      case 'PUT':
        return _http
            .put(uri, headers: headers, body: encoded)
            .timeout(ApiConfig.receiveTimeout);
      case 'DELETE':
        return _http
            .delete(uri, headers: headers)
            .timeout(ApiConfig.receiveTimeout);
      default:
        throw ServerException('Unsupported method: $method');
    }
  }

  Uri _buildUri(String path, Map<String, String>? queryParams) {
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    final base = Uri.parse(ApiConfig.baseUrl);
    return base.replace(
      path: '${base.path}$normalized'.replaceAll('//', '/'),
      queryParameters: queryParams?.isEmpty ?? true ? null : queryParams,
    );
  }

  dynamic _parseBody(http.Response response) {
    if (response.body.isEmpty) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return decoded;

    if (decoded['success'] == false) {
      final err = decoded['error'];
      final message = err is Map ? (err['message'] as String?) : null;
      final code = err is Map ? (err['code'] as String?) : null;
      throw ServerException(message ?? 'Request failed', code);
    }

    return decoded['data'];
  }

  String _errorMessage(http.Response response) {
    final parsed = _parseErrorBody(response.body);
    return parsed.$1 ?? 'HTTP ${response.statusCode}';
  }

  (String?, String?) _parseErrorBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final err = decoded['error'];
        if (err is Map) {
          final message = err['message'] is String ? err['message'] as String : null;
          final code = err['code'] is String ? err['code'] as String : null;
          return (message, code);
        }
      }
    } catch (_) {}
    return (null, null);
  }

  AppException _exceptionForResponse(http.Response response) {
    final (message, code) = _parseErrorBody(response.body);
    final text = message ?? 'HTTP ${response.statusCode}';

    if (response.statusCode == 401 ||
        code == 'invalid_credentials' ||
        code == 'invalid_refresh') {
      return AuthException(text, code);
    }

    if (response.statusCode == 409 || code == 'email_exists') {
      return AuthException(text, code);
    }

    return ServerException(text, code);
  }

  Future<bool> _tryRefresh() async {
    if (_isRefreshing) return false;
    final refresh = tokenStorage.refreshToken;
    if (refresh == null || refresh.isEmpty) return false;

    _isRefreshing = true;
    try {
      final uri = _buildUri('auth/refresh', null);
      final res = await _http
          .post(
            uri,
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'refresh_token': refresh}),
          )
          .timeout(ApiConfig.receiveTimeout);

      if (res.statusCode >= 400) return false;

      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>?;
      final access = data?['access_token'] as String?;
      final newRefresh = data?['refresh_token'] as String?;
      if (access == null) return false;

      await tokenStorage.saveTokens(
        accessToken: access,
        refreshToken: newRefresh ?? refresh,
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  void dispose() => _http.close();
}

/// Extract a list from API `data` (raw list or paginated items).
List<Map<String, dynamic>> apiListOf(dynamic data) {
  if (data is List) {
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  if (data is Map && data['items'] is List) {
    return (data['items'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }
  return const [];
}

/// Normalize numeric IDs to strings for domain models.
Map<String, dynamic> apiNormalizeRow(Map<String, dynamic> row) {
  final out = Map<String, dynamic>.from(row);
  for (final key in ['id', 'user_id', 'book_id', 'category_id']) {
    final v = out[key];
    if (v != null) out[key] = v.toString();
  }
  return out;
}
