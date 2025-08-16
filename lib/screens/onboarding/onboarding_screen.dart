import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_elevation.dart';
import 'create_wallet_screen.dart';
import 'import_wallet_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.06), // %6 of screen width
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Modern Logo with gradient background
                      Container(
                        width: screenWidth * 0.4, // %40 of screen width
                        height:
                            screenWidth * 0.4, // %40 of screen width (square)
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.1,
                          ), // %10 of screen width
                          boxShadow: AppElevation.elevation4,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Decorative circles
                            Positioned(
                              top: screenWidth * 0.05, // %5 of screen width
                              right: screenWidth * 0.05, // %5 of screen width
                              child: Container(
                                width:
                                    screenWidth * 0.075, // %7.5 of screen width
                                height:
                                    screenWidth * 0.075, // %7.5 of screen width
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(
                                    screenWidth * 0.0375,
                                  ), // %3.75 of screen width
                                ),
                              ),
                            ),
                            Positioned(
                              bottom:
                                  screenWidth * 0.075, // %7.5 of screen width
                              left: screenWidth * 0.075, // %7.5 of screen width
                              child: Container(
                                width: screenWidth * 0.05, // %5 of screen width
                                height:
                                    screenWidth * 0.05, // %5 of screen width
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(
                                    screenWidth * 0.025,
                                  ), // %2.5 of screen width
                                ),
                              ),
                            ),
                            // Main wallet icon
                            Icon(
                              Icons.account_balance_wallet_rounded,
                              size: screenWidth * 0.2, // %20 of screen width
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(
                        height: screenHeight * 0.06,
                      ), // %6 of screen height
                      // Welcome Text with modern typography
                      Text(
                        'Welcome to\n${AppConstants.appName}',
                        style: AppTypography.displaySmall.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(
                        height: screenHeight * 0.025,
                      ), // %2.5 of screen height
                      // Modern description with better styling
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                        ), // %4 of screen width
                        child: Text(
                          'Your secure gateway to decentralized finance.\nCreate or import a wallet to start your Web3 journey.',
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

                // Modern Action Buttons
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Create New Wallet - Primary Action
                      Container(
                        width: double.infinity,
                        height: screenHeight * 0.07, // %7 of screen height
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.04,
                          ), // %4 of screen width
                          boxShadow: AppElevation.elevation2,
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const CreateWalletScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.04,
                              ), // %4 of screen width
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_circle_outline,
                                color: Colors.white,
                                size: screenWidth * 0.06, // %6 of screen width
                              ),
                              SizedBox(
                                width: screenWidth * 0.03,
                              ), // %3 of screen width
                              Text(
                                'Create New Wallet',
                                style: AppTypography.buttonLarge.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(
                        height: screenHeight * 0.02,
                      ), // %2 of screen height
                      // Import Existing Wallet - Secondary Action
                      Container(
                        width: double.infinity,
                        height: screenHeight * 0.07, // %7 of screen height
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.04,
                          ), // %4 of screen width
                          border: Border.all(
                            color: colorScheme.outline,
                            width: 1.5,
                          ),
                          boxShadow: AppElevation.elevation1,
                        ),
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ImportWalletScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.04,
                              ), // %4 of screen width
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.download_outlined,
                                color: colorScheme.primary,
                                size: screenWidth * 0.06, // %6 of screen width
                              ),
                              SizedBox(
                                width: screenWidth * 0.03,
                              ), // %3 of screen width
                              Text(
                                'Import Existing Wallet',
                                style: AppTypography.buttonLarge.copyWith(
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(
                        height: screenHeight * 0.05,
                      ), // %5 of screen height
                      // Modern Terms and Privacy with better styling
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.05,
                        ), // %5 of screen width
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
}
