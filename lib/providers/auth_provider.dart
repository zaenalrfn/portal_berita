import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService authService;
  UserModel? user;
  bool loading = false;

  /// Ditandai true bila server mengembalikan 401 (token expired)
  /// tapi kita tidak mau tunjukkan login dialog langsung (background).
  bool sessionExpired = false;

  AuthProvider(this.authService);

  Future<void> loadProfile() async {
    loading = true;
    notifyListeners();
    try {
      user = await authService.getProfile();
      // jika berhasil, bersihkan flag expired
      sessionExpired = false;
    } catch (e) {
      user = null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> register(String name, String email, String password) async {
    loading = true;
    notifyListeners();
    try {
      await authService.register(name, email, password);
      await loadProfile();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    loading = true;
    notifyListeners();
    try {
      await authService.login(email, password);
      await loadProfile();
      sessionExpired = false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await authService.logout();
    } catch (_) {}
    user = null;
    sessionExpired = false;
    notifyListeners();
  }

  /// Hapus state lokal saja (dipanggil ketika token sudah invalid / 401)
  Future<void> logoutLocalOnly() async {
    user = null;
    sessionExpired = true; // tandai agar UI tahu sesi expired
    notifyListeners();
  }

  /// Clear flag expired jika user melakukan login manual
  void clearSessionExpired() {
    sessionExpired = false;
    notifyListeners();
  }

  bool get isLoggedIn => user != null;
}
