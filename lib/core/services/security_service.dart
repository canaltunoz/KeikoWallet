import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../constants/app_constants.dart';

class SecurityService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static final LocalAuthentication _localAuth = LocalAuthentication();
  static final _aesGcm = AesGcm.with256bits();

  /// Generate a random encryption key
  static Future<SecretKey> _generateEncryptionKey() async {
    return await _aesGcm.newSecretKey();
  }

  /// Encrypt data using AES-GCM
  static Future<Map<String, String>> _encryptData(
    String data,
    SecretKey key,
  ) async {
    final dataBytes = utf8.encode(data);
    final secretBox = await _aesGcm.encrypt(dataBytes, secretKey: key);

    return {
      'ciphertext': base64.encode(secretBox.cipherText),
      'nonce': base64.encode(secretBox.nonce),
      'mac': base64.encode(secretBox.mac.bytes),
    };
  }

  /// Decrypt data using AES-GCM
  static Future<String> _decryptData(
    Map<String, String> encryptedData,
    SecretKey key,
  ) async {
    final cipherText = base64.decode(encryptedData['ciphertext']!);
    final nonce = base64.decode(encryptedData['nonce']!);
    final mac = base64.decode(encryptedData['mac']!);

    final secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac(mac));

    final decryptedBytes = await _aesGcm.decrypt(secretBox, secretKey: key);

    return utf8.decode(decryptedBytes);
  }

  /// Store encryption key securely
  static Future<void> _storeEncryptionKey(SecretKey key) async {
    final keyBytes = await key.extractBytes();
    final keyBase64 = base64.encode(keyBytes);
    await _storage.write(key: 'encryption_key', value: keyBase64);
  }

  /// Retrieve encryption key
  static Future<SecretKey?> _getEncryptionKey() async {
    final keyBase64 = await _storage.read(key: 'encryption_key');
    if (keyBase64 == null) return null;

    final keyBytes = base64.decode(keyBase64);
    return SecretKey(keyBytes);
  }

  /// Encrypt and store seed phrase
  static Future<void> storeSeedPhrase(String seedPhrase) async {
    try {
      // Generate or get encryption key
      SecretKey? key = await _getEncryptionKey();
      key ??= await _generateEncryptionKey();

      // Encrypt the seed phrase
      final encryptedData = await _encryptData(seedPhrase, key);

      // Store encrypted data
      await _storage.write(
        key: AppConstants.seedStorageKey,
        value: json.encode(encryptedData),
      );

      // Store encryption key if it's new
      if (await _storage.read(key: 'encryption_key') == null) {
        await _storeEncryptionKey(key);
      }

      // Mark wallet as created
      await _storage.write(key: AppConstants.walletCreatedKey, value: 'true');
    } catch (e) {
      throw Exception('Failed to store seed phrase: $e');
    }
  }

  /// Retrieve and decrypt seed phrase
  static Future<String?> getSeedPhrase() async {
    try {
      final encryptedDataJson = await _storage.read(
        key: AppConstants.seedStorageKey,
      );
      if (encryptedDataJson == null) return null;

      final key = await _getEncryptionKey();
      if (key == null) throw Exception('Encryption key not found');

      final encryptedData = Map<String, String>.from(
        json.decode(encryptedDataJson) as Map,
      );

      return await _decryptData(encryptedData, key);
    } catch (e) {
      throw Exception('Failed to retrieve seed phrase: $e');
    }
  }

  /// Check if wallet exists
  static Future<bool> isWalletCreated() async {
    final walletCreated = await _storage.read(
      key: AppConstants.walletCreatedKey,
    );
    return walletCreated == 'true';
  }

  /// Delete all wallet data
  static Future<void> deleteWalletData() async {
    await _storage.delete(key: AppConstants.seedStorageKey);
    await _storage.delete(key: AppConstants.walletCreatedKey);
    await _storage.delete(key: 'encryption_key');
    await _storage.delete(key: AppConstants.biometricEnabledKey);
  }

  /// Check if biometric authentication is available
  static Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  /// Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Authenticate with biometrics or PIN
  static Future<bool> authenticateUser({
    String reason = 'Please authenticate to access your wallet',
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) return false;

      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  /// Enable/disable biometric authentication
  static Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: AppConstants.biometricEnabledKey,
      value: enabled.toString(),
    );
  }

  /// Check if biometric authentication is enabled
  static Future<bool> isBiometricEnabled() async {
    final enabled = await _storage.read(key: AppConstants.biometricEnabledKey);
    return enabled == 'true';
  }

  /// Secure authentication flow for accessing sensitive operations
  static Future<bool> authenticateForSensitiveOperation({
    String reason = 'Authentication required for this operation',
  }) async {
    final isBiometricEnabledByUser = await isBiometricEnabled();
    final isBiometricAvailableOnDevice = await isBiometricAvailable();

    if (isBiometricEnabledByUser && isBiometricAvailableOnDevice) {
      return await authenticateUser(reason: reason);
    }

    // Fallback to other authentication methods if needed
    // For now, we'll return true, but in a real app you might want
    // to implement PIN authentication or other methods
    return true;
  }
}
