import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../screens/services/google_auth_service.dart';
import '../services/biometric_service.dart';
import '../services/wallet_unlock_service.dart';
import '../services/wallet_creation_service.dart';

class AuthProvider extends ChangeNotifier {
  GoogleSignInAccount? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Getters
  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSignedIn => _currentUser != null;

  /// Initialize auth provider and check for existing session
  Future<void> initialize() async {
    try {
      _setLoading(true);
      _clearError();

      // Check if user was previously signed in
      final account = await GoogleAuthService.signInSilently();
      if (account != null) {
        _currentUser = account;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to initialize authentication: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      print('AuthProvider: Starting Google sign-in...');
      _setLoading(true);
      _clearError();

      final account = await GoogleAuthService.signIn();
      print('AuthProvider: Google sign-in result: $account');

      if (account != null) {
        print('AuthProvider: Sign-in successful! User: ${account.email}');
        _currentUser = account;
        notifyListeners();
        return true;
      } else {
        print('AuthProvider: Sign-in was cancelled or failed');
        _setError('Google sign-in was cancelled or failed');
        return false;
      }
    } catch (e) {
      print('AuthProvider: Sign-in error: $e');
      _setError('Failed to sign in with Google: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      _setLoading(true);
      _clearError();

      await GoogleAuthService.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _setError('Failed to sign out: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Disconnect from Google (revoke access)
  Future<void> disconnect() async {
    try {
      _setLoading(true);
      _clearError();

      await GoogleAuthService.disconnect();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _setError('Failed to disconnect: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get user authentication details
  Future<GoogleSignInAuthentication?> getAuthentication() async {
    try {
      return await GoogleAuthService.getAuthentication();
    } catch (e) {
      _setError('Failed to get authentication details: $e');
      return null;
    }
  }

  // Private helper methods
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
  }

  /// Check if user has existing wallet and try biometric unlock
  Future<WalletSession?> tryBiometricUnlock() async {
    if (_currentUser == null) return null;

    try {
      // Check if user has existing wallet
      final hasWallet = await WalletCreationService.hasExistingWallet(
        _currentUser!.id,
      );
      if (!hasWallet) return null;

      // Check if biometric is enabled
      final isBiometricEnabled = await BiometricService.isBiometricEnabled(
        _currentUser!.id,
      );
      if (!isBiometricEnabled) return null;

      // Try biometric unlock
      final result = await WalletUnlockService.unlockWalletWithBiometrics(
        userId: _currentUser!.id,
        reason: 'Unlock your Keiko Wallet',
      );

      if (result.success && result.walletSession != null) {
        print('AuthProvider: Biometric unlock successful');
        return result.walletSession;
      }

      return null;
    } catch (e) {
      print('AuthProvider: Biometric unlock failed: $e');
      return null;
    }
  }

  /// Check if user has existing wallet
  Future<bool> hasExistingWallet() async {
    if (_currentUser == null) return false;

    try {
      return await WalletCreationService.hasExistingWallet(_currentUser!.id);
    } catch (e) {
      print('AuthProvider: Error checking existing wallet: $e');
      return false;
    }
  }
}
