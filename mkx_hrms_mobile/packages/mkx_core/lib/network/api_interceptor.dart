import 'package:dio/dio.dart';
import '../storage/token_storage.dart';
import 'dio_client.dart';

/// Network interceptor injecting Authorization headers and structured logging
/// via `AppLogger` (`logger: ^2.8.0`) across all HTTP lifecycle phases (pending, success, error).
class ApiInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.extra['request_start_time'] = DateTime.now().millisecondsSinceEpoch;

    final token = await TokenStorage.instance.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Accept'] = 'application/json';
    options.headers['Content-Type'] = 'application/json';
    options.headers['x-timezone'] = 'Asia/Kolkata';
    options.headers['x-timezone-offset'] = '+05:30';

    AppLogger.logRequest(
      method: options.method,
      uri: options.uri,
      headers: options.headers,
      queryParams: options.queryParameters,
      body: options.data,
    );

    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final startTime = response.requestOptions.extra['request_start_time'] as int?;
    final durationMs = startTime != null
        ? DateTime.now().millisecondsSinceEpoch - startTime
        : 0;

    AppLogger.logResponse(
      method: response.requestOptions.method,
      uri: response.requestOptions.uri,
      statusCode: response.statusCode ?? 200,
      durationMs: durationMs,
      data: response.data,
    );

    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final startTime = err.requestOptions.extra['request_start_time'] as int?;
    final durationMs = startTime != null
        ? DateTime.now().millisecondsSinceEpoch - startTime
        : 0;

    AppLogger.logError(
      method: err.requestOptions.method,
      uri: err.requestOptions.uri,
      statusCode: err.response?.statusCode,
      durationMs: durationMs,
      message: err.message ?? err.toString(),
      responseData: err.response?.data,
      error: err.error,
      stackTrace: err.stackTrace,
    );

    if (err.response?.statusCode == 401) {
      final path = err.requestOptions.path;
      if (!path.contains('/auth/login')) {
        DioClient.handleUnauthorized();
      }
    }

    return handler.next(err);
  }
}
