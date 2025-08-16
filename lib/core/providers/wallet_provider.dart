import 'package:flutter/foundation.dart';
import 'package:web3dart/web3dart.dart';
import '../models/wallet.dart' as app_wallet;
import '../models/transaction.dart' as app_transaction;
import '../services/wallet_service.dart';
import '../services/security_service.dart';
import '../services/blockchain_service.dart';
import '../services/moralis_service.dart';
import '../constants/app_constants.dart';

class WalletProvider extends ChangeNotifier {
  app_wallet.Wallet? _currentWallet;
  List<app_wallet.TokenBalance> _tokenBalances = [];
  List<app_transaction.Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;
  late BlockchainService _blockchainService;

  // Getters
  app_wallet.Wallet? get currentWallet => _currentWallet;
  List<app_wallet.TokenBalance> get tokenBalances => _tokenBalances;
  List<app_transaction.Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasWallet => _currentWallet != null;

  WalletProvider() {
    _blockchainService = BlockchainService();
    _initializeWallet();
  }

  /// Initialize wallet from stored data
  Future<void> _initializeWallet() async {
    try {
      _setLoading(true);

      final isWalletCreated = await SecurityService.isWalletCreated();
      if (isWalletCreated) {
        await _loadWalletFromStorage();
      }
    } catch (e) {
      _setError('Failed to initialize wallet: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load wallet from secure storage
  Future<void> _loadWalletFromStorage() async {
    final seedPhrase = await SecurityService.getSeedPhrase();
    if (seedPhrase != null) {
      _currentWallet = await WalletService.createWalletFromMnemonic(seedPhrase);
      await refreshBalances();
      notifyListeners();
    }
  }

  /// Create new wallet
  Future<String> createNewWallet() async {
    try {
      _setLoading(true);
      _clearError();

      // Generate mnemonic
      final mnemonic = WalletService.generateMnemonic();

      // Create wallet from mnemonic
      _currentWallet = await WalletService.createWalletFromMnemonic(mnemonic);

      // Store encrypted seed phrase
      await SecurityService.storeSeedPhrase(mnemonic);

      // Load initial balances
      await refreshBalances();

      notifyListeners();
      return mnemonic;
    } catch (e) {
      _setError('Failed to create wallet: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Import wallet from mnemonic
  Future<void> importWalletFromMnemonic(String mnemonic) async {
    try {
      _setLoading(true);
      _clearError();

      if (!WalletService.validateMnemonic(mnemonic)) {
        throw ArgumentError('Invalid mnemonic phrase');
      }

      // Create wallet from mnemonic
      _currentWallet = await WalletService.createWalletFromMnemonic(mnemonic);

      // Store encrypted seed phrase
      await SecurityService.storeSeedPhrase(mnemonic);

      // Load initial balances
      await refreshBalances();

      notifyListeners();
    } catch (e) {
      _setError('Failed to import wallet: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Import wallet from private key
  Future<void> importWalletFromPrivateKey(String privateKey) async {
    try {
      _setLoading(true);
      _clearError();

      _currentWallet = await WalletService.importWalletFromPrivateKey(
        privateKey,
      );

      // Note: For imported private keys, we don't store the seed phrase
      // as we don't have the mnemonic. This is a security consideration.

      await refreshBalances();
      notifyListeners();
    } catch (e) {
      _setError('Failed to import wallet from private key: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh token balances
  Future<void> refreshBalances() async {
    if (_currentWallet == null) return;

    try {
      _setLoading(true);
      _clearError();

      final balances = <app_wallet.TokenBalance>[];

      // Get ETH balance using Moralis API
      final ethBalanceWei = await MoralisService.getNativeBalance(
        _currentWallet!.address,
        chain: 'sepolia',
      );

      final ethToken = app_wallet.Token(
        symbol: 'ETH',
        name: 'Ethereum',
        decimals: 18,
        isNative: true,
        chainId: AppConstants.ethereumSepoliaChainId,
      );

      balances.add(
        app_wallet.TokenBalance(
          token: ethToken,
          balance: BigInt.parse(ethBalanceWei),
        ),
      );

      // Get ERC20 token balances using Moralis API (temporarily disabled)
      try {
        // Temporarily disable token balance fetching until API format is fixed
        debugPrint('Token balance fetching temporarily disabled');
        /*
        final tokenBalances = await MoralisService.getTokenBalances(
          _currentWallet!.address,
          chain: 'sepolia',
        );

        for (final tokenData in tokenBalances) {
          final token = app_wallet.Token(
            symbol: tokenData['symbol'] ?? 'UNKNOWN',
            name: tokenData['name'] ?? 'Unknown Token',
            contractAddress: tokenData['token_address'],
            decimals:
                int.tryParse(tokenData['decimals']?.toString() ?? '18') ?? 18,
            chainId: AppConstants.ethereumSepoliaChainId,
          );

          balances.add(
            app_wallet.TokenBalance(
              token: token,
              balance: BigInt.parse(tokenData['balance'] ?? '0'),
            ),
          );
        }
        */
      } catch (tokenError) {
        debugPrint('Error fetching token balances: $tokenError');
        // Continue with just ETH balance if token fetch fails
      }

      _tokenBalances = balances;
      notifyListeners();
    } catch (e) {
      _setError('Failed to refresh balances: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Send ETH transaction
  Future<String> sendEthTransaction({
    required String toAddress,
    required String amount,
  }) async {
    if (_currentWallet == null) {
      throw StateError('No wallet available');
    }

    try {
      _setLoading(true);
      _clearError();

      // Authenticate user
      final isAuthenticated =
          await SecurityService.authenticateForSensitiveOperation(
            reason: 'Authenticate to send transaction',
          );

      if (!isAuthenticated) {
        throw Exception('Authentication failed');
      }

      // Get credentials
      final seedPhrase = await SecurityService.getSeedPhrase();
      if (seedPhrase == null) {
        throw StateError('Seed phrase not found');
      }

      final credentials = WalletService.getCredentialsFromMnemonic(seedPhrase);
      final etherAmount = EtherAmount.fromBase10String(EtherUnit.ether, amount);

      // Send transaction
      final txHash = await _blockchainService.sendEthTransaction(
        credentials: credentials,
        toAddress: toAddress,
        amount: etherAmount,
      );

      // Refresh balances after transaction
      await refreshBalances();

      return txHash;
    } catch (e) {
      _setError('Failed to send transaction: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete wallet and all associated data
  Future<void> deleteWallet() async {
    try {
      _setLoading(true);

      await SecurityService.deleteWalletData();

      _currentWallet = null;
      _tokenBalances = [];
      _transactions = [];

      notifyListeners();
    } catch (e) {
      _setError('Failed to delete wallet: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Switch network
  void switchNetwork(String rpcUrl, int chainId) {
    _blockchainService.switchNetwork(rpcUrl, chainId);
    // Refresh balances for new network
    refreshBalances();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _blockchainService.dispose();
    super.dispose();
  }
}
