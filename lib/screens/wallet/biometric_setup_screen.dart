import 'package:flutter/material.dart';
import '../../core/services/biometric_service.dart';
import '../../core/services/wallet_unlock_service.dart';
import '../../core/theme/app_colors.dart';
import 'wallet_home_screen.dart';

class BiometricSetupScreen extends StatefulWidget {
  final WalletSession walletSession;
  final String password;
  
  const BiometricSetupScreen({
    super.key,
    required this.walletSession,
    required this.password,
  });

  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  bool _isLoading = false;
  bool _isBiometricAvailable = false;
  List<String> _availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _animationController.forward();
    _checkBiometricAvailability();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    final availability = await BiometricService.checkBiometricAvailability();
    setState(() {
      _isBiometricAvailable = availability.isAvailable;
      _availableBiometrics = availability.availableBiometrics
          ?.map((biometric) => biometric.toString().split('.').last)
          .toList() ?? [];
    });
  }

  Future<void> _enableBiometric() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await BiometricService.enableBiometricAuth(
        userId: widget.walletSession.userId,
        password: widget.password,
      );

      if (success && mounted) {
        _showSuccessSnackBar('Biometric authentication enabled successfully!');
        _navigateToHome();
      } else if (mounted) {
        _showErrorSnackBar('Failed to enable biometric authentication');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _skipBiometric() {
    _navigateToHome();
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => WalletHomeScreen(
          walletSession: widget.walletSession,
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 60),
                
                // Biometric Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.fingerprint,
                    size: 60,
                    color: AppColors.onPrimary,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Title
                const Text(
                  'Secure Your Wallet',
                  style: TextStyle(
                    color: AppColors.darkOnSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Description
                Text(
                  _isBiometricAvailable
                      ? 'Enable biometric authentication for quick and secure access to your wallet'
                      : 'Biometric authentication is not available on this device',
                  style: TextStyle(
                    color: AppColors.darkOnSurface.withOpacity(0.8),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 48),
                
                // Benefits
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildBenefitItem(
                        Icons.speed,
                        'Quick Access',
                        'Unlock your wallet instantly',
                      ),
                      _buildBenefitItem(
                        Icons.security,
                        'Enhanced Security',
                        'Your biometric data stays on device',
                      ),
                      _buildBenefitItem(
                        Icons.privacy_tip,
                        'Privacy Protected',
                        'No passwords to remember or type',
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Action Buttons
                if (_isBiometricAvailable) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _enableBiometric,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.onPrimary,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.fingerprint),
                      label: Text(
                        _isLoading ? 'Setting up...' : 'Enable Biometric',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                ],
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _skipBiometric,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.darkOnSurface,
                      side: BorderSide(
                        color: AppColors.darkOnSurface.withOpacity(0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _isBiometricAvailable ? 'Skip for Now' : 'Continue',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.darkOnSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: AppColors.darkOnSurface.withOpacity(0.7),
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
