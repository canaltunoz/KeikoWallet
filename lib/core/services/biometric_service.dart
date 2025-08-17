import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

/// Service for biometric authentication
class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Check if biometric authentication is available
  static Future<BiometricAvailability> checkBiometricAvailability() async {
    try {
      // Check if device supports biometrics
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) {
        return BiometricAvailability(
          isAvailable: false,
          reason: 'Biometric authentication is not available on this device',
        );
      }

      // Check if device is enrolled
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!isDeviceSupported) {
        return BiometricAvailability(
          isAvailable: false,
          reason: 'Device does not support biometric authentication',
        );
      }

      // Get available biometric types
      final List<BiometricType> availableBiometrics = 
          await _localAuth.getAvailableBiometrics();

      if (availableBiometrics.isEmpty) {
        return BiometricAvailability(
          isAvailable: false,
          reason: 'No biometric methods are enrolled on this device',
        );
      }

      return BiometricAvailability(
        isAvailable: true,
        availableBiometrics: availableBiometrics,
      );
    } catch (e) {
      print('Error checking biometric availability: $e');
      return BiometricAvailability(
        isAvailable: false,
        reason: 'Error checking biometric availability: $e',
      );
    }
  }

  /// Authenticate using biometrics
  static Future<BiometricAuthResult> authenticateWithBiometrics({
    String reason = 'Please authenticate to access your wallet',
  }) async {
    try {
      final availability = await checkBiometricAvailability();
      if (!availability.isAvailable) {
        return BiometricAuthResult(
          success: false,
          error: availability.reason,
        );
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        return BiometricAuthResult(success: true);
      } else {
        return BiometricAuthResult(
          success: false,
          error: 'Biometric authentication was cancelled or failed',
        );
      }
    } catch (e) {
      print('Error during biometric authentication: $e');
      return BiometricAuthResult(
        success: false,
        error: 'Biometric authentication error: $e',
      );
    }
  }

  /// Enable biometric authentication for user
  static Future<bool> enableBiometricAuth({
    required String userId,
    required String password,
  }) async {
    try {
      // First verify biometrics are available
      final availability = await checkBiometricAvailability();
      if (!availability.isAvailable) {
        print('Cannot enable biometric auth: ${availability.reason}');
        return false;
      }

      // Authenticate with biometrics to confirm setup
      final authResult = await authenticateWithBiometrics(
        reason: 'Authenticate to enable biometric login',
      );

      if (!authResult.success) {
        print('Biometric authentication failed during setup');
        return false;
      }

      // Store encrypted password for biometric access
      final biometricData = {
        'enabled': true,
        'user_id': userId,
        'setup_date': DateTime.now().toIso8601String(),
        'biometric_types': availability.availableBiometrics
            ?.map((type) => type.toString())
            .toList(),
      };

      await _secureStorage.write(
        key: 'biometric_$userId',
        value: json.encode(biometricData),
      );

      // Store password hash for biometric unlock
      await _secureStorage.write(
        key: 'biometric_password_$userId',
        value: password, // In production, this should be encrypted
      );

      print('Biometric authentication enabled for user: $userId');
      return true;
    } catch (e) {
      print('Error enabling biometric authentication: $e');
      return false;
    }
  }

  /// Disable biometric authentication for user
  static Future<bool> disableBiometricAuth(String userId) async {
    try {
      await _secureStorage.delete(key: 'biometric_$userId');
      await _secureStorage.delete(key: 'biometric_password_$userId');
      print('Biometric authentication disabled for user: $userId');
      return true;
    } catch (e) {
      print('Error disabling biometric authentication: $e');
      return false;
    }
  }

  /// Check if biometric authentication is enabled for user
  static Future<bool> isBiometricEnabled(String userId) async {
    try {
      final biometricData = await _secureStorage.read(key: 'biometric_$userId');
      if (biometricData == null) return false;

      final data = json.decode(biometricData) as Map<String, dynamic>;
      return data['enabled'] as bool? ?? false;
    } catch (e) {
      print('Error checking biometric status: $e');
      return false;
    }
  }

  /// Authenticate user with biometrics and get password
  static Future<BiometricUnlockResult> unlockWithBiometrics({
    required String userId,
    String reason = 'Authenticate to unlock your wallet',
  }) async {
    try {
      // Check if biometric is enabled for user
      final isEnabled = await isBiometricEnabled(userId);
      if (!isEnabled) {
        return BiometricUnlockResult(
          success: false,
          error: 'Biometric authentication is not enabled for this user',
        );
      }

      // Authenticate with biometrics
      final authResult = await authenticateWithBiometrics(reason: reason);
      if (!authResult.success) {
        return BiometricUnlockResult(
          success: false,
          error: authResult.error,
        );
      }

      // Retrieve stored password
      final password = await _secureStorage.read(key: 'biometric_password_$userId');
      if (password == null) {
        return BiometricUnlockResult(
          success: false,
          error: 'Biometric data not found. Please re-enable biometric authentication.',
        );
      }

      return BiometricUnlockResult(
        success: true,
        password: password,
      );
    } catch (e) {
      print('Error during biometric unlock: $e');
      return BiometricUnlockResult(
        success: false,
        error: 'Biometric unlock error: $e',
      );
    }
  }

  /// Get biometric information for user
  static Future<BiometricInfo?> getBiometricInfo(String userId) async {
    try {
      final biometricData = await _secureStorage.read(key: 'biometric_$userId');
      if (biometricData == null) return null;

      final data = json.decode(biometricData) as Map<String, dynamic>;
      return BiometricInfo(
        isEnabled: data['enabled'] as bool? ?? false,
        setupDate: DateTime.parse(data['setup_date'] as String),
        biometricTypes: (data['biometric_types'] as List<dynamic>?)
            ?.map((type) => type.toString())
            .toList() ?? [],
      );
    } catch (e) {
      print('Error getting biometric info: $e');
      return null;
    }
  }
}

/// Biometric availability information
class BiometricAvailability {
  final bool isAvailable;
  final String? reason;
  final List<BiometricType>? availableBiometrics;

  BiometricAvailability({
    required this.isAvailable,
    this.reason,
    this.availableBiometrics,
  });

  @override
  String toString() {
    return 'BiometricAvailability(isAvailable: $isAvailable, reason: $reason, types: $availableBiometrics)';
  }
}

/// Biometric authentication result
class BiometricAuthResult {
  final bool success;
  final String? error;

  BiometricAuthResult({
    required this.success,
    this.error,
  });

  @override
  String toString() {
    return 'BiometricAuthResult(success: $success, error: $error)';
  }
}

/// Biometric unlock result with password
class BiometricUnlockResult {
  final bool success;
  final String? password;
  final String? error;

  BiometricUnlockResult({
    required this.success,
    this.password,
    this.error,
  });

  @override
  String toString() {
    return 'BiometricUnlockResult(success: $success, error: $error)';
  }
}

/// Biometric information for user
class BiometricInfo {
  final bool isEnabled;
  final DateTime setupDate;
  final List<String> biometricTypes;

  BiometricInfo({
    required this.isEnabled,
    required this.setupDate,
    required this.biometricTypes,
  });

  @override
  String toString() {
    return 'BiometricInfo(isEnabled: $isEnabled, setupDate: $setupDate, types: $biometricTypes)';
  }
}
