import 'dart:convert';
import 'dart:typed_data';

/// Secure logger that prevents sensitive data from being logged
class SecureLogger {
  /// Sensitive data patterns that should never be logged
  static final Set<String> _sensitivePatterns = {
    'password',
    'private_key',
    'privkey',
    'seed',
    'mnemonic',
    'dek',
    'kek',
    'secret',
    'key',
    'salt',
    'nonce',
    'mac',
    'ciphertext',
    'plaintext',
    'encrypted',
    'decrypted',
  };

  /// Sensitive data types that should be redacted
  static final Set<Type> _sensitiveTypes = {Uint8List};

  /// Log info message with sensitive data filtering
  static void info(String message, [Map<String, dynamic>? data]) {
    final sanitizedMessage = _sanitizeMessage(message);
    final sanitizedData = data != null ? _sanitizeData(data) : null;

    print(
      '[INFO] $sanitizedMessage${sanitizedData != null ? ' | Data: $sanitizedData' : ''}',
    );
  }

  /// Log error message with sensitive data filtering
  static void error(
    String message, [
    dynamic error,
    Map<String, dynamic>? data,
  ]) {
    final sanitizedMessage = _sanitizeMessage(message);
    final sanitizedError = _sanitizeError(error);
    final sanitizedData = data != null ? _sanitizeData(data) : null;

    print(
      '[ERROR] $sanitizedMessage${sanitizedError != null ? ' | Error: $sanitizedError' : ''}${sanitizedData != null ? ' | Data: $sanitizedData' : ''}',
    );
  }

  /// Log warning message with sensitive data filtering
  static void warning(String message, [Map<String, dynamic>? data]) {
    final sanitizedMessage = _sanitizeMessage(message);
    final sanitizedData = data != null ? _sanitizeData(data) : null;

    print(
      '[WARNING] $sanitizedMessage${sanitizedData != null ? ' | Data: $sanitizedData' : ''}',
    );
  }

  /// Log debug message (only in debug mode) with sensitive data filtering
  static void debug(String message, [Map<String, dynamic>? data]) {
    assert(() {
      final sanitizedMessage = _sanitizeMessage(message);
      final sanitizedData = data != null ? _sanitizeData(data) : null;

      print(
        '[DEBUG] $sanitizedMessage${sanitizedData != null ? ' | Data: $sanitizedData' : ''}',
      );
      return true;
    }());
  }

  /// Sanitize message to remove sensitive information
  static String _sanitizeMessage(String message) {
    String sanitized = message;

    // Replace sensitive patterns with [REDACTED]
    for (final pattern in _sensitivePatterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      sanitized = sanitized.replaceAllMapped(regex, (match) {
        return '[REDACTED_${match.group(0)?.toUpperCase()}]';
      });
    }

    // Remove base64-like strings (potential encoded sensitive data)
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'[A-Za-z0-9+/]{20,}={0,2}'),
      (match) => '[REDACTED_BASE64]',
    );

    // Remove hex strings (potential encoded sensitive data)
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'0x[a-fA-F0-9]{16,}'),
      (match) => '[REDACTED_HEX]',
    );

    return sanitized;
  }

  /// Sanitize data map to remove sensitive information
  static Map<String, dynamic> _sanitizeData(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};

    for (final entry in data.entries) {
      final key = entry.key.toLowerCase();
      final value = entry.value;

      // Check if key contains sensitive patterns
      bool isSensitive = _sensitivePatterns.any(
        (pattern) => key.contains(pattern),
      );

      // Check if value is sensitive type
      if (!isSensitive && value != null) {
        isSensitive = _sensitiveTypes.contains(value.runtimeType);
      }

      // Check if value is string with sensitive content
      if (!isSensitive && value is String) {
        isSensitive = _containsSensitiveContent(value);
      }

      if (isSensitive) {
        sanitized[entry.key] = '[REDACTED]';
      } else if (value is Map<String, dynamic>) {
        sanitized[entry.key] = _sanitizeData(value);
      } else if (value is List) {
        sanitized[entry.key] = _sanitizeList(value);
      } else {
        sanitized[entry.key] = value;
      }
    }

    return sanitized;
  }

  /// Sanitize list to remove sensitive information
  static List<dynamic> _sanitizeList(List<dynamic> list) {
    return list.map((item) {
      if (item is Map<String, dynamic>) {
        return _sanitizeData(item);
      } else if (item is List) {
        return _sanitizeList(item);
      } else if (item is String && _containsSensitiveContent(item)) {
        return '[REDACTED]';
      } else if (_sensitiveTypes.contains(item.runtimeType)) {
        return '[REDACTED]';
      } else {
        return item;
      }
    }).toList();
  }

  /// Sanitize error object
  static String? _sanitizeError(dynamic error) {
    if (error == null) return null;

    final errorString = error.toString();
    return _sanitizeMessage(errorString);
  }

  /// Check if string contains sensitive content
  static bool _containsSensitiveContent(String value) {
    // Check for base64-like patterns
    if (RegExp(r'^[A-Za-z0-9+/]{20,}={0,2}$').hasMatch(value)) {
      return true;
    }

    // Check for hex patterns
    if (RegExp(r'^0x[a-fA-F0-9]{16,}$').hasMatch(value)) {
      return true;
    }

    // Check for long alphanumeric strings (potential keys/hashes)
    if (RegExp(r'^[a-fA-F0-9]{32,}$').hasMatch(value)) {
      return true;
    }

    return false;
  }

  /// Log crypto operation (always sanitized)
  static void cryptoOperation(
    String operation, {
    bool success = true,
    String? error,
    Map<String, dynamic>? metadata,
  }) {
    final sanitizedMetadata = metadata != null ? _sanitizeData(metadata) : null;
    final sanitizedError = error != null ? _sanitizeMessage(error) : null;

    final status = success ? 'SUCCESS' : 'FAILED';
    final message = 'Crypto operation: $operation - $status';

    if (success) {
      info(message, sanitizedMetadata);
    } else {
      SecureLogger.error(message, sanitizedError, sanitizedMetadata);
    }
  }

  /// Log wallet operation (always sanitized)
  static void walletOperation(
    String operation, {
    required String userId,
    bool success = true,
    String? error,
    Map<String, dynamic>? metadata,
  }) {
    // Hash user ID for privacy
    final hashedUserId = _hashUserId(userId);

    final sanitizedMetadata = metadata != null ? _sanitizeData(metadata) : null;
    final sanitizedError = error != null ? _sanitizeMessage(error) : null;

    final status = success ? 'SUCCESS' : 'FAILED';
    final message =
        'Wallet operation: $operation for user $hashedUserId - $status';

    if (success) {
      info(message, sanitizedMetadata);
    } else {
      SecureLogger.error(message, sanitizedError, sanitizedMetadata);
    }
  }

  /// Hash user ID for privacy in logs
  static String _hashUserId(String userId) {
    final bytes = utf8.encode(userId);
    final hash = bytes.fold(0, (prev, element) => prev ^ element);
    return 'user_${hash.toRadixString(16).padLeft(8, '0')}';
  }

  /// Test the secure logger with various sensitive data
  static void runSecurityTest() {
    debug('Testing secure logger');

    // Test sensitive message sanitization
    info('Processing password: mySecretPassword123');
    info('Generated private_key: 0x1234567890abcdef1234567890abcdef12345678');
    info(
      'Encrypted data: SGVsbG8gV29ybGQgdGhpcyBpcyBhIGxvbmcgYmFzZTY0IHN0cmluZw==',
    );

    // Test sensitive data sanitization
    final sensitiveData = {
      'user_id': 'user123',
      'password': 'secret123',
      'private_key': Uint8List.fromList([1, 2, 3, 4]),
      'public_data': 'this is safe',
      'nested': {'seed': 'sensitive_seed_data', 'safe_field': 'safe_value'},
    };

    info('Processing user data', sensitiveData);

    // Test crypto operation logging
    cryptoOperation(
      'AES_ENCRYPT',
      success: true,
      metadata: {
        'algorithm': 'aes-256-gcm',
        'key_length': 32,
        'nonce': Uint8List.fromList([1, 2, 3]),
      },
    );

    // Test wallet operation logging
    walletOperation(
      'WALLET_CREATE',
      userId: 'user123456789',
      success: true,
      metadata: {'wallet_type': 'hd_wallet', 'coin_type': 60},
    );

    debug('Secure logger test completed');
  }
}

/// Extension for easy secure logging
extension SecureLogging on Object {
  /// Log this object securely
  void logSecurely(String message) {
    if (this is Map<String, dynamic>) {
      SecureLogger.info(message, this as Map<String, dynamic>);
    } else {
      SecureLogger.info('$message: ${toString()}');
    }
  }
}
