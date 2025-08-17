# Non-Custodial Cüzdan Güvenlik Sistemi v2.1

Bu doküman, **Google Login sonrası** kullanıcıya ait cüzdanın **client-side şifreleme** ile korunması, **SQLite** veritabanında saklanması, **biometric authentication** ve **mnemonic recovery** akışlarını **güvenlik iyileştirmeleri** ile detaylandırır.

---

## 🔒 Güvenlik İyileştirmeleri v2.1

### 1. Nonce Benzersizlik Garantisi
- **Hybrid Nonce**: 8 byte secure random + 4 byte monotonic counter
- **Uniqueness Tracking**: Memory set ile nonce tekrarı kontrolü
- **Memory Management**: 10K nonce limit ile memory leak önleme
- **Canary Validation**: Başlangıçta nonce uniqueness testi

### 2. Parametre Versiyonlaması
- **Format Versioning**: `format_version`, `crypto_version`
- **Algorithm Versioning**: Her algoritma için versiyon bilgisi
- **Migration Safety**: Geriye uyumlu versiyon kontrolü
- **Future-Proof**: Parametre değişikliklerinde veri kaybı önleme

### 3. Test Vektörleri ve Validation
- **Canary Tests**: Sistem başlangıcında hızlı validation
- **Test Vectors**: Bilinen giriş/çıkış test verileri
- **End-to-End Testing**: Tam wallet encryption/decryption
- **Regression Testing**: Versiyon uyumluluğu testleri

### 4. Güvenli Logging Sistemi
- **Sensitive Data Filtering**: Password, key, seed pattern filtreleme
- **Pattern Detection**: Base64, hex string redaction
- **User Privacy**: User ID hashing
- **Crypto Operation Logging**: Güvenli event tracking

---

## 1. Teknik Detaylar (Güncellenmiş)

### Anahtar Boyutları
- **Seed/PrivKey**: 32 byte (ECDSA/Ethereum için secp256k1 privKey)
- **DEK (Data Encryption Key)**: 32 byte (AES-256 key)
- **KEK (Key Encryption Key)**: 32 byte (KDF sonucu)
- **Mnemonic**: 12/24 kelime BIP39 standardı
- **Nonce**: 12 byte (8 byte random + 4 byte counter)

### KDF (Key Derivation Function) - Güçlendirilmiş
- **Algoritma**: Argon2id (Argon2 familyasından hybrid)
- **Parametreler (production-ready)**:
  - memory (`memLimit`): 128 MB (134,217,728 bayt) - güçlü güvenlik
  - iterations (`opsLimit`): 3 (zaman maliyeti)
  - parallelism (`p`): 1 (mobil cihazlarda dengeli)
- **Salt**: 32 byte rastgele, sabit, gizli olmayan değer
- **Versioning**: Argon2id v1.3 ile uyumlu

### AEAD (Authenticated Encryption with Associated Data) - AAD Desteği
- **Seçilen Algoritma**: `AES-256-GCM`
  - **Nonce**: 12 byte benzersiz (hybrid generation)
  - **Auth Tag (MAC)**: 16 byte (ayrı field olarak saklanır)
  - **AAD Support**: User ID binding ile context security
- **Güvenlik Avantajları**:
  - Donanım hızlandırması (ARM/Intel AES-NI)
  - User-specific binding (AAD ile)
  - Nonce uniqueness guarantee

---

## 2. Database Schema (Versiyonlu)

### SQLite Tablosu
```sql
CREATE TABLE wallet_blobs (
  user_id TEXT PRIMARY KEY,           -- Google User ID
  blob_json TEXT NOT NULL,            -- Şifrelenmiş wallet blob'u
  created_at INTEGER NOT NULL,        -- Unix timestamp
  updated_at INTEGER NOT NULL         -- Unix timestamp
);
```

### Blob Formatı v2.1 (Güvenlik İyileştirmeli)
```json
{
  "version": 1,
  "format_version": "2.1.0",
  "crypto_version": "2.1.0",
  "created_at": "2025-08-17T20:58:23.4883406",
  "kdf": {
    "algorithm": "argon2id",
    "version": "1.3",
    "salt": "base64_encoded_32_bytes",
    "iterations": 3,
    "memory": 134217728,
    "parallelism": 1
  },
  "wrapped_dek": {
    "ct": "base64_encoded_ciphertext",
    "nonce": "base64_encoded_12_bytes_unique",
    "mac": "base64_encoded_16_bytes",
    "algorithm": "aes-256-gcm",
    "version": "2.1.0"
  },
  "encrypted_privkey": {
    "ct": "base64_encoded_ciphertext",
    "nonce": "base64_encoded_12_bytes_unique",
    "mac": "base64_encoded_16_bytes",
    "algorithm": "aes-256-gcm", 
    "version": "2.1.0"
  },
  "metadata": {
    "name": "Keiko Wallet",
    "type": "hd_wallet",
    "coin_type": 60,
    "derivation_path": "m/44'/60'/0'/0/0",
    "bip32_version": "2.0.0",
    "bip39_version": "1.0.6",
    "aad_context": "user_id_bound"
  }
}
```

---

## 3. Güvenlik Katmanları (7 Katman)

### Katman 1: Password Protection
- ✅ Argon2id KDF (brute force koruması)
- ✅ 32-byte salt (rainbow table koruması)
- ✅ 128 MB memory (güçlü parametre)
- ✅ Versioned parameters

### Katman 2: Double Encryption + AAD
- ✅ KEK → DEK şifreleme (password layer)
- ✅ DEK → PrivKey şifreleme (data layer)
- ✅ User ID binding (AAD context)
- ✅ Benzersiz nonce'lar

### Katman 3: Authentication
- ✅ AES-256-GCM MAC (integrity check)
- ✅ Tamper detection
- ✅ Authenticated encryption
- ✅ Context binding (AAD)

### Katman 4: Storage Security
- ✅ Encrypted blob storage
- ✅ No plaintext keys in database
- ✅ User-specific encryption
- ✅ Versioned format

### Katman 5: Nonce Security
- ✅ Cryptographically secure random (8 bytes)
- ✅ Monotonic counter (4 bytes)
- ✅ Uniqueness tracking (memory set)
- ✅ Memory leak prevention

### Katman 6: Version Safety
- ✅ Format versioning (migration safety)
- ✅ Algorithm versioning (compatibility)
- ✅ Parameter versioning (future-proof)
- ✅ Backward compatibility

### Katman 7: Logging Security
- ✅ Sensitive data filtering
- ✅ Pattern-based redaction
- ✅ User ID hashing
- ✅ Crypto operation logging

---

## 4. Test ve Validation Sistemi

### Canary Tests (Başlangıç)
```dart
await CryptoService.initialize(); // Otomatik canary test

// Test edilen:
✅ Nonce uniqueness
✅ Basic encryption/decryption  
✅ System integrity
```

### Comprehensive Test Suite
```dart
final result = await CryptoTestService.runFullValidation();

// Test bileşenleri:
✅ AES-GCM encryption/decryption
✅ Argon2id KDF deterministic
✅ Nonce uniqueness (1000 iteration)
✅ End-to-end wallet encryption
✅ Version compatibility
```

### Test Vectors
```dart
{
  'aes_gcm_test': {
    'key': 'AAAA...', // 32 zero bytes
    'plaintext': 'SGVsbG8gV29ybGQ=', // "Hello World"
    'aad': 'dGVzdF9hYWQ=', // "test_aad"
  },
  'nonce_uniqueness': {
    'iterations': 1000,
    'expected_unique_count': 1000,
  }
}
```

---

## 5. Güvenli Logging

### Sensitive Data Protection
```dart
// Hassas veri asla loglanmaz
SecureLogger.info('Processing password: mySecret123');
// Output: [INFO] Processing [REDACTED_PASSWORD]: [REDACTED]

SecureLogger.cryptoOperation('ENCRYPT', success: true);
// Output: [INFO] Crypto operation: ENCRYPT - SUCCESS
```

### Pattern Detection
- **Password patterns**: `password`, `secret`, `key`
- **Base64 strings**: `[A-Za-z0-9+/]{20,}={0,2}`
- **Hex strings**: `0x[a-fA-F0-9]{16,}`
- **User ID hashing**: Privacy için hash'leme

---

## 6. Performans Metrikleri (Güncellenmiş)

### Şifreleme Süresi
- 🔧 Argon2id KDF (128 MB): ~400-800ms
- 🔐 AES-256-GCM (DEK): ~1-2ms
- 🔐 AES-256-GCM (PrivKey): ~1-2ms
- 🎲 Unique Nonce Generation: ~0.1ms
- 📄 JSON Serialization: ~1ms
- **Toplam: ~403-805ms**

### Memory Kullanımı
- 🧠 Argon2id: ~128MB (geçici)
- 💾 Blob Storage: ~2-3KB (versioned)
- 🔑 Key Storage: ~96 bytes (geçici)
- 📝 Nonce Tracking: ~10KB (10K nonces)

---

## 7. Migration ve Uyumluluk

### Version Migration
```dart
// Otomatik versiyon kontrolü
if (blobVersion < currentVersion) {
  await migrateBlob(blob, blobVersion, currentVersion);
}
```

### Backward Compatibility
- **v1.0.0 → v2.1.0**: Otomatik migration
- **Parameter changes**: Güvenli upgrade
- **Algorithm updates**: Versioned support

---

Bu v2.1 implementasyonu, **production-ready güvenlik** standartlarına uygun, **test edilmiş** ve **gelecek-uyumlu** bir çözüm sunar.
