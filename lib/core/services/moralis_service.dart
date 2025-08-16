import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class MoralisService {
  static const String _baseUrl = 'https://deep-index.moralis.io/api/v2.2';
  static final http.Client _client = http.Client();

  /// Get native balance for an address
  static Future<String> getNativeBalance(
    String address, {
    String chain = 'sepolia',
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/$address/balance');
      final response = await _client.get(
        url.replace(queryParameters: {'chain': chain}),
        headers: {
          'X-API-Key': AppConstants.moralisApiKey,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['balance'] ?? '0';
      } else {
        throw Exception(
          'Failed to get balance: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error getting native balance: $e');
    }
  }

  /// Get ERC20 token balances for an address
  static Future<List<Map<String, dynamic>>> getTokenBalances(
    String address, {
    String chain = 'sepolia',
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/$address/erc20');
      final response = await _client.get(
        url.replace(queryParameters: {'chain': chain}),
        headers: {
          'X-API-Key': AppConstants.moralisApiKey,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Handle both array and object responses
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data.containsKey('result')) {
          final result = data['result'];
          if (result is List) {
            return List<Map<String, dynamic>>.from(result);
          }
        }
        return [];
      } else {
        throw Exception(
          'Failed to get token balances: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error getting token balances: $e');
    }
  }

  /// Get transaction history for an address
  static Future<List<Map<String, dynamic>>> getTransactionHistory(
    String address, {
    String chain = 'sepolia',
    int limit = 10,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/$address');
      final response = await _client.get(
        url.replace(
          queryParameters: {'chain': chain, 'limit': limit.toString()},
        ),
        headers: {
          'X-API-Key': AppConstants.moralisApiKey,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['result'] ?? []);
      } else {
        throw Exception(
          'Failed to get transaction history: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error getting transaction history: $e');
    }
  }

  /// Get token metadata
  static Future<Map<String, dynamic>?> getTokenMetadata(
    String tokenAddress, {
    String chain = 'sepolia',
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/erc20/metadata');
      final response = await _client.get(
        url.replace(
          queryParameters: {'chain': chain, 'addresses': tokenAddress},
        ),
        headers: {
          'X-API-Key': AppConstants.moralisApiKey,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['result'] as List?;
        return results?.isNotEmpty == true ? results!.first : null;
      } else {
        throw Exception(
          'Failed to get token metadata: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error getting token metadata: $e');
    }
  }

  /// Get current gas price
  static Future<String> getGasPrice({String chain = 'sepolia'}) async {
    try {
      // Moralis doesn't have a direct gas price endpoint, so we'll use a fallback
      // You can implement this using Web3 RPC call or use a different service
      return '20000000000'; // 20 Gwei as fallback
    } catch (e) {
      throw Exception('Error getting gas price: $e');
    }
  }

  /// Validate if API key is working
  static Future<bool> validateApiKey() async {
    try {
      // Test with a simple call to check if API key works
      final url = Uri.parse(
        '$_baseUrl/0x0000000000000000000000000000000000000000/balance',
      );
      final response = await _client.get(
        url.replace(queryParameters: {'chain': 'sepolia'}),
        headers: {
          'X-API-Key': AppConstants.moralisApiKey,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      // Even if the address is invalid, a 200 response means API key is valid
      return response.statusCode == 200 || response.statusCode == 400;
    } catch (e) {
      return false;
    }
  }

  /// Get supported chains
  static List<Map<String, String>> getSupportedChains() {
    return [
      {'id': 'eth', 'name': 'Ethereum Mainnet', 'chainId': '0x1'},
      {'id': 'sepolia', 'name': 'Ethereum Sepolia', 'chainId': '0xaa36a7'},
      {'id': 'polygon', 'name': 'Polygon Mainnet', 'chainId': '0x89'},
      {'id': 'bsc', 'name': 'BSC Mainnet', 'chainId': '0x38'},
    ];
  }

  static void dispose() {
    _client.close();
  }
}
