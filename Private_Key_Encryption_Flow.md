# Private Key Şifreleme ve Çözme Akışı

Bu doküman, kullanıcının private key'inin nasıl şifrelendiği ve çözüldüğü sürecini adım adım açıklar.

---

## 🔐 Şifreleme Akışı (Encryption Flow)

### Adım 1: Kullanıcı Girdileri

```
📱 Kullanıcı → Password: "MySecurePassword123!"
🎲 Sistem → Mnemonic: "abandon ability about above absent absorb abstract absurd abuse access accident account"
```

### Adım 2: Mnemonic'ten Private Key Üretimi

```
🔑 Mnemonic → BIP39 → Seed (512-bit)
📊 Seed: 0x1a2b3c4d5e6f7890abcdef1234567890abcdef1234567890abcdef1234567890...
🔐 Seed → BIP32 HD Derivation → Private Key (32-byte)
📍 Derivation Path: m/44'/60'/0'/0/0 (Ethereum standart)
🗝️ Private Key: 0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890

Not: ECDSA imza algoritmasıdır, anahtar türetimi için BIP32 kullanılır.
```

### Adım 3: Rastgele Anahtarlar Üretimi

```
🎲 Generate DEK (32-byte): 0x9876543210fedcba9876543210fedcba9876543210fedcba9876543210fedcba
🧂 Generate Salt (32-byte): 0x1111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff
```

### Adım 4: KEK Türetimi (KDF)

```
🔧 Input: Password + Salt
⚙️ Algorithm: Argon2id
📊 Katmanlı Profiller:
   - Düşük: 64 MB (67,108,864 bytes) - Eski cihazlar
   - Orta: 128 MB (134,217,728 bytes) - Standart mobil
   - Yüksek: 256 MB (268,435,456 bytes) - Güçlü cihazlar
   - Iterations: 3
   - Parallelism: 1
   - Salt: 32-byte random

🔑 KEK = Argon2id(
    password="MySecurePassword123!",
    salt=0x1111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff,
    memory=134217728,  // 128 MB (standart profil)
    iterations=3,
    parallelism=1
) → 32-byte KEK
```

### Adım 5: DEK Şifreleme (Wrapped DEK)

```
🔐 Algorithm: AES-256-GCM
🎲 Generate Unique Nonce: generateUniqueNonce()
   - 8 bytes: Cryptographically secure random
   - 4 bytes: Monotonic counter
   - Uniqueness: Tracked in memory set
   - Result: hwg/5m43W8Q+c56y (Base64, 12-byte)
🔑 Key: KEK (32-byte)
📄 Plaintext: DEK (32-byte)
🏷️ AAD: user_id="113115482659428059027" (ek doğrulanan veri)

🔒 Wrapped DEK = AES-256-GCM-Encrypt(
    key=KEK,
    nonce="hwg/5m43W8Q+c56y" (guaranteed unique),
    plaintext=DEK,
    aad=user_id
)

📦 Result:
   - Ciphertext: VIsv3+mUV60Gs5uaI4ktmP2qACzt5B5LzDfimaDR1Lg= (Base64)
   - Nonce: hwg/5m43W8Q+c56y (Base64, 12-byte, unique)
   - MAC: 5bRYI+C806kxVjHri0neJg== (Base64, 16-byte)
   - Version: "1.0.0" (algorithm version)
```

### Adım 6: Private Key Şifreleme

```
🔐 Algorithm: AES-256-GCM
🎲 Generate Nonce (12-byte): 7TEamICV36RXvJya (Base64)
🔑 Key: DEK (32-byte)
📄 Plaintext: Private Key (32-byte)
🏷️ AAD: user_id="113115482659428059027" (ek doğrulanan veri)

🔒 Encrypted PrivKey = AES-256-GCM-Encrypt(
    key=DEK,
    nonce="7TEamICV36RXvJya" (12-byte),
    plaintext=PrivateKey,
    aad=user_id
)

📦 Result:
   - Ciphertext: gRWmDFYYi1ZQSqsJgxMP/EH9opm190qZchhKx8AWJWlq5n1YgjAeK4/orQQxH88KV4skACStAX067bPnHYpSLHg== (Base64)
   - Nonce: 7TEamICV36RXvJya (Base64, 12-byte)
   - MAC: YYPZV496KZVVc86guWNiVA== (Base64, 16-byte)
```

### Adım 7: Blob Oluşturma (Versiyonlu Format)

```json
{
  "version": 1,
  "created_at": "2025-08-17T20:58:23.4883406",
  "format_version": "1.0.0",
  "crypto_version": "1.0.0",
  "kdf": {
    "algorithm": "argon2id",
    "version": "1.3",
    "salt": "ERESIjMzRERVVWZmd3eIiZmQAKqqu7zN3e7v",
    "iterations": 3,
    "memory": 134217728,
    "parallelism": 1
  },
  "wrapped_dek": {
    "ct": "VIsv3+mUV60Gs5uaI4ktmP2qACzt5B5LzDfimaDR1Lg=",
    "nonce": "hwg/5m43W8Q+c56y",
    "mac": "5bRYI+C806kxVjHri0neJg==",
    "algorithm": "aes-256-gcm",
    "version": "1.0.0"
  },
  "encrypted_privkey": {
    "ct": "gRWmDFYYi1ZQSqsJgxMP/EH9opm190qZchhKx8AWJWlq5n1YgjAeK4/orQQxH88KV4skACStAX067bPnHYpSLHg==",
    "nonce": "7TEamICV36RXvJya",
    "mac": "YYPZV496KZVVc86guWNiVA==",
    "algorithm": "aes-256-gcm",
    "version": "1.0.0"
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

### Adım 8: Database'e Kayıt

```sql
INSERT INTO wallet_blobs (user_id, blob_json, created_at, updated_at)
VALUES (
  '113115482659428059027',
  '{"version":1,"kdf":{...},"wrapped_dek":{...},"encrypted_seed":{...}}',
  1755453503492,
  1755453503492
);
```

---

## 🔓 Çözme Akışı (Decryption Flow)

### Adım 1: Database'den Blob Okuma

```sql
SELECT blob_json FROM wallet_blobs WHERE user_id = '113115482659428059027';
```

### Adım 2: JSON Parse

```json
📄 Blob → JSON Parse → {
  "kdf": {...},
  "wrapped_dek": {...},
  "encrypted_seed": {...}
}
```

### Adım 3: Kullanıcı Password Girişi

```
📱 User Input: "MySecurePassword123!"
```

### Adım 4: KEK Yeniden Türetimi

```
🔧 Extract from blob:
   - Salt: "ERESIjMzRERVVWZmd3eIiZmQAKqqu7zN3e7v" (base64)
   - Algorithm: "argon2id"
   - Parameters: iterations=3, memory=134217728 (128 MB), parallelism=1

🔑 KEK = Argon2id(
    password="MySecurePassword123!",
    salt=decoded_salt,
    memory=134217728,  // 128 MB
    iterations=3,
    parallelism=1
) → Same 32-byte KEK
```

### Adım 5: DEK Çözme (Unwrap DEK)

```
🔓 Extract from wrapped_dek:
   - Ciphertext: "VIsv3+mUV60Gs5uaI4ktmP2qACzt5B5LzDfimaDR1Lg="
   - Nonce: "hwg/5m43W8Q+c56y" (12-byte Base64)
   - MAC: "5bRYI+C806kxVjHri0neJg=="
🏷️ AAD: user_id="113115482659428059027"

🔑 DEK = AES-256-GCM-Decrypt(
    key=KEK,
    nonce="hwg/5m43W8Q+c56y",
    ciphertext="VIsv3+mUV60Gs5uaI4ktmP2qACzt5B5LzDfimaDR1Lg=",
    mac="5bRYI+C806kxVjHri0neJg==",
    aad=user_id
)

✅ MAC Verification → Success
🔑 Result: Original DEK (32-byte)
```

### Adım 6: Private Key Çözme

```
🔓 Extract from encrypted_privkey:
   - Ciphertext: "gRWmDFYYi1ZQSqsJgxMP/EH9opm190qZchhKx8AWJWlq5n1YgjAeK4/orQQxH88KV4skACStAX067bPnHYpSLHg=="
   - Nonce: "7TEamICV36RXvJya" (12-byte Base64)
   - MAC: "YYPZV496KZVVc86guWNiVA=="
🏷️ AAD: user_id="113115482659428059027"

🔐 Private Key = AES-256-GCM-Decrypt(
    key=DEK,
    nonce="7TEamICV36RXvJya",
    ciphertext="gRWmDFYYi1ZQSqsJgxMP/EH9opm190qZchhKx8AWJWlq5n1YgjAeK4/orQQxH88KV4skACStAX067bPnHYpSLHg==",
    mac="YYPZV496KZVVc86guWNiVA==",
    aad=user_id
)

✅ MAC Verification → Success
🗝️ Result: Original Private Key (32-byte)
```

### Adım 7: Wallet Hazır

```
🎉 Private Key → Wallet Operations
💰 Address Generation
📝 Transaction Signing
🔍 Balance Queries
```

---

## ⚠️ Hata Durumları

### Yanlış Password

```
❌ Adım 5: DEK Çözme
🔴 MAC Verification Failed
💥 Exception: "Invalid password or corrupted data"
📱 UI: "Incorrect password, please try again"
```

### Corrupted Data

```
❌ Adım 2: JSON Parse Error
❌ Adım 5/6: MAC Verification Failed
🔴 Exception: "Data integrity check failed"
📱 UI: "Wallet data corrupted, please restore from mnemonic"
```

### Missing Fields

```
❌ Adım 2: Required fields missing
🔴 Exception: "Invalid blob format"
📱 UI: "Wallet format not supported"
```

---

## 🔒 Güvenlik Katmanları

### Katman 1: Password Protection

- ✅ Argon2id KDF (brute force koruması)
- ✅ 32-byte salt (rainbow table koruması)
- ✅ 128 MB memory (güçlü parametre)
- ✅ Mobil optimized parametreler

### Katman 2: Double Encryption

- ✅ KEK → DEK şifreleme (password layer)
- ✅ DEK → Seed şifreleme (data layer)
- ✅ Benzersiz nonce'lar (replay attack koruması)
- ✅ AAD binding (context security)

### Katman 3: Authentication

- ✅ AES-256-GCM MAC (integrity check)
- ✅ Tamper detection
- ✅ Authenticated encryption
- ✅ User ID binding (AAD)

### Katman 4: Storage Security

- ✅ Encrypted blob storage
- ✅ No plaintext keys in database
- ✅ User-specific encryption
- ✅ Versioned format

### Katman 5: Nonce Security

- ✅ Cryptographically secure random (8 bytes)
- ✅ Monotonic counter (4 bytes)
- ✅ Uniqueness tracking (memory set)
- ✅ Memory leak prevention (10K limit)

### Katman 6: Version Safety

- ✅ Format versioning (migration safety)
- ✅ Algorithm versioning (compatibility)
- ✅ Parameter versioning (future-proof)
- ✅ Backward compatibility checks

### Katman 7: Logging Security

- ✅ Sensitive data filtering
- ✅ Pattern-based redaction
- ✅ User ID hashing
- ✅ Crypto operation logging

---

## 📊 Performans Metrikleri

### Şifreleme Süresi (Profil Bazlı)

- 🔧 Argon2id KDF (64 MB): ~200-400ms
- 🔧 Argon2id KDF (128 MB): ~400-800ms
- 🔧 Argon2id KDF (256 MB): ~800-1600ms
- 🔐 AES-256-GCM (DEK): ~1-2ms
- 🔐 AES-256-GCM (PrivKey): ~1-2ms
- 📄 JSON Serialization: ~1ms
- **Toplam: ~403-1605ms (profil bazlı)**

### Çözme Süresi (Profil Bazlı)

- 📄 JSON Parse: ~1ms
- 🔧 Argon2id KDF (128 MB): ~400-800ms
- 🔓 AES-256-GCM (DEK): ~1-2ms
- 🔓 AES-256-GCM (PrivKey): ~1-2ms
- **Toplam: ~403-805ms**

### Memory Kullanımı (Profil Bazlı)

- 🧠 Argon2id (64 MB): ~64MB (geçici)
- 🧠 Argon2id (128 MB): ~128MB (geçici)
- 🧠 Argon2id (256 MB): ~256MB (geçici)
- 💾 Blob Storage: ~1-2KB
- 🔑 Key Storage: ~96 bytes (geçici)

---

## 🧪 Test ve Validation

### Canary Tests (Başlangıç Validation)

```dart
// Sistem başlangıcında otomatik çalışır
await CryptoService.initialize();

// Test edilen özellikler:
✅ Nonce uniqueness (2 farklı nonce)
✅ Basic encryption/decryption
✅ System integrity
```

### Comprehensive Test Suite

```dart
// Kapsamlı test suite
final result = await CryptoTestService.runFullValidation();

// Test edilen bileşenler:
✅ AES-GCM encryption/decryption
✅ Argon2id KDF deterministic
✅ Nonce uniqueness (1000 iteration)
✅ End-to-end wallet encryption
✅ Version compatibility
```

### Test Vectors

```dart
// Bilinen test vektörleri
{
  'aes_gcm_test': {
    'key': 'AAAA...', // 32 zero bytes
    'plaintext': 'SGVsbG8gV29ybGQ=', // "Hello World"
    'aad': 'dGVzdF9hYWQ=', // "test_aad"
  },
  'argon2id_test': {
    'password': 'test_password_123',
    'salt': 'AAAA...', // 32 zero bytes
  }
}
```

### Secure Logging Test

```dart
// Hassas veri filtreleme testi
SecureLogger.info('Processing password: mySecret123');
// Output: [INFO] Processing [REDACTED_PASSWORD]: [REDACTED]

SecureLogger.cryptoOperation('ENCRYPT', success: true);
// Output: [INFO] Crypto operation: ENCRYPT - SUCCESS
```

---

## 🔄 Biometric Bypass Akışı

### Normal Akış (Password)

```
Password → KEK → Unwrap DEK → Decrypt Seed
```

### Biometric Akış

```
Biometric → Device Key → Unwrap DEK → Decrypt Seed
```

**Not**: Biometric akışında Argon2id KDF bypass edilir, direkt device-specific key kullanılır.

---

# 📚 Kısaltmalar Sözlüğü

## Kriptografi Terimleri

| Kısaltma     | Açılımı                                       | Açıklama                                 |
| ------------ | --------------------------------------------- | ---------------------------------------- |
| **AES**      | Advanced Encryption Standard                  | Simetrik şifreleme algoritması (256-bit) |
| **GCM**      | Galois/Counter Mode                           | AES için authenticated encryption modu   |
| **AEAD**     | Authenticated Encryption with Associated Data | Şifreleme + doğrulama kombinasyonu       |
| **AAD**      | Additional Authenticated Data                 | Şifrelenmez ama doğrulanır ek veri       |
| **MAC**      | Message Authentication Code                   | Veri bütünlüğü doğrulama kodu            |
| **Nonce**    | Number Used Once                              | Bir kez kullanılan sayı (12-byte)        |
| **Counter**  | Monotonic Counter                             | Artan sayaç (nonce uniqueness için)      |
| **KDF**      | Key Derivation Function                       | Anahtar türetme fonksiyonu               |
| **KEK**      | Key Encryption Key                            | Anahtar şifreleme anahtarı               |
| **DEK**      | Data Encryption Key                           | Veri şifreleme anahtarı                  |
| **PBKDF2**   | Password-Based Key Derivation Function 2      | Password tabanlı anahtar türetme         |
| **Argon2id** | Argon2 Identity                               | Modern password hashing algoritması      |

## Blockchain Terimleri

| Kısaltma        | Açılımı                                    | Açıklama                                    |
| --------------- | ------------------------------------------ | ------------------------------------------- |
| **BIP39**       | Bitcoin Improvement Proposal 39            | Mnemonic kelime standardı                   |
| **HD**          | Hierarchical Deterministic                 | Hiyerarşik deterministik cüzdan             |
| **ECDSA**       | Elliptic Curve Digital Signature Algorithm | Eliptik eğri dijital imza                   |
| **secp256k1**   | -                                          | Bitcoin/Ethereum'da kullanılan eliptik eğri |
| **Private Key** | -                                          | Özel anahtar (32-byte)                      |
| **Public Key**  | -                                          | Açık anahtar (64-byte uncompressed)         |
| **Address**     | -                                          | Cüzdan adresi (20-byte hash)                |

## Sistem Terimleri

| Kısaltma   | Açılımı                       | Açıklama                              |
| ---------- | ----------------------------- | ------------------------------------- |
| **SQLite** | -                             | Gömülü SQL veritabanı                 |
| **JSON**   | JavaScript Object Notation    | Veri serileştirme formatı             |
| **Base64** | -                             | Binary veriyi text'e çevirme encoding |
| **UUID**   | Universally Unique Identifier | Benzersiz tanımlayıcı                 |
| **OAuth2** | Open Authorization 2.0        | Yetkilendirme protokolü               |
| **JWT**    | JSON Web Token                | Güvenli bilgi aktarım standardı       |

## Güvenlik Terimleri

| Kısaltma           | Açılımı                       | Açıklama                         |
| ------------------ | ----------------------------- | -------------------------------- |
| **2FA**            | Two-Factor Authentication     | İki faktörlü doğrulama           |
| **MFA**            | Multi-Factor Authentication   | Çok faktörlü doğrulama           |
| **HSM**            | Hardware Security Module      | Donanım güvenlik modülü          |
| **TEE**            | Trusted Execution Environment | Güvenilir çalıştırma ortamı      |
| **Keystore**       | -                             | Android anahtar depolama sistemi |
| **Secure Enclave** | -                             | iOS güvenli anahtar depolama     |
| **Canary Test**    | -                             | Hızlı sistem doğrulama testi     |
| **Test Vector**    | -                             | Bilinen giriş/çıkış test verisi  |
| **Redaction**      | -                             | Hassas veri maskeleme/gizleme    |
| **Versioning**     | -                             | Sürüm yönetimi ve uyumluluk      |

## Performans Terimleri

| Kısaltma | Açılımı                 | Açıklama                   |
| -------- | ----------------------- | -------------------------- |
| **RAM**  | Random Access Memory    | Rastgele erişim belleği    |
| **CPU**  | Central Processing Unit | Merkezi işlem birimi       |
| **I/O**  | Input/Output            | Giriş/Çıkış işlemleri      |
| **ms**   | millisecond             | Milisaniye (1/1000 saniye) |
| **KB**   | Kilobyte                | 1024 byte                  |
| **MB**   | Megabyte                | 1024 KB                    |

## Hata Kodları

| Kod                         | Açıklama                          |
| --------------------------- | --------------------------------- |
| **MAC_VERIFICATION_FAILED** | Veri bütünlüğü kontrolü başarısız |
| **INVALID_PASSWORD**        | Geçersiz parola                   |
| **CORRUPTED_DATA**          | Bozuk veri                        |
| **MISSING_FIELD**           | Eksik alan                        |
| **UNSUPPORTED_VERSION**     | Desteklenmeyen versiyon           |
| **BIOMETRIC_UNAVAILABLE**   | Biyometrik donanım mevcut değil   |
| **DEVICE_KEY_CORRUPTED**    | Cihaz anahtarı bozuk              |

---

Bu doküman, Keiko Wallet'ın private key şifreleme ve çözme sürecinin teknik detaylarını kapsamlı olarak açıklar.
