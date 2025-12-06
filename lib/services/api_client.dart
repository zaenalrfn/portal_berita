// lib/services/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

typedef UnauthenticatedHandler = Future<void> Function();

class ApiClient {
  final String baseUrl;
  final http.Client _client;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // make it non-final so we can assign callback after runApp if needed
  UnauthenticatedHandler? onUnauthenticated;

  ApiClient({required this.baseUrl, http.Client? client, this.onUnauthenticated})
      : _client = client ?? http.Client();

  Future<String?> getToken() => _storage.read(key: 'access_token');
  Future<void> saveToken(String token) => _storage.write(key: 'access_token', value: token);
  Future<void> deleteToken() => _storage.delete(key: 'access_token');

  Map<String, String> defaultHeaders(String? token) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Uri _u(String path) {
    if (path.startsWith('http')) return Uri.parse(path);
    return Uri.parse('$baseUrl$path');
  }

  Future<http.Response> get(String path) async => _request('GET', path);
  Future<http.Response> post(String path, {Map<String, String>? headers, dynamic body}) async =>
      _request('POST', path, headers: headers, body: body);
  Future<http.Response> put(String path, {Map<String, String>? headers, dynamic body}) async =>
      _request('PUT', path, headers: headers, body: body);
  Future<http.Response> delete(String path) async => _request('DELETE', path);

  Future<http.Response> _request(String method, String path,
      {Map<String, String>? headers, dynamic body}) async {
    final token = await getToken();
    final merged = {...defaultHeaders(token), if (headers != null) ...headers};
    final uri = _u(path);

    http.Response resp;
    switch (method) {
      case 'GET':
        resp = await _client.get(uri, headers: merged);
        break;
      case 'POST':
        resp = await _client.post(uri, headers: merged, body: body);
        break;
      case 'PUT':
        resp = await _client.put(uri, headers: merged, body: body);
        break;
      case 'DELETE':
        resp = await _client.delete(uri, headers: merged);
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }

    // handle 401 globally: delete token + callback so UI/Provider can react
    if (resp.statusCode == 401) {
      await deleteToken();
      if (onUnauthenticated != null) {
        try {
          await onUnauthenticated!();
        } catch (e) {
          // swallow exceptions from callback to avoid breaking callers
        }
      }
    }

    return resp;
  }
}
