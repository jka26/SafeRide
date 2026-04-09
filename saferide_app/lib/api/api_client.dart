import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'session_store.dart';

class ApiClient {
  ApiClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Uri _uri(String path, [Map<String, dynamic>? queryParameters]) {
    final base = ApiConfig.baseUrl.endsWith('/')
        ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
        : ApiConfig.baseUrl;
    return Uri.parse('$base$path').replace(
      queryParameters: queryParameters?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }

  Map<String, String> _headers() {
    final token = SessionStore.instance.token;
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _httpClient.get(
      _uri(path, queryParameters),
      headers: _headers(),
    );
    return _decode(response);
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _httpClient.post(
      _uri(path),
      headers: _headers(),
      body: jsonEncode(body ?? <String, dynamic>{}),
    );
    return _decode(response);
  }

  Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _httpClient.patch(
      _uri(path),
      headers: _headers(),
      body: jsonEncode(body ?? <String, dynamic>{}),
    );
    return _decode(response);
  }

  dynamic _decode(http.Response response) {
    final hasBody = response.body.trim().isNotEmpty;
    final payload = hasBody ? jsonDecode(response.body) : null;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return payload;
    }

    String message = 'Request failed';
    if (payload is Map<String, dynamic>) {
      final raw = payload['message'];
      if (raw is List && raw.isNotEmpty) {
        message = raw.join(', ');
      } else if (raw != null) {
        message = raw.toString();
      }
    }

    throw ApiException(statusCode: response.statusCode, message: message);
  }
}

class ApiException implements Exception {
  ApiException({
    required this.statusCode,
    required this.message,
  });

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}
