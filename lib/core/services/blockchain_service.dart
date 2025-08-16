import 'dart:typed_data';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import '../models/wallet.dart' as app_wallet;

import '../constants/app_constants.dart';

/// Custom HTTP client for Web3 RPC calls
class Web3HttpClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    // Standard headers for RPC calls
    request.headers['Content-Type'] = 'application/json';
    request.headers['Accept'] = 'application/json';
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
  }
}

class BlockchainService {
  late Web3Client _web3Client;
  late String _rpcUrl;
  late int _chainId;

  BlockchainService({String? rpcUrl, int? chainId}) {
    _rpcUrl = rpcUrl ?? AppConstants.ethereumSepoliaRpc;
    _chainId = chainId ?? AppConstants.ethereumSepoliaChainId;
    _web3Client = Web3Client(_rpcUrl, _createAuthenticatedClient());
  }

  /// Create HTTP client for Web3 RPC calls
  http.Client _createAuthenticatedClient() {
    return Web3HttpClient();
  }

  /// Switch to different network
  void switchNetwork(String rpcUrl, int chainId) {
    _rpcUrl = rpcUrl;
    _chainId = chainId;
    _web3Client = Web3Client(_rpcUrl, _createAuthenticatedClient());
  }

  /// Get ETH balance for an address
  Future<EtherAmount> getEthBalance(String address) async {
    try {
      final ethAddress = EthereumAddress.fromHex(address);
      return await _web3Client.getBalance(ethAddress);
    } catch (e) {
      throw Exception('Failed to get ETH balance: $e');
    }
  }

  /// Get ERC20 token balance
  Future<BigInt> getTokenBalance(
    String walletAddress,
    String tokenAddress,
  ) async {
    try {
      final contract = DeployedContract(
        ContractAbi.fromJson(_erc20Abi, 'ERC20'),
        EthereumAddress.fromHex(tokenAddress),
      );

      final balanceFunction = contract.function('balanceOf');
      final result = await _web3Client.call(
        contract: contract,
        function: balanceFunction,
        params: [EthereumAddress.fromHex(walletAddress)],
      );

      return result.first as BigInt;
    } catch (e) {
      throw Exception('Failed to get token balance: $e');
    }
  }

  /// Get token information (name, symbol, decimals)
  Future<app_wallet.Token> getTokenInfo(
    String tokenAddress,
    int chainId,
  ) async {
    try {
      final contract = DeployedContract(
        ContractAbi.fromJson(_erc20Abi, 'ERC20'),
        EthereumAddress.fromHex(tokenAddress),
      );

      // Get token name
      final nameFunction = contract.function('name');
      final nameResult = await _web3Client.call(
        contract: contract,
        function: nameFunction,
        params: [],
      );
      final name = nameResult.first as String;

      // Get token symbol
      final symbolFunction = contract.function('symbol');
      final symbolResult = await _web3Client.call(
        contract: contract,
        function: symbolFunction,
        params: [],
      );
      final symbol = symbolResult.first as String;

      // Get token decimals
      final decimalsFunction = contract.function('decimals');
      final decimalsResult = await _web3Client.call(
        contract: contract,
        function: decimalsFunction,
        params: [],
      );
      final decimals = (decimalsResult.first as BigInt).toInt();

      return app_wallet.Token(
        symbol: symbol,
        name: name,
        contractAddress: tokenAddress,
        decimals: decimals,
        chainId: chainId,
      );
    } catch (e) {
      throw Exception('Failed to get token info: $e');
    }
  }

  /// Send ETH transaction
  Future<String> sendEthTransaction({
    required EthPrivateKey credentials,
    required String toAddress,
    required EtherAmount amount,
    EtherAmount? gasPrice,
    int? gasLimit,
  }) async {
    try {
      final to = EthereumAddress.fromHex(toAddress);

      // Get current gas price if not provided
      gasPrice ??= await _web3Client.getGasPrice();

      // Estimate gas if not provided
      gasLimit ??= await _estimateGas(
        from: credentials.address,
        to: to,
        value: amount,
      );

      final transaction = Transaction(
        to: to,
        gasPrice: gasPrice,
        maxGas: gasLimit,
        value: amount,
      );

      return await _web3Client.sendTransaction(
        credentials,
        transaction,
        chainId: _chainId,
      );
    } catch (e) {
      throw Exception('Failed to send ETH transaction: $e');
    }
  }

  /// Send ERC20 token transaction
  Future<String> sendTokenTransaction({
    required EthPrivateKey credentials,
    required String tokenAddress,
    required String toAddress,
    required BigInt amount,
    EtherAmount? gasPrice,
    int? gasLimit,
  }) async {
    try {
      final contract = DeployedContract(
        ContractAbi.fromJson(_erc20Abi, 'ERC20'),
        EthereumAddress.fromHex(tokenAddress),
      );

      final transferFunction = contract.function('transfer');

      gasPrice ??= await _web3Client.getGasPrice();
      gasLimit ??= 100000; // Default gas limit for ERC20 transfers

      final transaction = Transaction.callContract(
        contract: contract,
        function: transferFunction,
        parameters: [EthereumAddress.fromHex(toAddress), amount],
        gasPrice: gasPrice,
        maxGas: gasLimit,
      );

      return await _web3Client.sendTransaction(
        credentials,
        transaction,
        chainId: _chainId,
      );
    } catch (e) {
      throw Exception('Failed to send token transaction: $e');
    }
  }

  /// Estimate gas for a transaction
  Future<int> _estimateGas({
    required EthereumAddress from,
    required EthereumAddress to,
    EtherAmount? value,
    Uint8List? data,
  }) async {
    try {
      final gasEstimate = await _web3Client.estimateGas(
        sender: from,
        to: to,
        value: value,
        data: data,
      );

      // Add 20% buffer to gas estimate
      return (gasEstimate.toDouble() * 1.2).round();
    } catch (e) {
      // Return default gas limit if estimation fails
      return 21000;
    }
  }

  /// Get transaction receipt
  Future<TransactionReceipt?> getTransactionReceipt(String txHash) async {
    try {
      return await _web3Client.getTransactionReceipt(txHash);
    } catch (e) {
      return null;
    }
  }

  /// Get transaction by hash
  Future<TransactionInformation?> getTransaction(String txHash) async {
    try {
      return await _web3Client.getTransactionByHash(txHash);
    } catch (e) {
      return null;
    }
  }

  /// Get current gas price
  Future<EtherAmount> getGasPrice() async {
    return await _web3Client.getGasPrice();
  }

  /// Get current block number
  Future<int> getBlockNumber() async {
    return await _web3Client.getBlockNumber();
  }

  /// Get nonce for address
  Future<int> getNonce(String address) async {
    final ethAddress = EthereumAddress.fromHex(address);
    return await _web3Client.getTransactionCount(ethAddress);
  }

  void dispose() {
    _web3Client.dispose();
  }

  // ERC20 ABI for basic token operations
  static const String _erc20Abi = '''[
    {
      "constant": true,
      "inputs": [],
      "name": "name",
      "outputs": [{"name": "", "type": "string"}],
      "type": "function"
    },
    {
      "constant": true,
      "inputs": [],
      "name": "symbol",
      "outputs": [{"name": "", "type": "string"}],
      "type": "function"
    },
    {
      "constant": true,
      "inputs": [],
      "name": "decimals",
      "outputs": [{"name": "", "type": "uint8"}],
      "type": "function"
    },
    {
      "constant": true,
      "inputs": [{"name": "_owner", "type": "address"}],
      "name": "balanceOf",
      "outputs": [{"name": "balance", "type": "uint256"}],
      "type": "function"
    },
    {
      "constant": false,
      "inputs": [
        {"name": "_to", "type": "address"},
        {"name": "_value", "type": "uint256"}
      ],
      "name": "transfer",
      "outputs": [{"name": "", "type": "bool"}],
      "type": "function"
    }
  ]''';
}
