import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  final String baseUrl;
  final http.Client _client;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  Future<String?> getToken() => _storage.read(key: 'access_token');

  Future<void> saveToken(String token) => _storage.write(key: 'access_token', value: token);

  Future<void> deleteToken() => _storage.delete(key: 'access_token');

  Map<String, String> defaultHeaders(String? token) {
    final headers = {'Accept': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Uri _u(String path) => Uri.parse('$baseUrl$path');

  Future<http.Response> get(String path) async {
    final token = await getToken();
    return _client.get(_u(path), headers: defaultHeaders(token));
  }

  Future<http.Response> post(String path, {Map<String, String>? headers, dynamic body}) async {
    final token = await getToken();
    final h = {...defaultHeaders(token), if (headers != null) ...headers};
    return _client.post(_u(path), headers: h, body: body);
  }

  Future<http.Response> put(String path, {Map<String, String>? headers, dynamic body}) async {
    final token = await getToken();
    final h = {...defaultHeaders(token), if (headers != null) ...headers};
    return _client.put(_u(path), headers: h, body: body);
  }

  Future<http.Response> delete(String path) async {
    final token = await getToken();
    return _client.delete(_u(path), headers: defaultHeaders(token));
  }
}
