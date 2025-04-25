import 'package:desafio_loomi/app/features/auth/data/datasources/auth_local_data_source.dart'; // Ajuste o path se necessário
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class AuthInterceptor extends Interceptor {
  final FirebaseAuth _firebaseAuth;

  AuthInterceptor({required FirebaseAuth firebaseAuth})
      : _firebaseAuth = firebaseAuth;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    debugPrint('AuthInterceptor: Checking auth for ${options.path}');

    final publicPaths = ['/api/auth/local/register', '/api/auth/local'];
    if (publicPaths.contains(options.path)) {
      debugPrint('AuthInterceptor: Path is public, skipping token.');
      options.headers['Content-Type'] =
          'application/json'; // Garante content-type
      return handler.next(options); // Continua sem adicionar token
    }

    try {
      final user = _firebaseAuth.currentUser;
      debugPrint('AuthInterceptor: Current Firebase User: ${user?.uid}');

      if (user == null) {
        debugPrint(
            'AuthInterceptor: No Firebase user logged in for protected route.');
        handler.reject(
          DioException(
            requestOptions: options,
            error: 'User not authenticated for protected route ${options.path}',
            type: DioExceptionType.cancel, // Ou outro tipo apropriado
          ),
        );
        return;
      }

      debugPrint(
          'AuthInterceptor: Firebase user exists. Trying to get fresh token...');
      final token = await user.getIdToken(true);

      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';

        try {
          final authLocalDataSource = GetIt.I.get<AuthLocalDataSource>();
          await authLocalDataSource.saveToken(token);
        } catch (e) {
          debugPrint(
              "AuthInterceptor: Failed to get/save token to local cache - $e");
        }
      } else {
        debugPrint('AuthInterceptor: getIdToken(true) returned null.');
        handler.reject(
          DioException(
            requestOptions: options,
            error: 'Failed to get Firebase token (token was null)',
            type: DioExceptionType.cancel,
          ),
        );
        return;
      }
    } catch (e) {
      debugPrint('AuthInterceptor: Error getting Firebase token: $e');
      handler.reject(
        DioException(
          requestOptions: options,
          error: 'Failed to get Firebase token: $e',
          type: DioExceptionType.unknown,
        ),
      );
      return;
    }

    options.headers['Content-Type'] = 'application/json';
    debugPrint(
        'AuthInterceptor: Proceeding with request (Authorization header added).');
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
        'AuthInterceptor: onError Status Code: ${err.response?.statusCode} for ${err.requestOptions.path}');
    if (err.response?.statusCode == 401 || err.response?.statusCode == 403) {
      debugPrint(
          'AuthInterceptor: Received ${err.response?.statusCode}, attempting to clear local token if exists.');
      try {
        final authLocalDataSource = GetIt.I.get<AuthLocalDataSource>();
        authLocalDataSource.clearToken();
      } catch (e) {
        debugPrint(
            "AuthInterceptor: Failed to get/clear token from local cache on error - $e");
      }
      final errorMsg = (err.response?.statusCode == 401)
          ? 'Unauthorized (Token possibly expired or invalid). Please login again.'
          : 'Forbidden (User does not have permission for this action).';
      err = err.copyWith(error: errorMsg);
    }
    return handler.next(err);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    return handler.next(response); // Passa a resposta adiante
  }
}

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.forEach((k, v) => debugPrint('$k: $v'));
    if (options.data != null) {}

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    response.headers.forEach((k, v) => debugPrint("$k: $v"));
    if (response.data != null) {
      debugPrint("Response: ${response.data}");
    }

    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
      "<-- Error ${err.response?.statusCode} ${err.requestOptions.method} ${err.requestOptions.uri}",
    );
    if (err.response != null) {
      debugPrint("Error Response: ${err.response?.data}");
    } else {
      debugPrint("Error Message: ${err.message}");
    }

    super.onError(err, handler);
  }
}
