import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

export 'package:logger/logger.dart';

/// Centralized application logging utility built on top of `logger: ^2.8.0`.
/// Renders structured, ANSI color-coded box entries visible across both IDE
/// Debug Consoles and system terminals (CMD, PowerShell, Bash).
class AppLogger {
  static final Logger _logger = Logger(
    filter: DevelopmentFilter(),
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 85,
      colors: true,
      printEmojis: false,
      dateTimeFormat: DateTimeFormat.none,
      levelColors: {
        Level.trace: const AnsiColor.fg(8),
        Level.debug: const AnsiColor.fg(12),
        Level.info: const AnsiColor.fg(34),
        Level.warning: const AnsiColor.fg(208),
        Level.error: const AnsiColor.fg(196),
        Level.fatal: const AnsiColor.fg(199),
      },
    ),
  );

  /// Underlying singleton [Logger] instance.
  static Logger get instance => _logger;

  /// Formats JSON strings, Maps, and Lists into indented multi-line JSON representation.
  static String _formatPayload(Object? payload) {
    if (payload == null) return '';
    try {
      if (payload is Map || payload is List) {
        const encoder = JsonEncoder.withIndent('  ');
        return encoder.convert(payload);
      }
      if (payload is String) {
        final trimmed = payload.trim();
        if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
            (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
          final decoded = json.decode(trimmed);
          const encoder = JsonEncoder.withIndent('  ');
          return encoder.convert(decoded);
        }
        return payload;
      }
      return payload.toString();
    } catch (_) {
      return payload.toString();
    }
  }

  /// Logs debug-level diagnostic messages.
  ///
  /// @param message The diagnostic message or object to record
  /// @param error Optional error object
  /// @param stackTrace Optional stack trace
  static void d(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _logger.d(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Logs standard informational messages in green.
  ///
  /// @param message The informational message to record
  /// @param error Optional error object
  /// @param stackTrace Optional stack trace
  static void i(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Logs operational warning messages in orange.
  ///
  /// @param message The warning message to record
  /// @param error Optional warning error object
  /// @param stackTrace Optional stack trace
  static void w(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Logs critical errors and exceptions in red.
  ///
  /// @param message The error message to record
  /// @param error The thrown error or exception
  /// @param stackTrace Optional stack trace
  static void e(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Formats and logs a pending HTTP request dispatch with orange box coloring.
  ///
  /// @param method HTTP method (GET, POST, etc.)
  /// @param uri Target request URI
  /// @param headers Request headers map
  /// @param queryParams Request query parameters
  /// @param body Optional request body payload
  static void logRequest({
    required String method,
    required Uri uri,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParams,
    Object? body,
  }) {
    if (!kDebugMode) return;

    final buffer = StringBuffer();
    buffer.writeln('[PENDING] $method $uri');

    if (queryParams != null && queryParams.isNotEmpty) {
      buffer.writeln('Query: $queryParams');
    }

    if (body != null) {
      buffer.writeln('Payload: ${_formatPayload(body)}');
    }

    _logger.w(buffer.toString().trimRight());
  }

  /// Formats and logs a successful HTTP response with green box coloring.
  ///
  /// @param method HTTP method
  /// @param uri Request URI
  /// @param statusCode HTTP response status code
  /// @param durationMs Request execution round-trip duration in milliseconds
  /// @param data Optional response data payload
  static void logResponse({
    required String method,
    required Uri uri,
    required int statusCode,
    required int durationMs,
    Object? data,
  }) {
    if (!kDebugMode) return;

    final buffer = StringBuffer();
    buffer.writeln('[SUCCESS] $statusCode (${durationMs}ms) $method $uri');

    if (data != null) {
      final formatted = _formatPayload(data);
      final preview = formatted.length > 1500
          ? '${formatted.substring(0, 1500)}\n... (truncated)'
          : formatted;
      buffer.writeln('Data: $preview');
    }

    _logger.i(buffer.toString().trimRight());
  }

  /// Formats and logs an HTTP error or exception with red box coloring.
  ///
  /// @param method HTTP method
  /// @param uri Request URI
  /// @param statusCode HTTP response status code if available
  /// @param durationMs Request round-trip duration in milliseconds
  /// @param message Descriptive error message
  /// @param responseData Optional response payload received from server
  /// @param error Optional underlying error or exception
  /// @param stackTrace Optional stack trace
  static void logError({
    required String method,
    required Uri uri,
    int? statusCode,
    int? durationMs,
    required String message,
    Object? responseData,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final buffer = StringBuffer();
    final statusText = statusCode != null ? '$statusCode' : 'NETWORK_ERROR';
    final durationText = durationMs != null ? ' (${durationMs}ms)' : '';

    buffer.writeln('[ERROR] $statusText$durationText $method $uri');
    buffer.writeln('Message: $message');

    if (responseData != null) {
      buffer.writeln('Response: ${_formatPayload(responseData)}');
    }

    _logger.e(
      buffer.toString().trimRight(),
      error: error,
      stackTrace: stackTrace,
    );
  }
}
