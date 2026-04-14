import 'dart:convert';
import 'dart:io';

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
    final uri = _uri(path, queryParameters);
    final response = await _send(() => _httpClient.get(uri, headers: _headers()), uri);
    return _decode(response);
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = _uri(path);
    final response = await _send(
      () => _httpClient.post(
        uri,
        headers: _headers(),
        body: jsonEncode(body ?? <String, dynamic>{}),
      ),
      uri,
    );
    return _decode(response);
  }

  Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = _uri(path);
    final response = await _send(
      () => _httpClient.patch(
        uri,
        headers: _headers(),
        body: jsonEncode(body ?? <String, dynamic>{}),
      ),
      uri,
    );
    return _decode(response);
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request,
    Uri uri,
  ) async {
    try {
      return await request();
    } on SocketException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Could not connect to $uri (${e.message})',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Could not reach $uri (${e.message})',
      );
    } on FormatException catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Invalid response from $uri (${e.message})',
      );
    }
  }

  dynamic _decode(http.Response response) {
    final hasBody = response.body.trim().isNotEmpty;
    dynamic payload;
    if (hasBody) {
      try {
        payload = jsonDecode(response.body);
      } catch (_) {
        payload = response.body;
      }
    }

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
    } else if (payload is String && payload.isNotEmpty) {
      message = payload;
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
