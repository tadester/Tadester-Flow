import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

class BackendApiException implements Exception {
  const BackendApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class BackendApiClient {
  static const Duration _requestTimeout = Duration(seconds: 15);

  BackendApiClient({http.Client? httpClient, GoTrueClient? authClient})
    : _httpClient = httpClient ?? http.Client(),
      _authClient = authClient ?? Supabase.instance.client.auth;

  final http.Client _httpClient;
  final GoTrueClient _authClient;

  Future<Map<String, dynamic>> getJson(String path) async {
    final http.Response response = await _send(method: 'GET', path: path);
    return _decodeJsonObject(response.body);
  }

  Future<Map<String, dynamic>> getPublicJson(String path) async {
    final http.Response response = await _send(
      method: 'GET',
      path: path,
      requireAuth: false,
    );
    return _decodeJsonObject(response.body);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final http.Response response = await _send(
      method: 'POST',
      path: path,
      body: jsonEncode(body),
    );
    return _decodeJsonObject(response.body);
  }

  Future<Map<String, dynamic>> postPublicJson(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final http.Response response = await _send(
      method: 'POST',
      path: path,
      body: jsonEncode(body),
      requireAuth: false,
    );
    return _decodeJsonObject(response.body);
  }

  Future<http.Response> _send({
    required String method,
    required String path,
    String? body,
    bool requireAuth = true,
  }) async {
    final Map<String, String> headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (requireAuth) {
      final Session? session = _authClient.currentSession;
      final String? accessToken = session?.accessToken;

      if (accessToken == null || accessToken.isEmpty) {
        throw const BackendApiException(
          'You must be logged in to access the backend.',
        );
      }

      headers['Authorization'] = 'Bearer $accessToken';
    }

    final Uri uri = Uri.parse('${Env.backendApiUrl}$path');

    late final http.Response response;

    if (method == 'GET') {
      response = await _httpClient
          .get(uri, headers: headers)
          .timeout(_requestTimeout);
    } else if (method == 'POST') {
      response = await _httpClient
          .post(uri, headers: headers, body: body)
          .timeout(_requestTimeout);
    } else {
      throw BackendApiException('Unsupported HTTP method: $method');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }

    final Map<String, dynamic> payload = response.body.isEmpty
        ? <String, dynamic>{}
        : _decodeJsonObject(response.body);
    final dynamic error = payload['error'];
    final String message = error is Map<String, dynamic>
        ? (error['message'] as String? ?? 'Backend request failed.')
        : 'Backend request failed.';

    throw BackendApiException(message, statusCode: response.statusCode);
  }

  Map<String, dynamic> _decodeJsonObject(String body) {
    final dynamic decoded = jsonDecode(body);

    if (decoded is! Map<String, dynamic>) {
      throw const BackendApiException(
        'Backend response was not a JSON object.',
      );
    }

    return decoded;
  }
}

final Provider<BackendApiClient> backendApiClientProvider =
    Provider<BackendApiClient>((Ref ref) {
      return BackendApiClient();
    });
