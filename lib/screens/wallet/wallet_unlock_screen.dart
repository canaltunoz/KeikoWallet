import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/wallet_unlock_service.dart';
import '../../core/services/biometric_service.dart';
import '../../core/services/password_management_service.dart';
import '../../core/theme/app_colors.dart';
import 'wallet_home_screen.dart';

class WalletUnlockScreen extends StatefulWidget {
  const WalletUnlockScreen({super.key});

  @override
  State<WalletUnlockScreen> createState() => _WalletUnlockScreenState();
}

class _WalletUnlockScreenState extends State<WalletUnlockScreen>
    with TickerProviderStateMixin {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;

  String? _errorMessage;
  LockoutStatus? _lockoutStatus;

  late AnimationController _animationController;
  late AnimationController _shakeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _animationController.forward();
    _checkBiometricAvailability();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _animationController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId =
        authProvider.currentUser?.id ??
        authProvider.currentUser?.email ??
        'unknown';

    final availability = await BiometricService.checkBiometricAvailability();
    final isEnabled = await BiometricService.isBiometricEnabled(userId);

    setState(() {
      _isBiometricAvailable = availability.isAvailable;
      _isBiometricEnabled = isEnabled;
    });
  }

  Future<void> _unlockWallet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId =
        authProvider.currentUser?.id ??
        authProvider.currentUser?.email ??
        'unknown';

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await WalletUnlockService.unlockWallet(
        userId: userId,
        password: _passwordController.text,
      );

      if (result.success && mounted) {
        // Navigate to wallet home screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                WalletHomeScreen(walletSession: result.walletSession!),
          ),
        );
      } else if (mounted) {
        setState(() {
          _errorMessage = result.error;
          _lockoutStatus = result.lockoutStatus;
        });
        _shakeController.forward().then((_) => _shakeController.reset());
        _passwordController.clear();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error unlocking wallet: $e';
        });
        _shakeController.forward().then((_) => _shakeController.reset());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _unlockWithBiometrics() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId =
        authProvider.currentUser?.id ??
        authProvider.currentUser?.email ??
        'unknown';

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await WalletUnlockService.unlockWalletWithBiometrics(
        userId: userId,
        reason: 'Unlock your Keiko Wallet',
      );

      if (result.success && mounted) {
        // Navigate to wallet home screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                WalletHomeScreen(walletSession: result.walletSession!),
          ),
        );
      } else if (mounted) {
        setState(() {
          _errorMessage = result.error;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Biometric unlock failed: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),

                  // Logo and Title
                  Column(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/keiko_logo.jpeg',
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet,
                                  size: 60,
                                  color: AppColors.onPrimary,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Welcome Back',
                        style: TextStyle(
                          color: AppColors.darkOnSurface,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Unlock your wallet to continue',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),

                  // Lockout Status
                  if (_lockoutStatus != null &&
                      _lockoutStatus!.isLockedOut) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.error.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_clock,
                            color: AppColors.error,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Account Locked',
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Try again in ${_lockoutStatus!.remainingLockoutMinutes} minutes',
                                  style: TextStyle(
                                    color: AppColors.darkOnSurface.withOpacity(
                                      0.8,
                                    ),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Error Message
                  if (_errorMessage != null) ...[
                    AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(
                            _shakeAnimation.value *
                                10 *
                                (1 - _shakeAnimation.value),
                            0,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.error.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: AppColors.error,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    enabled:
                        _lockoutStatus == null || !_lockoutStatus!.isLockedOut,
                    style: const TextStyle(color: AppColors.darkOnSurface),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: AppColors.primary),
                      hintText: 'Enter your wallet password',
                      hintStyle: TextStyle(
                        color: AppColors.darkOnSurface.withOpacity(0.6),
                      ),
                      prefixIcon: const Icon(
                        Icons.lock,
                        color: AppColors.primary,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.primary,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: AppColors.darkSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: AppColors.darkOnSurface.withOpacity(0.3),
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _unlockWallet(),
                  ),

                  const SizedBox(height: 32),

                  // Unlock Button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed:
                          (_isLoading ||
                              (_lockoutStatus != null &&
                                  _lockoutStatus!.isLockedOut))
                          ? null
                          : _unlockWallet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: AppColors.onPrimary,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Unlock Wallet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  // Biometric Unlock
                  if (_isBiometricAvailable && _isBiometricEnabled) ...[
                    const SizedBox(height: 24),
                    const Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.primary)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ),
                        Expanded(child: Divider(color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _unlockWithBiometrics,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.fingerprint, size: 24),
                        label: const Text(
                          'Unlock with Biometrics',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Remaining Attempts
                  if (_lockoutStatus != null &&
                      !_lockoutStatus!.isLockedOut &&
                      _lockoutStatus!.failedAttempts > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.warning.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            color: AppColors.warning,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${_lockoutStatus!.remainingAttempts} attempts remaining before lockout',
                              style: const TextStyle(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
