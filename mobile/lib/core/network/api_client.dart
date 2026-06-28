import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';

class ApiClient {
  // Cambia `isProduction` a `true` cuando subas el backend a tu servidor.
  static const bool isProduction = false;
  
  static const String baseUrl = isProduction 
      ? 'https://api.sparkingcraft.com/movil' 
      : 'http://127.0.0.1:8000/movil'; // En emulador Android usar: 'http://10.0.2.2:8000/movil'
  
  final Dio _dio;
  final FlutterSecureStorage _storage;

  ApiClient() : _dio = Dio(BaseOptions(baseUrl: baseUrl)), _storage = const FlutterSecureStorage() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'jwt_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            await _storage.delete(key: 'jwt_token');
          }
          return handler.next(e);
        }
      )
    );
  }

  Dio get client => _dio;
  FlutterSecureStorage get storage => _storage;

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<bool> hasToken() async {
    final token = await _storage.read(key: 'jwt_token');
    return token != null;
  }
}

final apiClient = ApiClient();
