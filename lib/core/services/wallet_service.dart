import 'dart:typed_data';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;
import 'package:web3dart/web3dart.dart';
import 'package:convert/convert.dart';
import '../models/wallet.dart' as app_wallet;

class WalletService {
  static const int _mnemonicStrength = 128; // 12 words
  static const int _mnemonicStrengthLong = 256; // 24 words

  /// Generate a new BIP39 mnemonic phrase
  /// [wordCount] can be 12 or 24 words
  static String generateMnemonic({int wordCount = 12}) {
    final strength = wordCount == 24
        ? _mnemonicStrengthLong
        : _mnemonicStrength;
    return bip39.generateMnemonic(strength: strength);
  }

  /// Validate a BIP39 mnemonic phrase
  static bool validateMnemonic(String mnemonic) {
    return bip39.validateMnemonic(mnemonic);
  }

  /// Generate seed from mnemonic with optional passphrase
  static Uint8List mnemonicToSeed(String mnemonic, {String passphrase = ''}) {
    if (!validateMnemonic(mnemonic)) {
      throw ArgumentError('Invalid mnemonic phrase');
    }
    return bip39.mnemonicToSeed(mnemonic, passphrase: passphrase);
  }

  /// Create wallet from mnemonic for Ethereum/EVM chains
  static Future<app_wallet.Wallet> createWalletFromMnemonic(
    String mnemonic, {
    String passphrase = '',
    int accountIndex = 0,
  }) async {
    if (!validateMnemonic(mnemonic)) {
      throw ArgumentError('Invalid mnemonic phrase');
    }

    // Generate seed from mnemonic
    final seed = mnemonicToSeed(mnemonic, passphrase: passphrase);

    // Create HD wallet from seed
    final hdWallet = bip32.BIP32.fromSeed(seed);

    // Derive Ethereum account using BIP44 path: m/44'/60'/0'/0/accountIndex
    final derivationPath = "m/44'/60'/0'/0/$accountIndex";
    final derivedNode = hdWallet.derivePath(derivationPath);

    if (derivedNode.privateKey == null) {
      throw StateError('Failed to derive private key');
    }

    // Create Ethereum credentials from private key
    final credentials = EthPrivateKey(derivedNode.privateKey!);
    final address = credentials.address.hex;
    final publicKey = hex.encode(derivedNode.publicKey);

    return app_wallet.Wallet(
      address: address,
      publicKey: publicKey,
      createdAt: DateTime.now(),
      isImported: false,
    );
  }

  /// Import wallet from private key
  static Future<app_wallet.Wallet> importWalletFromPrivateKey(
    String privateKeyHex,
  ) async {
    try {
      // Remove '0x' prefix if present
      final cleanPrivateKey = privateKeyHex.startsWith('0x')
          ? privateKeyHex.substring(2)
          : privateKeyHex;

      // Validate private key length (64 hex characters = 32 bytes)
      if (cleanPrivateKey.length != 64) {
        throw ArgumentError('Invalid private key length');
      }

      final privateKeyBytes = Uint8List.fromList(hex.decode(cleanPrivateKey));
      final credentials = EthPrivateKey(privateKeyBytes);
      final address = credentials.address.hex;

      // For imported wallets, we don't have the full public key from BIP32
      // We can derive it from the private key if needed
      final publicKey = ''; // TODO: Derive public key if needed

      return app_wallet.Wallet(
        address: address,
        publicKey: publicKey,
        createdAt: DateTime.now(),
        isImported: true,
      );
    } catch (e) {
      throw ArgumentError('Invalid private key: $e');
    }
  }

  /// Get private key from mnemonic for specific account
  static Uint8List getPrivateKeyFromMnemonic(
    String mnemonic, {
    String passphrase = '',
    int accountIndex = 0,
  }) {
    if (!validateMnemonic(mnemonic)) {
      throw ArgumentError('Invalid mnemonic phrase');
    }

    final seed = mnemonicToSeed(mnemonic, passphrase: passphrase);
    final hdWallet = bip32.BIP32.fromSeed(seed);
    final derivationPath = "m/44'/60'/0'/0/$accountIndex";
    final derivedNode = hdWallet.derivePath(derivationPath);

    if (derivedNode.privateKey == null) {
      throw StateError('Failed to derive private key');
    }

    return derivedNode.privateKey!;
  }

  /// Create EthPrivateKey credentials from mnemonic
  static EthPrivateKey getCredentialsFromMnemonic(
    String mnemonic, {
    String passphrase = '',
    int accountIndex = 0,
  }) {
    final privateKey = getPrivateKeyFromMnemonic(
      mnemonic,
      passphrase: passphrase,
      accountIndex: accountIndex,
    );
    return EthPrivateKey(privateKey);
  }

  /// Generate multiple accounts from the same mnemonic
  static Future<List<app_wallet.Wallet>> generateMultipleAccounts(
    String mnemonic, {
    String passphrase = '',
    int count = 5,
  }) async {
    final wallets = <app_wallet.Wallet>[];

    for (int i = 0; i < count; i++) {
      final wallet = await createWalletFromMnemonic(
        mnemonic,
        passphrase: passphrase,
        accountIndex: i,
      );
      wallets.add(wallet.copyWith(name: 'Account ${i + 1}'));
    }

    return wallets;
  }

  /// Validate Ethereum address format
  static bool isValidEthereumAddress(String address) {
    try {
      EthereumAddress.fromHex(address);
      return true;
    } catch (e) {
      return false;
    }
  }
}
