import 'dart:async';
import 'package:dio/dio.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';

class AuthState {
  final bool isAuthenticated;
  const AuthState({required this.isAuthenticated});
}

class AuthRepository {
  final ApiClient _api;
  final _authStateController = StreamController<AuthState>.broadcast();

  AuthRepository(this._api) {
    _init();
  }

  Future<void> _init() async {
    final hasToken = await _api.hasToken();
    _authStateController.add(AuthState(isAuthenticated: hasToken));
  }

  bool get isLoggedIn => true; // Replaced by stream

  Stream<AuthState> get authStateChanges => _authStateController.stream;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _api.client.post('/auth/login', data: {
        'email': email.trim(),
        'password': password,
      });
      final token = res.data['access_token'];
      await _api.saveToken(token);
      _authStateController.add(const AuthState(isAuthenticated: true));
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Error de inicio de sesión');
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String nombre,
  }) async {
    try {
      final res = await _api.client.post('/auth/register', data: {
        'email': email.trim(),
        'password': password,
        'nombre': nombre.trim(),
      });
      final token = res.data['access_token'];
      await _api.saveToken(token);
      _authStateController.add(const AuthState(isAuthenticated: true));
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Error de registro');
    }
  }

  Future<void> signOut() async {
    await _api.deleteToken();
    _authStateController.add(const AuthState(isAuthenticated: false));
  }

  Future<void> resetPassword(String email) async {
    // Aún no implementado en el backend
  }

  Future<PerfilModel?> getPerfil() async {
    try {
      final res = await _api.client.get('/auth/me');
      return PerfilModel.fromJson(res.data);
    } catch (_) {
      return null;
    }
  }
}
