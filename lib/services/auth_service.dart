import 'dart:convert';
import '../models/user_model.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient api;
  AuthService(this.api);

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
      return UserModel.fromJson(j['data'] ?? j);
    }
    return null;
  }
}