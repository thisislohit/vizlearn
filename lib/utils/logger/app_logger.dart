import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// App-wide logger that automatically disables logging in release builds
class AppLogger {
  static Logger? _logger;

  /// Get the logger instance
  /// In release mode, returns a logger that doesn't output anything
  static Logger get logger {
    if (_logger != null) return _logger!;

    if (kReleaseMode) {
      // In release mode, use a logger that doesn't output anything
      _logger = Logger(
        printer: _ReleasePrinter(),
        level: Level.off,
      );
    } else {
      // In debug/profile mode, use full logging
      _logger = Logger(
        printer: PrettyPrinter(
          methodCount: 0,
          errorMethodCount: 5,
          colors: true,
          printEmojis: true,
          printTime: true,
        ),
      );
    }

    return _logger!;
  }

  /// Reset the logger (useful for testing)
  static void reset() {
    _logger = null;
  }
}

/// A printer that does nothing (for release builds)
class _ReleasePrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    // Return empty list - no output in release mode
    return [];
  }
}

