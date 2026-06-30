import 'dart:io';
import 'package:dio/dio.dart';

class ErrorHandler {
  static String parse(Object e) {
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.receiveTimeout || 
          e.type == DioExceptionType.sendTimeout) {
        return 'El servidor tardó demasiado en responder.';
      } else if (e.type == DioExceptionType.connectionError || e.error is SocketException) {
        return 'No hay conexión a internet.';
      } else if (e.response != null && e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map && data['detail'] != null) {
          final detail = data['detail'];
          // Handle standard FastAPI validation errors which can be a list
          if (detail is List && detail.isNotEmpty && detail.first is Map && detail.first['msg'] != null) {
             return detail.first['msg'].toString();
          }
          return detail.toString();
        }
      }
      return 'Ocurrió un error inesperado al procesar la solicitud.';
    }
    
    // For general dart exceptions (like FormatException)
    return e.toString();
  }
}
