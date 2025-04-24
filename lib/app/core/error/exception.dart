// app/core/error/exceptions.dart

class ServerException implements Exception {
  final String? message;
  final int? statusCode; // Opcional: guardar o status code HTTP

  ServerException({this.message, this.statusCode});
}

class CacheException implements Exception {
  final String? message;
  CacheException({this.message});
}

class NetworkException implements Exception {
  final String? message;
  NetworkException({this.message = "Network error occurred."});
}
