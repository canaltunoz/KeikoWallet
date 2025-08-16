import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/wallet_provider.dart';
import '../core/providers/theme_provider.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_elevation.dart';
import 'onboarding/onboarding_screen.dart';
import 'home/home_screen.dart';

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

    final walletProvider = Provider.of<WalletProvider>(context, listen: false);

    // Navigate based on wallet status
    if (walletProvider.hasWallet) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
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
