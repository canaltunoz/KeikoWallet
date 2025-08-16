import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvService {
  static bool _isInitialized = false;

  /// Initialize environment variables
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await dotenv.load(fileName: '.env');
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to load environment variables: $e');
    }
  }

  /// Get Moralis API Key
  static String get moralisApiKey {
    _ensureInitialized();
    final apiKey = dotenv.env['MORALIS_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('MORALIS_API_KEY not found in environment variables');
    }
    return apiKey;
  }

  /// Get default network
  static String get defaultNetwork {
    _ensureInitialized();
    return dotenv.env['DEFAULT_NETWORK'] ?? 'sepolia';
  }

  /// Get Ethereum Mainnet RPC
  static String get ethereumMainnetRpc {
    _ensureInitialized();
    return dotenv.env['ETHEREUM_MAINNET_RPC'] ?? 'https://eth.llamarpc.com';
  }

  /// Get Ethereum Sepolia RPC
  static String get ethereumSepoliaRpc {
    _ensureInitialized();
    return dotenv.env['ETHEREUM_SEPOLIA_RPC'] ?? 'https://rpc.sepolia.org';
  }

  /// Get Polygon Mainnet RPC
  static String get polygonMainnetRpc {
    _ensureInitialized();
    return dotenv.env['POLYGON_MAINNET_RPC'] ?? 'https://polygon-rpc.com';
  }

  /// Get BSC Mainnet RPC
  static String get bscMainnetRpc {
    _ensureInitialized();
    return dotenv.env['BSC_MAINNET_RPC'] ?? 'https://bsc-dataseed.binance.org/';
  }

  /// Get app name
  static String get appName {
    _ensureInitialized();
    return dotenv.env['APP_NAME'] ?? 'Keiko Wallet';
  }

  /// Get app version
  static String get appVersion {
    _ensureInitialized();
    return dotenv.env['APP_VERSION'] ?? '1.0.0';
  }

  /// Check if debug mode is enabled
  static bool get isDebugMode {
    _ensureInitialized();
    final debugMode = dotenv.env['DEBUG_MODE'];
    return debugMode?.toLowerCase() == 'true';
  }

  /// Ensure environment is initialized
  static void _ensureInitialized() {
    if (!_isInitialized) {
      throw Exception('Environment service not initialized. Call EnvService.initialize() first.');
    }
  }

  /// Check if environment is initialized
  static bool get isInitialized => _isInitialized;

  /// Get all environment variables (for debugging)
  static Map<String, String> getAllEnvVars() {
    _ensureInitialized();
    return Map<String, String>.from(dotenv.env);
  }

  /// Validate required environment variables
  static void validateRequiredVars() {
    _ensureInitialized();
    
    final requiredVars = ['MORALIS_API_KEY'];
    final missingVars = <String>[];
    
    for (final varName in requiredVars) {
      final value = dotenv.env[varName];
      if (value == null || value.isEmpty) {
        missingVars.add(varName);
      }
    }
    
    if (missingVars.isNotEmpty) {
      throw Exception('Missing required environment variables: ${missingVars.join(', ')}');
    }
  }
}
