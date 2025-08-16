# Keiko Wallet 🚀

A modern, secure, and user-friendly cryptocurrency wallet built with Flutter.

## ✨ Features

### 🔐 Security

- **Secure Mnemonic Generation** - 12-word seed phrase with BIP39 standard
- **Advanced Verification System** - Multi-step mnemonic verification with randomized questions
- **Environment Variables** - Secure API key management
- **Local Storage Encryption** - Encrypted wallet data storage

### 🌐 Blockchain Support

- **Ethereum Mainnet & Sepolia Testnet**
- **Polygon Network**
- **Binance Smart Chain (BSC)**
- **Moralis API Integration** - Real-time balance and transaction data

### 📱 User Experience

- **Responsive Design** - Optimized for all screen sizes
- **Material Design 3** - Modern and intuitive interface
- **Smooth Animations** - Polished user interactions

### 💰 Wallet Features

- **Create New Wallet** - Generate secure wallets
- **Import Existing Wallet** - Restore from mnemonic phrase
- **Balance Display** - Real-time ETH and token balances
- **Multi-Network Support** - Switch between different blockchains

## 🛠️ Technical Stack

- **Framework**: Flutter 3.x
- **State Management**: Provider
- **Blockchain**: Web3Dart, Moralis API
- **Security**: Flutter Secure Storage
- **Environment**: flutter_dotenv
- **UI**: Material Design 3

## 🚀 Getting Started

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

- [ ] **Send/Receive Transactions**
- [ ] **Transaction History**
- [ ] **QR Code Support**
- [ ] **Token Swap Integration**
- [ ] **Biometric Authentication**
- [ ] **Portfolio Tracking**
- [ ] **DeFi Integration**

## 👨‍💻 Author

**Can Altunöz**

- Email: m.canaltunoz@gmail.com
- GitHub: [@canaltunoz](https://github.com/canaltunoz)

---

**⚠️ Disclaimer**: This is a development wallet. Do not use with real funds on mainnet without proper security audits.
