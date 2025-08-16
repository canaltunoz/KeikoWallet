import '../services/env_service.dart';

class AppConstants {
  // App Info
  static String get appName => EnvService.appName;
  static String get appVersion => EnvService.appVersion;

  // Moralis Configuration
  static String get moralisApiKey => EnvService.moralisApiKey;

  // Network Constants
  static String get ethereumMainnetRpc => EnvService.ethereumMainnetRpc;
  static String get ethereumSepoliaRpc => EnvService.ethereumSepoliaRpc;
  static String get polygonMainnetRpc => EnvService.polygonMainnetRpc;
  static String get bscMainnetRpc => EnvService.bscMainnetRpc;

  // Chain IDs
  static const int ethereumMainnetChainId = 1;
  static const int ethereumSepoliaChainId = 11155111;
  static const int polygonMainnetChainId = 137;
  static const int bscMainnetChainId = 56;

  // HD Wallet Derivation Paths
  static const String ethereumDerivationPath = "m/44'/60'/0'/0/0";
  static const String bitcoinDerivationPath = "m/44'/0'/0'/0/0";

  // Security
  static const String seedStorageKey = 'encrypted_seed';
  static const String walletCreatedKey = 'wallet_created';
  static const String biometricEnabledKey = 'biometric_enabled';

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;

  // Token Addresses (Ethereum Mainnet)
  static const String usdtTokenAddress =
      '0xdAC17F958D2ee523a2206206994597C13D831ec7';
  static const String usdcTokenAddress =
      '0xA0b86a33E6441b8C4505B8C4505B8C4505B8C4505';
  static const String daiTokenAddress =
      '0x6B175474E89094C44Da98b954EedeAC495271d0F';
}
