import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService authService;
  UserModel? user;
  bool loading = false;

  AuthProvider(this.authService);

  Future<void> loadProfile() async {
    loading = true; notifyListeners();
    try {
      user = await authService.getProfile();
    } catch (e) {
      user = null;
    } finally {
      loading = false; notifyListeners();
    }
  }

  Future<void> register(String name, String email, String password) async {
    loading = true; notifyListeners();
    try {
      await authService.register(name, email, password);
      await loadProfile();
    } finally {
      loading = false; notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    loading = true; notifyListeners();
    try {
      await authService.login(email, password);
      await loadProfile();
    } finally {
      loading = false; notifyListeners();
    }
  }

  Future<void> logout() async {
    await authService.logout();
    user = null;
    notifyListeners();
  }

  bool get isLoggedIn => user != null;
}
