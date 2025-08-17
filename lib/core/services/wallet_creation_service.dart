import 'dart:convert';
import 'dart:typed_data';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;
import 'crypto_service.dart';
import 'wallet_blob_service.dart';
import 'database_service.dart';

/// Service for creating and managing wallets
class WalletCreationService {
  /// Check if user has existing wallet
  static Future<bool> hasExistingWallet(String userId) async {
    try {
      return await WalletBlobService.hasWallet(userId);
    } catch (e) {
      print('Error checking existing wallet: $e');
      return false;
    }
  }

  /// Create a new wallet with password
  static Future<WalletCreationResult> createWallet({
    required String userId,
    required String password,
    String? customMnemonic,
  }) async {
    try {
      print(
        'WalletCreationService: Starting wallet creation for user: $userId',
      );

      // 1. Generate or validate mnemonic
      String mnemonic;
      if (customMnemonic != null) {
        if (!bip39.validateMnemonic(customMnemonic)) {
          throw ArgumentError('Invalid mnemonic phrase');
        }
        mnemonic = customMnemonic;
        print('WalletCreationService: Using provided mnemonic');
      } else {
        mnemonic = bip39.generateMnemonic();
        print('WalletCreationService: Generated new mnemonic');
      }

      // 2. Generate seed from mnemonic (BIP39)
      final masterSeed = bip39.mnemonicToSeed(mnemonic);
      print('WalletCreationService: Generated master seed from mnemonic');

      // 3. Derive private key using BIP32 HD derivation
      final hdWallet = bip32.BIP32.fromSeed(masterSeed);
      final derivationPath = "m/44'/60'/0'/0/0"; // Ethereum standard path
      final derivedNode = hdWallet.derivePath(derivationPath);
      final privateKey = derivedNode.privateKey!;
      print(
        'WalletCreationService: Derived private key using BIP32 ($derivationPath)',
      );

      // 3. Generate salt for KDF
      final salt = CryptoService.generateSalt();
      print('WalletCreationService: Generated salt for KDF');

      // 4. Derive KEK from password
      final kek = await CryptoService.deriveKEK(password: password, salt: salt);
      print('WalletCreationService: Derived KEK from password');

      // 5. Generate DEK
      final dek = CryptoService.generateDEK();
      print('WalletCreationService: Generated DEK');

      // 6. Wrap DEK with KEK (with user ID as AAD)
      final userIdBytes = utf8.encode(userId);
      final wrappedDEK = await CryptoService.wrapDEK(
        dek: dek,
        kek: kek,
        aad: Uint8List.fromList(userIdBytes),
      );
      print('WalletCreationService: Wrapped DEK with KEK (AAD: user_id)');

      // 7. Encrypt private key with DEK (with user ID as AAD)
      final encryptedSeed = await CryptoService.encryptSeed(
        seed: privateKey,
        dek: dek,
        aad: Uint8List.fromList(userIdBytes),
      );
      print(
        'WalletCreationService: Encrypted private key with DEK (AAD: user_id)',
      );

      // 8. Create wallet blob with versioned parameters
      final walletBlob = {
        'version': 1,
        'created_at': DateTime.now().toIso8601String(),
        'format_version': '1.0.0', // Blob format version
        'crypto_version': '1.0.0', // Crypto implementation version
        'kdf': {
          'algorithm': 'argon2id',
          'version': '1.3', // Argon2id version
          'salt': CryptoService.bytesToBase64(salt),
          'iterations': CryptoService.kdfIterations,
          'memory': CryptoService.kdfMemory,
          'parallelism': CryptoService.kdfParallelism,
        },
        'wrapped_dek': {
          ...wrappedDEK.toBase64Map(),
          'algorithm': 'aes-256-gcm',
          'version': '1.0.0',
        },
        'encrypted_privkey': {
          ...encryptedSeed.toBase64Map(),
          'algorithm': 'aes-256-gcm',
          'version': '1.0.0',
        },
        'metadata': {
          'name': 'Keiko Wallet',
          'type': 'hd_wallet',
          'coin_type': 60, // Ethereum
          'derivation_path': "m/44'/60'/0'/0/0",
          'bip32_version': '2.0.0',
          'bip39_version': '1.0.6',
        },
      };

      // 9. Save wallet blob to database
      final saved = await WalletBlobService.saveWalletBlob(
        userId: userId,
        walletData: walletBlob,
      );

      if (!saved) {
        throw Exception('Failed to save wallet to database');
      }

      print('WalletCreationService: Wallet saved to database successfully');

      // 10. Cleanup sensitive data
      CryptoService.secureCleanup(privateKey);
      CryptoService.secureCleanup(kek);
      CryptoService.secureCleanup(dek);

      return WalletCreationResult(
        success: true,
        mnemonic: mnemonic,
        walletId: userId,
      );
    } catch (e) {
      print('WalletCreationService: Error creating wallet: $e');
      return WalletCreationResult(success: false, error: e.toString());
    }
  }

  /// Import existing wallet from mnemonic
  static Future<WalletCreationResult> importWallet({
    required String userId,
    required String password,
    required String mnemonic,
  }) async {
    return await createWallet(
      userId: userId,
      password: password,
      customMnemonic: mnemonic,
    );
  }

  /// Validate mnemonic phrase
  static bool validateMnemonic(String mnemonic) {
    try {
      return bip39.validateMnemonic(mnemonic.trim());
    } catch (e) {
      return false;
    }
  }

  /// Generate a new mnemonic phrase
  static String generateMnemonic() {
    return bip39.generateMnemonic();
  }

  /// Check if user already has a wallet
  static Future<bool> hasWallet(String userId) async {
    return await WalletBlobService.hasWallet(userId);
  }

  /// Delete wallet for user
  static Future<bool> deleteWallet(String userId) async {
    try {
      return await WalletBlobService.deleteWallet(userId);
    } catch (e) {
      print('WalletCreationService: Error deleting wallet: $e');
      return false;
    }
  }

  /// Get wallet metadata without decrypting
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
      print('WalletCreationService: Error getting wallet metadata: $e');
      return null;
    }
  }
}

/// Result of wallet creation operation
class WalletCreationResult {
  final bool success;
  final String? mnemonic;
  final String? walletId;
  final String? error;

  WalletCreationResult({
    required this.success,
    this.mnemonic,
    this.walletId,
    this.error,
  });

  @override
  String toString() {
    return 'WalletCreationResult(success: $success, walletId: $walletId, error: $error)';
  }
}
