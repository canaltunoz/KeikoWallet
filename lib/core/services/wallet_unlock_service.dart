import 'dart:convert';
import 'dart:typed_data';
import 'crypto_service.dart';
import 'wallet_blob_service.dart';
import 'password_management_service.dart';
import 'biometric_service.dart';

/// Service for unlocking and accessing wallets
class WalletUnlockService {
  /// Unlock wallet with password
  static Future<WalletUnlockResult> unlockWallet({
    required String userId,
    required String password,
  }) async {
    try {
      print('WalletUnlockService: Starting wallet unlock for user: $userId');

      // 1. Check lockout status
      final lockoutStatus = await PasswordManagementService.getLockoutStatus(
        userId,
      );
      if (lockoutStatus.isLockedOut) {
        return WalletUnlockResult(
          success: false,
          error:
              'Account is locked. Try again in ${lockoutStatus.remainingLockoutMinutes} minutes.',
          lockoutStatus: lockoutStatus,
        );
      }

      // 2. Get wallet blob from database
      final walletData = await WalletBlobService.getWalletData(userId);
      if (walletData == null) {
        return WalletUnlockResult(
          success: false,
          error: 'Wallet not found for user',
        );
      }

      print('WalletUnlockService: Wallet blob retrieved from database');

      // 2. Extract KDF parameters
      final kdfData = walletData['kdf'] as Map<String, dynamic>;
      final salt = CryptoService.base64ToBytes(kdfData['salt'] as String);

      print('WalletUnlockService: Extracted KDF parameters');

      // 3. Derive KEK from password
      final kek = await CryptoService.deriveKEK(password: password, salt: salt);
      print('WalletUnlockService: Derived KEK from password');

      // 4. Extract wrapped DEK
      final wrappedDEKData = walletData['wrapped_dek'] as Map<String, dynamic>;
      final wrappedDEK = EncryptionResult.fromBase64Map(wrappedDEKData);

      print('WalletUnlockService: Extracted wrapped DEK');

      // 5. Unwrap DEK with KEK (with user ID as AAD)
      final userIdBytes = utf8.encode(userId);
      final dek = await CryptoService.unwrapDEK(
        wrappedDEK: wrappedDEK.ciphertext,
        nonce: wrappedDEK.nonce,
        mac: wrappedDEK.mac,
        kek: kek,
        aad: Uint8List.fromList(userIdBytes),
      );
      print('WalletUnlockService: Unwrapped DEK successfully');

      // 6. Extract encrypted private key
      final encryptedSeedData =
          walletData['encrypted_privkey'] as Map<String, dynamic>;
      final encryptedSeed = EncryptionResult.fromBase64Map(encryptedSeedData);

      print('WalletUnlockService: Extracted encrypted seed');

      // 7. Decrypt seed with DEK (with user ID as AAD)
      final seed = await CryptoService.decryptSeed(
        encryptedSeed: encryptedSeed.ciphertext,
        nonce: encryptedSeed.nonce,
        mac: encryptedSeed.mac,
        dek: dek,
        aad: Uint8List.fromList(userIdBytes),
      );
      print('WalletUnlockService: Decrypted seed successfully');

      // 8. Create wallet session
      final walletSession = WalletSession(
        userId: userId,
        seed: seed,
        metadata: walletData['metadata'] as Map<String, dynamic>,
        createdAt: DateTime.parse(walletData['created_at'] as String),
        version: walletData['version'] as int,
      );

      // 9. Cleanup sensitive data
      CryptoService.secureCleanup(kek);
      CryptoService.secureCleanup(dek);

      print('WalletUnlockService: Wallet unlocked successfully');

      // Record successful attempt
      await PasswordManagementService.recordSuccessfulAttempt(userId);

      return WalletUnlockResult(success: true, walletSession: walletSession);
    } catch (e) {
      print('WalletUnlockService: Error unlocking wallet: $e');

      // Determine error type and record failed attempt if it's a password error
      String errorMessage;
      bool isPasswordError = false;

      if (e.toString().contains('SecretBoxAuthenticationError') ||
          e.toString().contains('MAC')) {
        errorMessage = 'Invalid password';
        isPasswordError = true;
      } else if (e.toString().contains('not found')) {
        errorMessage = 'Wallet not found';
      } else {
        errorMessage = 'Failed to unlock wallet: ${e.toString()}';
      }

      // Record failed attempt for password errors
      LockoutStatus? lockoutStatus;
      if (isPasswordError) {
        lockoutStatus = await PasswordManagementService.recordFailedAttempt(
          userId,
        );
        if (lockoutStatus.isLockedOut) {
          errorMessage =
              'Too many failed attempts. Account locked for ${lockoutStatus.remainingLockoutMinutes} minutes.';
        } else {
          errorMessage =
              'Invalid password. ${lockoutStatus.remainingAttempts} attempts remaining.';
        }
      }

      return WalletUnlockResult(
        success: false,
        error: errorMessage,
        lockoutStatus: lockoutStatus,
      );
    }
  }

  /// Unlock wallet with biometric authentication
  static Future<WalletUnlockResult> unlockWalletWithBiometrics({
    required String userId,
    String reason = 'Authenticate to unlock your wallet',
  }) async {
    try {
      // Check if biometric is enabled
      final isEnabled = await BiometricService.isBiometricEnabled(userId);
      if (!isEnabled) {
        return WalletUnlockResult(
          success: false,
          error: 'Biometric authentication is not enabled',
        );
      }

      // Unlock with biometrics
      final biometricResult = await BiometricService.unlockWithBiometrics(
        userId: userId,
        reason: reason,
      );

      if (!biometricResult.success) {
        return WalletUnlockResult(success: false, error: biometricResult.error);
      }

      // Use retrieved password to unlock wallet
      return await unlockWallet(
        userId: userId,
        password: biometricResult.password!,
      );
    } catch (e) {
      return WalletUnlockResult(
        success: false,
        error: 'Biometric unlock failed: $e',
      );
    }
  }

  /// Verify password without full unlock
  static Future<bool> verifyPassword({
    required String userId,
    required String password,
  }) async {
    try {
      final result = await unlockWallet(userId: userId, password: password);
      if (result.success && result.walletSession != null) {
        // Cleanup the session immediately
        result.walletSession!.dispose();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check if wallet exists for user
  static Future<bool> hasWallet(String userId) async {
    return await WalletBlobService.hasWallet(userId);
  }

  /// Get wallet metadata without unlocking
  static Future<Map<String, dynamic>?> getWalletMetadata(String userId) async {
    try {
      final walletData = await WalletBlobService.getWalletData(userId);
      if (walletData != null) {
        return {
          'version': walletData['version'],
          'created_at': walletData['created_at'],
          'metadata': walletData['metadata'],
        };
      }
      return null;
    } catch (e) {
      print('WalletUnlockService: Error getting wallet metadata: $e');
      return null;
    }
  }
}

/// Result of wallet unlock operation
class WalletUnlockResult {
  final bool success;
  final WalletSession? walletSession;
  final String? error;
  final LockoutStatus? lockoutStatus;

  WalletUnlockResult({
    required this.success,
    this.walletSession,
    this.error,
    this.lockoutStatus,
  });

  @override
  String toString() {
    return 'WalletUnlockResult(success: $success, error: $error, lockoutStatus: $lockoutStatus)';
  }
}

/// Active wallet session with decrypted data
class WalletSession {
  final String userId;
  final Uint8List seed;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final int version;
  final DateTime unlockedAt;

  WalletSession({
    required this.userId,
    required this.seed,
    required this.metadata,
    required this.createdAt,
    required this.version,
  }) : unlockedAt = DateTime.now();

  /// Get wallet name
  String get name => metadata['name'] as String? ?? 'Keiko Wallet';

  /// Get wallet type
  String get type => metadata['type'] as String? ?? 'hd_wallet';

  /// Get coin type
  int get coinType => metadata['coin_type'] as int? ?? 60;

  /// Dispose of sensitive data
  void dispose() {
    CryptoService.secureCleanup(seed);
    print('WalletSession: Disposed of sensitive data');
  }

  @override
  String toString() {
    return 'WalletSession(userId: $userId, name: $name, type: $type, unlockedAt: $unlockedAt)';
  }
}
