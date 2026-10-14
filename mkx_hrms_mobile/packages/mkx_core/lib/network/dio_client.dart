import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import '../constants/api_endpoints.dart';
import '../storage/token_storage.dart';
import '../utils/ui_helpers.dart';
import 'api_exception.dart';
import 'api_interceptor.dart';

export 'package:dio_cache_interceptor/dio_cache_interceptor.dart'
    show CachePolicy, CacheOptions, CachePriority;
export '../utils/app_logger.dart';

/// Dio networking service managing the HTTP client instance, request dispatching,
/// in-memory caching, and offline response resilience.
class DioClient {
  DioClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.defaultBaseUrl,
        connectTimeout: const Duration(seconds: 180),
        receiveTimeout: const Duration(seconds: 180),
        sendTimeout: const Duration(seconds: 180),
      ),
    );

    _cacheStore = MemCacheStore(
      maxSize: 10485760,
      maxEntrySize: 1048576,
    );

    _cacheOptions = CacheOptions(
      store: _cacheStore,
      policy: CachePolicy.request,
      hitCacheOnNetworkFailure: true,
      hitCacheOnErrorCodes: const <int>[500, 502, 503, 504],
      priority: CachePriority.normal,
      maxStale: const Duration(days: 7),
      allowPostMethod: false,
    );

    _dio.interceptors.add(DioCacheInterceptor(options: _cacheOptions));
    _dio.interceptors.add(ApiInterceptor());
  }

  static final DioClient instance = DioClient._();
  late final Dio _dio;
  late final CacheStore _cacheStore;
  late final CacheOptions _cacheOptions;

  /// Underlying Dio HTTP client instance.
  Dio get dio => _dio;

  /// In-memory cache storage instance.
  CacheStore get cacheStore => _cacheStore;

  /// Global cache configuration options.
  CacheOptions get cacheOptions => _cacheOptions;

  /// Global callback invoked on 401 Unauthorized errors to handle session termination.
  static void Function()? onUnauthorized;

  /// When true, bypasses automatic 401 handler for preview and testing.
  static bool bypassUnauthorized = false;

  static DateTime? _lastUnauthorizedTime;

  /// Throttled handler for 401 Unauthorized responses to avoid repetitive logout calls.
  static void handleUnauthorized() {
    if (bypassUnauthorized) return;

    final now = DateTime.now();
    if (_lastUnauthorizedTime != null &&
        now.difference(_lastUnauthorizedTime!).inSeconds < 3) {
      return;
    }
    _lastUnauthorizedTime = now;

    if (onUnauthorized != null) {
      onUnauthorized?.call();
    } else {
      UiHelpers.showGlobalSnackBar('Session Expired', isError: true);
      UiHelpers.rootNavigatorKey.currentState
          ?.popUntil((route) => route.isFirst);
    }
  }

  /// Updates and persists the base API URL.
  void updateBaseUrl(String newUrl) {
    _dio.options.baseUrl = newUrl;
    TokenStorage.instance.saveBaseUrl(newUrl);
  }

  /// Clears all entries from the in-memory cache store.
  Future<void> clearCache() async {
    await _cacheStore.clean();
  }

  /// Invalidates a specific cached resource path.
  Future<void> deleteCache(String path) async {
    await _cacheStore.delete(path);
  }

  /// Perform a GET request with optional cache policy override and force-refresh support.
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CachePolicy? cachePolicy,
    bool forceRefresh = false,
  }) async {
    try {
      Options requestOptions;
      if (forceRefresh || cachePolicy != null) {
        final policy = forceRefresh ? CachePolicy.refresh : cachePolicy!;
        final customOptions = _cacheOptions.copyWith(policy: policy);
        final Map<String, dynamic> mergedExtra = <String, dynamic>{
          ...?options?.extra,
          ...customOptions.toExtra(),
        };

        requestOptions = (options ?? Options()).copyWith(
          extra: mergedExtra,
        );
      } else {
        requestOptions = options ?? Options();
      }

      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: requestOptions,
      );
      return _extractData(response);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Perform a POST request
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _extractData(response);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Perform a PATCH request
  Future<dynamic> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _extractData(response);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Perform a DELETE request
  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _extractData(response);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  dynamic _extractData(Response response) {
    if (response.data is Map<String, dynamic>) {
      final map = response.data as Map<String, dynamic>;
      if (map.containsKey('data')) {
        return map['data'];
      }
      return map;
    }
    return response.data;
  }
}
