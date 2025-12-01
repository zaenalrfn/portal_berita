import 'dart:convert';
import '../models/user_model.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient api;
  AuthService(this.api);

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final resp = await api.post('/api/register', headers: {'Content-Type': 'application/json'}, body: jsonEncode({'name': name, 'email': email, 'password': password}));
    if (resp.statusCode == 200) {
      final json = jsonDecode(resp.body);
      final token = json['access_token'] ?? json['token'];
      if (token != null) await api.saveToken(token);
      return json;
    } else {
      throw Exception('Register failed: ${resp.body}');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final resp = await api.post('/api/login', headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': email, 'password': password}));
    if (resp.statusCode == 200) {
      final json = jsonDecode(resp.body);
      final token = json['access_token'] ?? json['token'];
      if (token != null) await api.saveToken(token);
      return json;
    } else {
      throw Exception('Login failed: ${resp.body}');
    }
  }

  Future<void> logout() async {
    await api.post('/api/logout');
    await api.deleteToken();
  }

  Future<UserModel?> getProfile() async {
    final resp = await api.get('/api/user');
    if (resp.statusCode == 200) {
      final j = jsonDecode(resp.body);
      final Map<String, dynamic> root = j is Map<String, dynamic> ? Map<String, dynamic>.from(j) : {};
      
    final Map<String, dynamic> userPart = root['user'] is Map
        ? Map<String, dynamic>.from(root['user'])
        : (root['data'] is Map ? Map<String, dynamic>.from(root['data']) : Map<String, dynamic>.from(root));

    // Tambahkan total_news dari root ke user map supaya model dapat membaca
    if (root.containsKey('total_news')) {
      userPart['total_news'] = root['total_news'];
    }

    return UserModel.fromJson(userPart);
    }
    return null;
  }
}