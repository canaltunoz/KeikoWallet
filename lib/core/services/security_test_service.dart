import 'password_management_service.dart';
import 'biometric_service.dart';
import 'wallet_creation_service.dart';
import 'wallet_unlock_service.dart';

/// Test service for security features
class SecurityTestService {
  /// Test password management and brute force protection
  static Future<void> testPasswordManagement() async {
    try {
      print('=== Password Management Test Started ===');

      const testUserId = 'security_test_user';
      const correctPassword = 'TestPassword123!';
      const wrongPassword = 'WrongPassword123!';

      // 1. Test password strength validation
      print('--- Testing password strength validation ---');
      final passwords = [
        '123',
        'password',
        'Password1',
        'Password123!',
        'MyVerySecurePassword123!@#',
        'password123', // common password
        'abc123def', // sequential characters
        'aaa111bbb', // repeated characters
      ];

      for (final password in passwords) {
        final result = PasswordManagementService.validatePassword(password);
        print('Password: "$password"');
        print('  Strength: ${result.strength.name}');
        print('  Score: ${result.score}');
        print('  Valid: ${result.isValid}');
        if (result.issues.isNotEmpty) {
          print('  Issues: ${result.issues.join(', ')}');
        }
        print('');
      }

      // 2. Test secure password generation
      print('--- Testing secure password generation ---');
      for (int i = 0; i < 3; i++) {
        final generated = PasswordManagementService.generateSecurePassword();
        final validation = PasswordManagementService.validatePassword(generated);
        print('Generated: "$generated" (${validation.strength.name})');
      }

      // 3. Create test wallet
      print('--- Creating test wallet ---');
      final createResult = await WalletCreationService.createWallet(
        userId: testUserId,
        password: correctPassword,
      );

      if (!createResult.success) {
        print('✗ Failed to create test wallet: ${createResult.error}');
        return;
      }
      print('✓ Test wallet created');

      // 4. Test lockout status (should be clean initially)
      final initialStatus = await PasswordManagementService.getLockoutStatus(testUserId);
      print('✓ Initial lockout status: ${initialStatus.failedAttempts} failed attempts');

      // 5. Test successful unlock (should not affect lockout)
      print('--- Testing successful unlock ---');
      final successResult = await WalletUnlockService.unlockWallet(
        userId: testUserId,
        password: correctPassword,
      );

      if (successResult.success) {
        print('✓ Successful unlock');
        successResult.walletSession?.dispose();
      } else {
        print('✗ Unexpected unlock failure: ${successResult.error}');
      }

      // 6. Test failed attempts and progressive lockout
      print('--- Testing failed attempts and lockout ---');
      for (int attempt = 1; attempt <= 7; attempt++) {
        print('Attempt $attempt with wrong password...');
        
        final failResult = await WalletUnlockService.unlockWallet(
          userId: testUserId,
          password: wrongPassword,
        );

        if (!failResult.success) {
          print('  Failed as expected: ${failResult.error}');
          if (failResult.lockoutStatus != null) {
            final status = failResult.lockoutStatus!;
            print('  Failed attempts: ${status.failedAttempts}');
            print('  Remaining attempts: ${status.remainingAttempts}');
            if (status.isLockedOut) {
              print('  LOCKED OUT until: ${status.lockoutUntil}');
              print('  Remaining lockout: ${status.remainingLockoutMinutes} minutes');
              break;
            }
          }
        } else {
          print('✗ Unexpected success with wrong password');
        }

        // Small delay between attempts
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // 7. Test unlock while locked out
      print('--- Testing unlock while locked out ---');
      final lockedResult = await WalletUnlockService.unlockWallet(
        userId: testUserId,
        password: correctPassword,
      );

      if (!lockedResult.success && lockedResult.error!.contains('locked')) {
        print('✓ Correctly blocked during lockout: ${lockedResult.error}');
      } else {
        print('✗ Lockout not working properly');
      }

      // 8. Clear lockout and test recovery
      print('--- Testing lockout recovery ---');
      await PasswordManagementService.clearLockoutData(testUserId);
      
      final recoveryResult = await WalletUnlockService.unlockWallet(
        userId: testUserId,
        password: correctPassword,
      );

      if (recoveryResult.success) {
        print('✓ Successfully unlocked after lockout cleared');
        recoveryResult.walletSession?.dispose();
      } else {
        print('✗ Failed to unlock after lockout cleared: ${recoveryResult.error}');
      }

      // 9. Cleanup
      await WalletCreationService.deleteWallet(testUserId);
      await PasswordManagementService.clearLockoutData(testUserId);
      print('✓ Test wallet and lockout data cleaned up');

      print('=== Password Management Test Completed ===');

    } catch (e) {
      print('✗ Password Management Test Failed: $e');
      rethrow;
    }
  }

  /// Test biometric authentication
  static Future<void> testBiometricAuthentication() async {
    try {
      print('=== Biometric Authentication Test Started ===');

      // 1. Check biometric availability
      final availability = await BiometricService.checkBiometricAvailability();
      print('Biometric availability: ${availability.isAvailable}');
      if (!availability.isAvailable) {
        print('Reason: ${availability.reason}');
        print('=== Biometric Test Skipped (Not Available) ===');
        return;
      }

      print('Available biometrics: ${availability.availableBiometrics}');

      const testUserId = 'biometric_test_user';
      const testPassword = 'BiometricTest123!';

      // 2. Create test wallet
      final createResult = await WalletCreationService.createWallet(
        userId: testUserId,
        password: testPassword,
      );

      if (!createResult.success) {
        print('✗ Failed to create test wallet: ${createResult.error}');
        return;
      }
      print('✓ Test wallet created');

      // 3. Test biometric status (should be disabled initially)
      final initialStatus = await BiometricService.isBiometricEnabled(testUserId);
      print('✓ Initial biometric status: ${initialStatus ? 'ENABLED' : 'DISABLED'}');

      // 4. Test biometric authentication (should prompt user)
      print('--- Testing biometric authentication ---');
      print('NOTE: This will prompt for biometric authentication on device');
      
      final authResult = await BiometricService.authenticateWithBiometrics(
        reason: 'Test biometric authentication',
      );
      
      if (authResult.success) {
        print('✓ Biometric authentication successful');
        
        // 5. Enable biometric auth
        final enableResult = await BiometricService.enableBiometricAuth(
          userId: testUserId,
          password: testPassword,
        );
        
        if (enableResult) {
          print('✓ Biometric authentication enabled');
          
          // 6. Test biometric info
          final info = await BiometricService.getBiometricInfo(testUserId);
          if (info != null) {
            print('✓ Biometric info retrieved:');
            print('  Enabled: ${info.isEnabled}');
            print('  Setup date: ${info.setupDate}');
            print('  Types: ${info.biometricTypes}');
          }
          
          // 7. Test biometric unlock
          print('--- Testing biometric unlock ---');
          final unlockResult = await WalletUnlockService.unlockWalletWithBiometrics(
            userId: testUserId,
            reason: 'Test biometric wallet unlock',
          );
          
          if (unlockResult.success) {
            print('✓ Biometric wallet unlock successful');
            unlockResult.walletSession?.dispose();
          } else {
            print('✗ Biometric wallet unlock failed: ${unlockResult.error}');
          }
          
          // 8. Disable biometric auth
          final disableResult = await BiometricService.disableBiometricAuth(testUserId);
          if (disableResult) {
            print('✓ Biometric authentication disabled');
          }
          
        } else {
          print('✗ Failed to enable biometric authentication');
        }
        
      } else {
        print('✗ Biometric authentication failed: ${authResult.error}');
        print('This is expected if user cancelled or biometrics failed');
      }

      // 9. Cleanup
      await WalletCreationService.deleteWallet(testUserId);
      await BiometricService.disableBiometricAuth(testUserId);
      print('✓ Test wallet and biometric data cleaned up');

      print('=== Biometric Authentication Test Completed ===');

    } catch (e) {
      print('✗ Biometric Authentication Test Failed: $e');
      print('This may be expected if biometrics are not available or user cancelled');
    }
  }

  /// Test complete security flow
  static Future<void> testCompleteSecurity() async {
    print('=== Complete Security Test Started ===');
    
    await testPasswordManagement();
    print('');
    await testBiometricAuthentication();
    
    print('=== Complete Security Test Completed ===');
  }
}
