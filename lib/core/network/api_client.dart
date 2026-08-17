import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../storage/session_store.dart';
import 'api_exception.dart';
import 'api_response.dart';

typedef UnauthorizedHandler = void Function();

class ApiClient {
  final SessionStore sessionStore;

  late final Dio _dio;
  UnauthorizedHandler? onUnauthorized;

  ApiClient({required this.sessionStore}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        responseType: ResponseType.json,
        validateStatus: (status) => status != null && status < 500,
        headers: {
          'Accept': 'application/json',
          'X-App-Version': AppConfig.appVersion,
        },
      ),
    );

    if (AppConfig.allowBadCertificates) {
      _dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback = (cert, host, port) => true;
          return client;
        },
      );
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = sessionStore.token;

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';

            if (options.data is FormData) {
              (options.data as FormData).fields.add(MapEntry('token', token));
            } else if (options.data is Map) {
              final map = Map<String, dynamic>.from(options.data as Map);
              map.putIfAbsent('token', () => token);
              options.data = map;
            } else if (options.data == null) {
              options.data = {'token': token};
            }
          }

          handler.next(options);
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          request: false,
          requestHeader: false,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          logPrint: (Object object) => debugPrint('$object'),
        ),
      );
    }
  }

  void updateBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }

  Future<ApiResponse> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) {
    return _send(
      () => _dio.post(
        path,
        data: body ?? <String, dynamic>{},
        queryParameters: query,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<ApiResponse> upload(
    String path, {
    required FormData formData,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) {
    return _send(
      () => _dio.post(
        path,
        data: formData,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      ),
    );
  }

  Future<ApiResponse> _send(Future<Response> Function() request) async {
    try {
      final response = await request();
      final parsed = ApiResponse.fromJson(
        response.data,
        response.statusCode ?? 0,
      );

      if (parsed.success) return parsed;

      throw _failureFrom(parsed);
    } on DioException catch (error) {
      throw _fromDio(error);
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(
        message: 'Something went wrong. Please try again.',
        kind: ApiFailureKind.unknown,
      );
    }
  }

  ApiException _failureFrom(ApiResponse response) {
    final kind = _kindForStatus(response.statusCode);

    if (kind == ApiFailureKind.unauthorized) {
      onUnauthorized?.call();
    }

    return ApiException(
      message: response.message.isNotEmpty
          ? response.message
          : 'Request could not be completed.',
      statusCode: response.statusCode,
      errors: response.errors,
      kind: kind,
    );
  }

  ApiException _fromDio(DioException error) {
    if (error.type == DioExceptionType.cancel) {
      return const ApiException(
        message: 'Request cancelled.',
        kind: ApiFailureKind.cancelled,
      );
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const ApiException(
        message: 'The server took too long to respond. Please try again.',
        kind: ApiFailureKind.timeout,
      );
    }

    if (error.type == DioExceptionType.connectionError ||
        error.error is SocketException) {
      return const ApiException(
        message: 'No internet connection. Check your network and retry.',
        kind: ApiFailureKind.network,
      );
    }

    final response = error.response;

    if (response != null) {
      final parsed = ApiResponse.fromJson(
        response.data,
        response.statusCode ?? 0,
      );
      return _failureFrom(parsed);
    }

    return const ApiException(
      message: 'Unable to reach the server. Please try again.',
      kind: ApiFailureKind.network,
    );
  }

  ApiFailureKind _kindForStatus(int status) {
    switch (status) {
      case 401:
        return ApiFailureKind.unauthorized;
      case 403:
        return ApiFailureKind.forbidden;
      case 404:
        return ApiFailureKind.notFound;
      case 422:
        return ApiFailureKind.validation;
      default:
        if (status >= 500) return ApiFailureKind.server;
        return ApiFailureKind.validation;
    }
  }
}
