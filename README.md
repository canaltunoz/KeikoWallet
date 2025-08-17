# Keiko Wallet 🚀

A modern, secure, and user-friendly cryptocurrency wallet built with Flutter with enterprise-grade security.

## ✨ Features

### 🔐 Advanced Security

- **Military-Grade Encryption** - AES-256-GCM with unique nonce generation
- **Argon2id KDF** - 16MB memory, optimized for mobile security
- **Secure Mnemonic Generation** - 12-word seed phrase with BIP39 standard
- **Advanced Verification System** - Multi-step mnemonic verification with randomized questions
- **Biometric Authentication** - Fingerprint and face unlock support
- **Versioned Security** - Future-proof cryptographic parameter versioning
- **Secure Logging** - Production-safe logging with sensitive data filtering
- **Environment Variables** - Secure API key management
- **Local Storage Encryption** - Multi-layered encrypted wallet data storage

### 🌐 Blockchain Support

- **Ethereum Mainnet & Sepolia Testnet**
- **Polygon Network**
- **Binance Smart Chain (BSC)**
- **Moralis API Integration** - Real-time balance and transaction data

### 📱 User Experience

- **Google Sign-In Integration** - Seamless authentication
- **Settings Management** - Comprehensive user settings and account management
- **Responsive Design** - Optimized for all screen sizes
- **Material Design 3** - Modern and intuitive interface
- **Smooth Animations** - Polished user interactions
- **Privacy Controls** - "Forget Me" functionality for complete data removal
- **Biometric Setup** - Easy fingerprint and face unlock configuration

### 💰 Wallet Features

- **Create New Wallet** - Generate secure wallets
- **Import Existing Wallet** - Restore from mnemonic phrase
- **Balance Display** - Real-time ETH and token balances
- **Multi-Network Support** - Switch between different blockchains

## 🛠️ Technical Stack

### 📱 Frontend (Current)

- **Framework**: Flutter 3.x
- **State Management**: Provider
- **Blockchain**: Web3Dart, Moralis API
- **Security**: AES-256-GCM, Argon2id, Flutter Secure Storage
- **Database**: SQLite with encrypted storage
- **Authentication**: Google Sign-In, Local Biometrics
- **Cryptography**: pointycastle, crypto
- **Environment**: flutter_dotenv
- **UI**: Material Design 3

### 🔧 Backend (Planned)

- **API Framework**: Node.js/Express or Go/Gin
- **Authentication**: Google OAuth 2.0 + JWT
- **Database**: PostgreSQL with encryption at rest
- **Storage**: AWS S3 or Google Cloud Storage
- **Security**: Rate limiting, audit logging, token validation
- **Infrastructure**: Docker containers, cloud deployment
- **Monitoring**: Structured logging, metrics, alerting

## � Security Architecture

### Encryption Layers

- **AES-256-GCM**: Authenticated encryption for wallet data
- **Argon2id KDF**: 16MB memory, 3 iterations for password derivation
- **Unique Nonces**: 8-byte random + 4-byte counter for replay protection
- **AAD Binding**: Additional authenticated data for user context

### Key Management

- **DEK (Data Encryption Key)**: Encrypts wallet private keys
- **KEK (Key Encryption Key)**: Derived from user password via Argon2id
- **Wrapped DEK**: KEK-encrypted DEK stored securely
- **Biometric Integration**: Hardware-backed secure key storage

### Security Features

- **Version Safety**: Cryptographic parameter versioning
- **Test Vectors**: Comprehensive validation with known test cases
- **Canary Tests**: Runtime security validation
- **Secure Logging**: Production-safe logging with data filtering
- **Memory Protection**: Secure memory handling for sensitive data

### Backend Security (Planned)

- **Token Validation**: Google ID token signature and audience verification
- **Access Control**: User-scoped blob access via Google sub ID
- **Rate Limiting**: Protection against online attacks and abuse
- **Audit Trail**: Comprehensive logging of all blob operations
- **Session Management**: Secure JWT handling with refresh tokens
- **Data Isolation**: User data segregation and privacy protection

## 🧪 Testing & Validation

- **Crypto Test Suite**: 1000+ test iterations for nonce uniqueness
- **End-to-End Tests**: Complete wallet creation/unlock validation
- **Security Canaries**: Runtime cryptographic health checks
- **Test Vectors**: AES-GCM and Argon2id reference implementations

## �🚀 Getting Started

### Prerequisites

- Flutter SDK (3.0+)
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/canaltunoz/KeikoWallet.git
   cd KeikoWallet
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Environment Setup**

   - Copy `.env.example` to `.env`
   - Add your Moralis API key:

   ```env
   MORALIS_API_KEY=your_moralis_api_key_here
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 🔧 Configuration

### Environment Variables

Create a `.env` file in the root directory:

```env
# Moralis Configuration
MORALIS_API_KEY=your_moralis_api_key

# Network Configuration
DEFAULT_NETWORK=sepolia
ETHEREUM_MAINNET_RPC=https://eth.llamarpc.com
ETHEREUM_SEPOLIA_RPC=https://rpc.sepolia.org

# App Configuration
APP_NAME=Keiko Wallet
APP_VERSION=1.0.0
DEBUG_MODE=true
```

## 🔒 Security Features

### Mnemonic Verification

- **3 Random Word Verification** - Users must verify 3 randomly selected words
- **Dynamic Question Generation** - New questions on each failed attempt
- **Secure Option Shuffling** - Prevents pattern memorization

### API Security

- **Environment Variables** - No hardcoded API keys
- **Secure HTTP Client** - Custom authentication headers
- **Error Handling** - Graceful failure management

## 🌟 Upcoming Features

### 🔗 Blockchain Features

- [ ] **Send/Receive Transactions** - Complete transaction functionality
- [ ] **Transaction History** - Detailed transaction tracking
- [ ] **QR Code Support** - Easy address sharing and scanning
- [ ] **Token Swap Integration** - DEX integration for token swaps
- [ ] **Portfolio Tracking** - Advanced portfolio analytics
- [ ] **DeFi Integration** - Staking and yield farming
- [ ] **Multi-Signature Support** - Enhanced security for teams
- [ ] **Hardware Wallet Integration** - Ledger and Trezor support
- [ ] **Cross-Chain Bridges** - Seamless asset transfers
- [ ] **NFT Gallery** - View and manage NFT collections

### 🛡️ Backend Security & Infrastructure

- [ ] **Google ID Token Validation** - Server-side token signature and audience verification
- [ ] **Centralized Blob Storage** - Secure encrypted wallet storage via API (S3/Database)
- [ ] **User Authorization** - Google sub-based access control for wallet blobs
- [ ] **Rate Limiting** - Protection against online brute-force attacks
- [ ] **Audit Logging** - Comprehensive access logs (who, when, which blob accessed)
- [ ] **JWT Session Management** - Secure session handling with token refresh
- [ ] **API Gateway** - Centralized authentication and request routing
- [ ] **Backup & Recovery** - Encrypted cloud backup with user consent
- [ ] **Multi-Device Sync** - Secure wallet synchronization across devices

## ✅ Recently Completed

- [x] **Biometric Authentication** - Fingerprint and face unlock
- [x] **Settings Management** - Comprehensive user settings
- [x] **Advanced Security** - Military-grade encryption implementation
- [x] **Google Sign-In** - Seamless authentication integration
- [x] **Database Encryption** - Multi-layered secure storage
- [x] **Privacy Controls** - Complete data removal functionality

## 👨‍💻 Author

**Can Altunöz**

- Email: m.canaltunoz@gmail.com
- GitHub: [@canaltunoz](https://github.com/canaltunoz)

---

## 📄 Documentation

- **[Security Architecture](./Wallet_Saklama_v2_Security.md)** - Comprehensive security specifications
- **[Encryption Flow](./Private_Key_Encryption_Flow.md)** - Detailed encryption implementation
- **[Wallet Storage](./Wallet_Saklama.md)** - Storage and key management details

---

**⚠️ Disclaimer**: This wallet implements enterprise-grade security but is still in development. Comprehensive security audits are recommended before mainnet deployment with significant funds.
