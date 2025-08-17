import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_elevation.dart';
import '../core/services/database_service.dart';
import 'auth/auth_screen.dart';
import 'wallet/wallet_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkWalletStatus();
  }

  Future<void> _checkWalletStatus() async {
    // Wait for the wallet provider to initialize
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Initialize auth provider
    print('SplashScreen: Initializing auth provider...');
    await authProvider.initialize();

    if (!mounted) return;

    print(
      'SplashScreen: Auth provider initialized. isSignedIn: ${authProvider.isSignedIn}',
    );
    print('SplashScreen: Current user: ${authProvider.currentUser?.email}');

    // Debug: Query wallet_blobs table
    await _debugQueryWalletBlobs(authProvider.currentUser?.id);

    // Navigate based on authentication and wallet status
    if (authProvider.isSignedIn) {
      print('SplashScreen: User is signed in, checking wallet status...');
      // User is signed in with Google, check if has wallet and try biometric unlock
      final hasWallet = await authProvider.hasExistingWallet();
      print('SplashScreen: Has existing wallet: $hasWallet');

      if (hasWallet) {
        print('SplashScreen: Trying biometric unlock...');
        // Try biometric unlock
        final walletSession = await authProvider.tryBiometricUnlock();

        if (walletSession != null && mounted) {
          print(
            'SplashScreen: Biometric unlock successful, navigating to wallet home',
          );
          // Biometric unlock successful, go to wallet home
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) =>
                  WalletHomeScreen(walletSession: walletSession),
            ),
          );
          return;
        } else {
          print('SplashScreen: Biometric unlock failed');
        }
      }

      // No wallet or biometric failed, go to auth screen
      print(
        'SplashScreen: Navigating to auth screen (signed in but no wallet or biometric failed)',
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      }
    } else {
      // User needs to authenticate
      print('SplashScreen: User not signed in, navigating to auth screen');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      }
    }
  }

  Future<void> _debugQueryWalletBlobs(String? userId) async {
    if (userId == null) return;

    try {
      final db = await DatabaseService.database;

      // Get all tables in database
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      );

      print('=== DATABASE TABLES DEBUG ===');
      print('Total tables: ${tables.length}');

      for (var table in tables) {
        final tableName = table['name'] as String;
        print('Table: $tableName');

        // Get table schema
        final schema = await db.rawQuery('PRAGMA table_info($tableName)');
        print('  Columns:');
        for (var column in schema) {
          print('    - ${column['name']} (${column['type']})');
        }

        // Get record count
        final count = await db.rawQuery(
          'SELECT COUNT(*) as count FROM $tableName',
        );
        final recordCount = count.first['count'];
        print('  Records: $recordCount');

        // Show all data for all tables
        if (recordCount != null && recordCount as int > 0) {
          final allData = await db.query(tableName);
          if (allData.isNotEmpty) {
            print('  All data:');
            for (var record in allData) {
              print('    $record');
            }
          }
        }
        print('');
      }

      print('=== END DATABASE DEBUG ===');
    } catch (e) {
      print('Debug query error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Modern Logo Container
                Container(
                  width: screenWidth * 0.35, // %35 of screen width
                  height: screenWidth * 0.35, // %35 of screen width (square)
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      screenWidth * 0.08,
                    ), // %8 of screen width
                    boxShadow: AppElevation.elevation3,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background circle
                      Container(
                        width: screenWidth * 0.25, // %25 of screen width
                        height: screenWidth * 0.25, // %25 of screen width
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.125,
                          ), // %12.5 of screen width
                        ),
                      ),
                      // Wallet icon
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        size: screenWidth * 0.125, // %12.5 of screen width
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.05), // %5 of screen height
                // App Name with modern typography
                Text(
                  AppConstants.appName,
                  style: AppTypography.displaySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                  ),
                ),

                SizedBox(height: screenHeight * 0.015), // %1.5 of screen height
                // Modern tagline
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.06, // %6 of screen width
                    vertical: screenHeight * 0.01, // %1 of screen height
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(
                      screenWidth * 0.05,
                    ), // %5 of screen width
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Secure • Modern • Decentralized',
                    style: AppTypography.bodyLarge.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.075), // %7.5 of screen height
                // Modern loading indicator
                Container(
                  padding: EdgeInsets.all(
                    screenWidth * 0.04,
                  ), // %4 of screen width
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(
                      screenWidth * 0.04,
                    ), // %4 of screen width
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: screenWidth * 0.08, // %8 of screen width
                        height: screenWidth * 0.08, // %8 of screen width
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: screenHeight * 0.015,
                      ), // %1.5 of screen height
                      Text(
                        'Initializing...',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.05), // %5 of screen height
                // Version info
                Text(
                  'v${AppConstants.appVersion}',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
