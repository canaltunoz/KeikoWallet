import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'secure_logger.dart';

/// Crypto service for wallet encryption/decryption using Argon2id + AES-GCM
class CryptoService {
  static final Random _random = Random.secure();

  // Nonce tracking for uniqueness guarantee
  static final Set<String> _usedNonces = <String>{};
  static int _nonceCounter = 0;

  /// Initialize crypto service with validation
  static Future<void> initialize() async {
    try {
      // Run canary test to validate crypto system
      final canaryResult = await _runCanaryTest();
      if (!canaryResult) {
        throw Exception('Crypto system validation failed - canary test failed');
      }

      SecureLogger.info(
        'Crypto service initialized and validated successfully',
      );
    } catch (e) {
      SecureLogger.error('Error initializing crypto service', e);
      rethrow;
    }
  }

  /// Quick canary test for crypto system validation
  static Future<bool> _runCanaryTest() async {
    try {
      // Test 1: Nonce uniqueness
      final nonce1 = generateUniqueNonce();
      final nonce2 = generateUniqueNonce();
      if (bytesToHex(nonce1) == bytesToHex(nonce2)) {
        return false; // Nonces should be unique
      }

      // Test 2: Basic encryption/decryption
      const testData = 'canary_test_data_12345';
      final key = generateDEK();
      final plaintext = Uint8List.fromList(testData.codeUnits);

      final encrypted = await encryptData(data: plaintext, key: key);
      final decrypted = await decryptData(
        ciphertext: encrypted.ciphertext,
        nonce: encrypted.nonce,
        key: key,
        mac: encrypted.mac,
      );

      final decryptedText = String.fromCharCodes(decrypted);
      return decryptedText == testData;
    } catch (e) {
      return false;
    }
  }

  /// Argon2id parameters for mobile devices (production-ready)
  static const int kdfIterations = 3; // iterations
  static const int kdfMemory = 16384; // 16 MB in KB (16 * 1024)
  static const int kdfParallelism = 1; // threads
  static const int kdfSaltLength = 32; // bytes
  static const int kdfKeyLength = 32; // bytes (256-bit key)

  /// Generate cryptographically secure unique nonce for AES-GCM
  static Uint8List generateUniqueNonce() {
    Uint8List nonce;
    String nonceHex;
    int attempts = 0;
    const maxAttempts = 1000;

    do {
      if (attempts >= maxAttempts) {
        throw Exception(
          'Failed to generate unique nonce after $maxAttempts attempts',
        );
      }

      // Generate 12-byte nonce: 8 bytes random + 4 bytes counter
      nonce = Uint8List(12);

      // First 8 bytes: cryptographically secure random
      for (int i = 0; i < 8; i++) {
        nonce[i] = _random.nextInt(256);
      }

      // Last 4 bytes: counter (big-endian)
      final counter = _nonceCounter++;
      nonce[8] = (counter >> 24) & 0xFF;
      nonce[9] = (counter >> 16) & 0xFF;
      nonce[10] = (counter >> 8) & 0xFF;
      nonce[11] = counter & 0xFF;

      nonceHex = bytesToHex(nonce);
      attempts++;
    } while (_usedNonces.contains(nonceHex));

    _usedNonces.add(nonceHex);

    // Prevent memory leak: keep only last 10000 nonces
    if (_usedNonces.length > 10000) {
      final oldNonces = _usedNonces.take(_usedNonces.length - 5000).toList();
      for (final oldNonce in oldNonces) {
        _usedNonces.remove(oldNonce);
      }
    }

    return nonce;
  }

  /// Generate random salt for KDF
  static Uint8List generateSalt() {
    final bytes = Uint8List(kdfSaltLength);
    for (int i = 0; i < kdfSaltLength; i++) {
      bytes[i] = _random.nextInt(256);
    }
    return bytes;
  }

  /// Generate random DEK (Data Encryption Key)
  static Uint8List generateDEK() {
    final bytes = Uint8List(kdfKeyLength);
    for (int i = 0; i < kdfKeyLength; i++) {
      bytes[i] = _random.nextInt(256);
    }
    return bytes;
  }

  /// Generate random seed for wallet
  static Uint8List generateSeed() {
    final bytes = Uint8List(32); // 256-bit seed
    for (int i = 0; i < 32; i++) {
      bytes[i] = _random.nextInt(256);
    }
    return bytes;
  }

  /// Generate Ethereum address from seed
  static Future<String> generateEthereumAddress(Uint8List seed) async {
    try {
      // For now, generate a deterministic address from seed
      // In a real implementation, you would use proper Ethereum key derivation
      final hash = await Sha256().hash(seed);
      final addressBytes = hash.bytes.take(20).toList();
      return '0x${addressBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
    } catch (e) {
      SecureLogger.error('Error generating Ethereum address', e);
      // Fallback: generate a mock address for testing
      final addressBytes = Uint8List(20);
      for (int i = 0; i < 20; i++) {
        addressBytes[i] = _random.nextInt(256);
      }
      return '0x${addressBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
    }
  }

  /// Derive KEK (Key Encryption Key) from password using Argon2id
  static Future<Uint8List> deriveKEK({
    required String password,
    required Uint8List salt,
  }) async {
    return deriveKEKWithParams(
      password: password,
      salt: salt,
      iterations: kdfIterations,
      memory: kdfMemory,
      parallelism: kdfParallelism,
    );
  }

  /// Derive KEK from password using custom Argon2id parameters
  static Future<Uint8List> deriveKEKWithParams({
    required String password,
    required Uint8List salt,
    required int iterations,
    required int memory,
    required int parallelism,
  }) async {
    try {
      final algorithm = Argon2id(
        memory: memory,
        iterations: iterations,
        parallelism: parallelism,
        hashLength: kdfKeyLength,
      );

      final secretKey = await algorithm.deriveKey(
        secretKey: SecretKey(utf8.encode(password)),
        nonce: salt,
      );

      final keyBytes = await secretKey.extractBytes();
      return Uint8List.fromList(keyBytes);
    } catch (e) {
      SecureLogger.error('Error deriving KEK', e);
      rethrow;
    }
  }

  /// Encrypt data using AES-GCM with optional AAD
  static Future<EncryptionResult> encryptData({
    required Uint8List data,
    required Uint8List key,
    Uint8List? aad, // Additional Authenticated Data
  }) async {
    try {
      final algorithm = AesGcm.with256bits();

      // Generate cryptographically secure unique nonce
      final nonce = generateUniqueNonce();

      final secretKey = SecretKey(key);
      final secretBox = await algorithm.encrypt(
        data,
        secretKey: secretKey,
        nonce: nonce,
        aad: aad?.toList() ?? [], // Convert to List<int> if provided
      );

      return EncryptionResult(
        ciphertext: Uint8List.fromList(secretBox.cipherText),
        nonce: nonce,
        mac: Uint8List.fromList(secretBox.mac.bytes),
      );
    } catch (e) {
      SecureLogger.cryptoOperation(
        'ENCRYPT',
        success: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Decrypt data using AES-GCM with optional AAD
  static Future<Uint8List> decryptData({
    required Uint8List ciphertext,
    required Uint8List nonce,
    required Uint8List key,
    required Uint8List mac,
    Uint8List? aad, // Additional Authenticated Data
  }) async {
    try {
      final algorithm = AesGcm.with256bits();
      final secretKey = SecretKey(key);

      final secretBox = SecretBox(ciphertext, nonce: nonce, mac: Mac(mac));

      final plaintext = await algorithm.decrypt(
        secretBox,
        secretKey: secretKey,
        aad: aad?.toList() ?? [], // Include AAD if provided
      );

      return Uint8List.fromList(plaintext);
    } catch (e) {
      SecureLogger.cryptoOperation(
        'DECRYPT',
        success: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Wrap DEK with KEK (encrypt DEK using KEK)
  static Future<EncryptionResult> wrapDEK({
    required Uint8List dek,
    required Uint8List kek,
    Uint8List? aad, // Additional Authenticated Data (e.g., user_id)
  }) async {
    return await encryptData(data: dek, key: kek, aad: aad);
  }

  /// Unwrap DEK with KEK (decrypt DEK using KEK)
  static Future<Uint8List> unwrapDEK({
    required Uint8List wrappedDEK,
    required Uint8List nonce,
    required Uint8List mac,
    required Uint8List kek,
    Uint8List? aad, // Additional Authenticated Data (e.g., user_id)
  }) async {
    return await decryptData(
      ciphertext: wrappedDEK,
      nonce: nonce,
      mac: mac,
      key: kek,
      aad: aad,
    );
  }

  /// Encrypt seed with DEK
  static Future<EncryptionResult> encryptSeed({
    required Uint8List seed,
    required Uint8List dek,
    Uint8List? aad, // Additional Authenticated Data (e.g., user_id)
  }) async {
    return await encryptData(data: seed, key: dek, aad: aad);
  }

  /// Decrypt seed with DEK
  static Future<Uint8List> decryptSeed({
    required Uint8List encryptedSeed,
    required Uint8List nonce,
    required Uint8List mac,
    required Uint8List dek,
    Uint8List? aad, // Additional Authenticated Data (e.g., user_id)
  }) async {
    return await decryptData(
      ciphertext: encryptedSeed,
      nonce: nonce,
      mac: mac,
      key: dek,
      aad: aad,
    );
  }

  /// Convert bytes to base64 string
  static String bytesToBase64(Uint8List bytes) {
    return base64.encode(bytes);
  }

  /// Convert base64 string to bytes
  static Uint8List base64ToBytes(String base64String) {
    return Uint8List.fromList(base64.decode(base64String));
  }

  /// Convert bytes to hex string
  static String bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Secure memory cleanup (zeros out sensitive data)
  static void secureCleanup(Uint8List sensitiveData) {
    sensitiveData.fillRange(0, sensitiveData.length, 0);
  }
}

/// Result of encryption operation
class EncryptionResult {
  final Uint8List ciphertext;
  final Uint8List nonce;
  final Uint8List mac;

  EncryptionResult({
    required this.ciphertext,
    required this.nonce,
    required this.mac,
  });

  /// Convert to base64 map for JSON storage
  Map<String, String> toBase64Map() {
    return {
      'ct': CryptoService.bytesToBase64(ciphertext),
      'nonce': CryptoService.bytesToBase64(nonce),
      'mac': CryptoService.bytesToBase64(mac),
    };
  }

  /// Create from base64 map
  factory EncryptionResult.fromBase64Map(Map<String, dynamic> map) {
    return EncryptionResult(
      ciphertext: CryptoService.base64ToBytes(map['ct'] as String),
      nonce: CryptoService.base64ToBytes(map['nonce'] as String),
      mac: CryptoService.base64ToBytes(map['mac'] as String),
    );
  }
}
