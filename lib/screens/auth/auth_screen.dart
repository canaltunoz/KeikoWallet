import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_elevation.dart';
import '../wallet/wallet_creation_screen.dart';
import '../wallet/wallet_unlock_screen.dart';
import '../wallet/wallet_home_screen.dart';
import '../../core/services/wallet_creation_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.06),
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        width: screenWidth * 0.3,
                        height: screenWidth * 0.3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.08,
                          ),
                          boxShadow: AppElevation.elevation4,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.08,
                          ),
                          child: Image.asset(
                            'assets/images/keiko_logo.jpeg',
                            width: screenWidth * 0.3,
                            height: screenWidth * 0.3,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback icon if image fails to load
                              return Container(
                                width: screenWidth * 0.3,
                                height: screenWidth * 0.3,
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(
                                    screenWidth * 0.08,
                                  ),
                                ),
                                child: Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: screenWidth * 0.15,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.04),

                      // Welcome Text
                      Text(
                        'Welcome to\n${AppConstants.appName}',
                        style: AppTypography.displaySmall.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // Description
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                        ),
                        child: Text(
                          'Choose how you want to get started with your secure wallet',
                          style: AppTypography.bodyLarge.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Google Sign In Button
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          return Container(
                            width: double.infinity,
                            height: screenHeight * 0.07,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.04,
                              ),
                              border: Border.all(
                                color: colorScheme.outline.withValues(
                                  alpha: 0.3,
                                ),
                                width: 1,
                              ),
                              boxShadow: AppElevation.elevation2,
                            ),
                            child: ElevatedButton(
                              onPressed: authProvider.isLoading
                                  ? null
                                  : () => _handleGoogleSignIn(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black87,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    screenWidth * 0.04,
                                  ),
                                ),
                              ),
                              child: authProvider.isLoading
                                  ? SizedBox(
                                      width: screenWidth * 0.05,
                                      height: screenWidth * 0.05,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/images/google_logo.png',
                                          width: screenWidth * 0.06,
                                          height: screenWidth * 0.06,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Icon(
                                                  Icons.login,
                                                  size: screenWidth * 0.06,
                                                  color: Colors.blue,
                                                );
                                              },
                                        ),
                                        SizedBox(width: screenWidth * 0.03),
                                        Text(
                                          'Continue with Google',
                                          style: AppTypography.buttonLarge
                                              .copyWith(color: Colors.black87),
                                        ),
                                      ],
                                    ),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // Divider
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: colorScheme.outline.withValues(alpha: 0.3),
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.04,
                            ),
                            child: Text(
                              'or',
                              style: AppTypography.bodyMedium.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: colorScheme.outline.withValues(alpha: 0.3),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // Create/Import Wallet Button
                      Container(
                        width: double.infinity,
                        height: screenHeight * 0.07,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.04,
                          ),
                          boxShadow: AppElevation.elevation2,
                        ),
                        child: ElevatedButton(
                          onPressed: () => _navigateToWalletOptions(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.04,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.account_balance_wallet_outlined,
                                color: Colors.white,
                                size: screenWidth * 0.06,
                              ),
                              SizedBox(width: screenWidth * 0.03),
                              Text(
                                'Create or Import Wallet',
                                style: AppTypography.buttonLarge.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.04),

                      // Terms and Privacy
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.05,
                        ),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: AppTypography.bodySmall.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.8,
                              ),
                              height: 1.4,
                            ),
                            children: [
                              const TextSpan(
                                text: 'By continuing, you agree to our ',
                              ),
                              TextSpan(
                                text: 'Terms of Service',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.signInWithGoogle();

    if (success && mounted) {
      // Google login başarılı, kullanıcının wallet'ı var mı kontrol et
      final userId =
          authProvider.currentUser?.id ??
          authProvider.currentUser?.email ??
          'unknown';
      final hasWallet = await WalletCreationService.hasExistingWallet(userId);

      if (hasWallet) {
        print(
          'AuthScreen: User has existing wallet, trying biometric unlock...',
        );
        // Wallet varsa önce biometric unlock dene
        final walletSession = await authProvider.tryBiometricUnlock();

        if (walletSession != null && mounted) {
          print(
            'AuthScreen: Biometric unlock successful, navigating to wallet home',
          );
          // Biometric unlock başarılı, direkt wallet home'a git
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) =>
                  WalletHomeScreen(walletSession: walletSession),
            ),
          );
        } else if (mounted) {
          print(
            'AuthScreen: Biometric unlock failed or not available, navigating to password screen',
          );
          // Biometric unlock başarısız veya aktif değil, şifre ekranına git
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const WalletUnlockScreen()),
          );
        }
      } else if (mounted) {
        // Wallet yoksa creation screen'e git
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WalletCreationScreen()),
        );
      }
    } else if (mounted && authProvider.error != null) {
      // Hata göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error!),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _navigateToWalletOptions() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const WalletCreationScreen()),
    );
  }
}
