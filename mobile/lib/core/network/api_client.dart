import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  // Cambia `isProduction` a `true` cuando subas el backend a tu servidor.
  static const bool isProduction = true;
  
  static const String baseUrl = isProduction 
      ? 'https://api.sparkingcraft.com/movil' 
      : 'http://192.168.1.8:8000/movil'; // IP de tu PC para probar en tu celular físico
  
  final Dio _dio;
  final FlutterSecureStorage _storage;
  void Function()? onUnauthorized;

  ApiClient() : _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  )), _storage = const FlutterSecureStorage() {
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
            if (onUnauthorized != null) {
              onUnauthorized!();
            }
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
