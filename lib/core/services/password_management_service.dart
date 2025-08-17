import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for password management and brute force protection
class PasswordManagementService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Brute force protection settings
  static const int maxFailedAttempts = 5;
  static const int lockoutDurationMinutes = 30;
  static const int progressiveLockoutMultiplier = 2;

  /// Check if user is currently locked out
  static Future<LockoutStatus> getLockoutStatus(String userId) async {
    try {
      final lockoutDataJson = await _secureStorage.read(key: 'lockout_$userId');
      if (lockoutDataJson == null) {
        return LockoutStatus(isLockedOut: false, failedAttempts: 0);
      }

      final lockoutData = json.decode(lockoutDataJson) as Map<String, dynamic>;
      final failedAttempts = lockoutData['failed_attempts'] as int;
      final lockoutUntil = lockoutData['lockout_until'] != null
          ? DateTime.fromMillisecondsSinceEpoch(lockoutData['lockout_until'] as int)
          : null;

      if (lockoutUntil != null && DateTime.now().isBefore(lockoutUntil)) {
        return LockoutStatus(
          isLockedOut: true,
          failedAttempts: failedAttempts,
          lockoutUntil: lockoutUntil,
        );
      }

      // Lockout expired, reset if needed
      if (lockoutUntil != null && DateTime.now().isAfter(lockoutUntil)) {
        await _resetFailedAttempts(userId);
        return LockoutStatus(isLockedOut: false, failedAttempts: 0);
      }

      return LockoutStatus(
        isLockedOut: false,
        failedAttempts: failedAttempts,
      );
    } catch (e) {
      print('Error getting lockout status: $e');
      return LockoutStatus(isLockedOut: false, failedAttempts: 0);
    }
  }

  /// Record a failed password attempt
  static Future<LockoutStatus> recordFailedAttempt(String userId) async {
    try {
      final currentStatus = await getLockoutStatus(userId);
      
      if (currentStatus.isLockedOut) {
        return currentStatus;
      }

      final newFailedAttempts = currentStatus.failedAttempts + 1;
      
      if (newFailedAttempts >= maxFailedAttempts) {
        // Calculate progressive lockout duration
        final lockoutCount = await _getLockoutCount(userId);
        final lockoutDuration = lockoutDurationMinutes * 
            (lockoutCount > 0 ? progressiveLockoutMultiplier * lockoutCount : 1);
        
        final lockoutUntil = DateTime.now().add(Duration(minutes: lockoutDuration));
        
        await _saveLockoutData(userId, newFailedAttempts, lockoutUntil);
        await _incrementLockoutCount(userId);

        print('User $userId locked out until $lockoutUntil (${lockoutDuration}min)');

        return LockoutStatus(
          isLockedOut: true,
          failedAttempts: newFailedAttempts,
          lockoutUntil: lockoutUntil,
        );
      } else {
        await _saveLockoutData(userId, newFailedAttempts, null);
        
        print('Failed attempt recorded for $userId: $newFailedAttempts/$maxFailedAttempts');

        return LockoutStatus(
          isLockedOut: false,
          failedAttempts: newFailedAttempts,
        );
      }
    } catch (e) {
      print('Error recording failed attempt: $e');
      return LockoutStatus(isLockedOut: false, failedAttempts: 0);
    }
  }

  /// Record a successful password attempt (resets failed attempts)
  static Future<void> recordSuccessfulAttempt(String userId) async {
    try {
      await _resetFailedAttempts(userId);
      print('Successful attempt recorded for $userId - failed attempts reset');
    } catch (e) {
      print('Error recording successful attempt: $e');
    }
  }

  /// Reset failed attempts for user
  static Future<void> _resetFailedAttempts(String userId) async {
    try {
      await _secureStorage.delete(key: 'lockout_$userId');
    } catch (e) {
      print('Error resetting failed attempts: $e');
    }
  }

  /// Save lockout data to secure storage
  static Future<void> _saveLockoutData(
    String userId,
    int failedAttempts,
    DateTime? lockoutUntil,
  ) async {
    try {
      final lockoutData = {
        'failed_attempts': failedAttempts,
        'lockout_until': lockoutUntil?.millisecondsSinceEpoch,
        'last_attempt': DateTime.now().millisecondsSinceEpoch,
      };

      await _secureStorage.write(
        key: 'lockout_$userId',
        value: json.encode(lockoutData),
      );
    } catch (e) {
      print('Error saving lockout data: $e');
    }
  }

  /// Get total lockout count for progressive penalties
  static Future<int> _getLockoutCount(String userId) async {
    try {
      final countStr = await _secureStorage.read(key: 'lockout_count_$userId');
      return countStr != null ? int.parse(countStr) : 0;
    } catch (e) {
      return 0;
    }
  }

  /// Increment lockout count
  static Future<void> _incrementLockoutCount(String userId) async {
    try {
      final currentCount = await _getLockoutCount(userId);
      await _secureStorage.write(
        key: 'lockout_count_$userId',
        value: (currentCount + 1).toString(),
      );
    } catch (e) {
      print('Error incrementing lockout count: $e');
    }
  }

  /// Validate password strength with detailed feedback
  static PasswordValidationResult validatePassword(String password) {
    final issues = <String>[];
    int score = 0;

    // Length check
    if (password.length < 8) {
      issues.add('Password must be at least 8 characters long');
    } else if (password.length >= 12) {
      score += 2;
    } else if (password.length >= 10) {
      score += 1;
    }

    // Character variety checks
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      issues.add('Password must contain lowercase letters');
    } else {
      score += 1;
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      issues.add('Password must contain uppercase letters');
    } else {
      score += 1;
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      issues.add('Password must contain numbers');
    } else {
      score += 1;
    }

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      issues.add('Password must contain special characters');
    } else {
      score += 2;
    }

    // Common password checks
    if (_isCommonPassword(password)) {
      issues.add('Password is too common');
      score = 0;
    }

    // Sequential characters check
    if (_hasSequentialCharacters(password)) {
      issues.add('Avoid sequential characters (123, abc, etc.)');
      score = Math.max(0, score - 1);
    }

    // Repeated characters check
    if (_hasRepeatedCharacters(password)) {
      issues.add('Avoid repeated characters (aaa, 111, etc.)');
      score = Math.max(0, score - 1);
    }

    PasswordStrength strength;
    if (issues.isNotEmpty || score < 4) {
      strength = PasswordStrength.weak;
    } else if (score < 6) {
      strength = PasswordStrength.medium;
    } else {
      strength = PasswordStrength.strong;
    }

    return PasswordValidationResult(
      strength: strength,
      score: score,
      issues: issues,
      isValid: issues.isEmpty && score >= 4,
    );
  }

  /// Check if password is in common passwords list
  static bool _isCommonPassword(String password) {
    final commonPasswords = [
      'password', 'password123', '123456', '123456789', 'qwerty',
      'abc123', 'password1', 'admin', 'letmein', 'welcome',
      'monkey', '1234567890', 'dragon', 'master', 'hello',
    ];
    
    return commonPasswords.contains(password.toLowerCase());
  }

  /// Check for sequential characters
  static bool _hasSequentialCharacters(String password) {
    final sequences = ['123', '234', '345', '456', '567', '678', '789',
                     'abc', 'bcd', 'cde', 'def', 'efg', 'fgh', 'ghi'];
    
    final lowerPassword = password.toLowerCase();
    return sequences.any((seq) => lowerPassword.contains(seq));
  }

  /// Check for repeated characters
  static bool _hasRepeatedCharacters(String password) {
    for (int i = 0; i < password.length - 2; i++) {
      if (password[i] == password[i + 1] && password[i] == password[i + 2]) {
        return true;
      }
    }
    return false;
  }

  /// Generate a secure password suggestion
  static String generateSecurePassword({int length = 16}) {
    const chars = 'abcdefghijklmnopqrstuvwxyz';
    const upperChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const numbers = '0123456789';
    const symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
    
    final random = DateTime.now().millisecondsSinceEpoch;
    var password = '';
    
    // Ensure at least one character from each category
    password += chars[random % chars.length];
    password += upperChars[random % upperChars.length];
    password += numbers[random % numbers.length];
    password += symbols[random % symbols.length];
    
    // Fill the rest randomly
    const allChars = chars + upperChars + numbers + symbols;
    for (int i = 4; i < length; i++) {
      password += allChars[(random + i) % allChars.length];
    }
    
    // Shuffle the password
    final chars_list = password.split('');
    for (int i = chars_list.length - 1; i > 0; i--) {
      final j = (random + i) % (i + 1);
      final temp = chars_list[i];
      chars_list[i] = chars_list[j];
      chars_list[j] = temp;
    }
    
    return chars_list.join('');
  }

  /// Clear all lockout data for user (admin function)
  static Future<void> clearLockoutData(String userId) async {
    try {
      await _secureStorage.delete(key: 'lockout_$userId');
      await _secureStorage.delete(key: 'lockout_count_$userId');
      print('Lockout data cleared for user: $userId');
    } catch (e) {
      print('Error clearing lockout data: $e');
    }
  }
}

/// Lockout status information
class LockoutStatus {
  final bool isLockedOut;
  final int failedAttempts;
  final DateTime? lockoutUntil;

  LockoutStatus({
    required this.isLockedOut,
    required this.failedAttempts,
    this.lockoutUntil,
  });

  /// Get remaining lockout time in minutes
  int get remainingLockoutMinutes {
    if (lockoutUntil == null) return 0;
    final remaining = lockoutUntil!.difference(DateTime.now()).inMinutes;
    return remaining > 0 ? remaining : 0;
  }

  /// Get remaining attempts before lockout
  int get remainingAttempts {
    return PasswordManagementService.maxFailedAttempts - failedAttempts;
  }

  @override
  String toString() {
    return 'LockoutStatus(isLockedOut: $isLockedOut, failedAttempts: $failedAttempts, lockoutUntil: $lockoutUntil)';
  }
}

/// Password validation result
class PasswordValidationResult {
  final PasswordStrength strength;
  final int score;
  final List<String> issues;
  final bool isValid;

  PasswordValidationResult({
    required this.strength,
    required this.score,
    required this.issues,
    required this.isValid,
  });

  @override
  String toString() {
    return 'PasswordValidationResult(strength: $strength, score: $score, isValid: $isValid, issues: ${issues.length})';
  }
}

/// Password strength levels
enum PasswordStrength {
  weak,
  medium,
  strong,
}

/// Math utility for max function
class Math {
  static int max(int a, int b) => a > b ? a : b;
}
