import 'wallet_creation_service.dart';
import 'wallet_unlock_service.dart';

/// Test service for wallet operations
class WalletTestService {
  /// Test complete wallet creation and unlock flow
  static Future<void> testWalletFlow() async {
    try {
      print('=== Wallet Flow Test Started ===');

      const testUserId = 'test_user_123';
      const testPassword = 'TestPassword123!';

      // 1. Test password strength validation
      final passwordStrength = WalletCreationService.validatePasswordStrength(testPassword);
      print('✓ Password strength: ${passwordStrength.displayName}');

      // 2. Test mnemonic generation
      final generatedMnemonic = WalletCreationService.generateMnemonic();
      print('✓ Generated mnemonic: ${generatedMnemonic.split(' ').length} words');

      // 3. Test mnemonic validation
      final isValidMnemonic = WalletCreationService.validateMnemonic(generatedMnemonic);
      print('✓ Mnemonic validation: ${isValidMnemonic ? 'PASSED' : 'FAILED'}');

      // 4. Check if wallet exists (should be false initially)
      final hasWalletBefore = await WalletCreationService.hasWallet(testUserId);
      print('✓ Has wallet before creation: ${hasWalletBefore ? 'YES' : 'NO'}');

      // 5. Create wallet
      print('--- Creating wallet ---');
      final createResult = await WalletCreationService.createWallet(
        userId: testUserId,
        password: testPassword,
      );

      if (createResult.success) {
        print('✓ Wallet created successfully');
        print('  - Wallet ID: ${createResult.walletId}');
        print('  - Mnemonic: ${createResult.mnemonic?.split(' ').length} words');
      } else {
        print('✗ Wallet creation failed: ${createResult.error}');
        return;
      }

      // 6. Check if wallet exists (should be true now)
      final hasWalletAfter = await WalletCreationService.hasWallet(testUserId);
      print('✓ Has wallet after creation: ${hasWalletAfter ? 'YES' : 'NO'}');

      // 7. Get wallet metadata
      final metadata = await WalletUnlockService.getWalletMetadata(testUserId);
      if (metadata != null) {
        print('✓ Wallet metadata retrieved:');
        print('  - Version: ${metadata['version']}');
        print('  - Created: ${metadata['created_at']}');
        print('  - Name: ${metadata['metadata']['name']}');
      }

      // 8. Test unlock with correct password
      print('--- Unlocking wallet with correct password ---');
      final unlockResult = await WalletUnlockService.unlockWallet(
        userId: testUserId,
        password: testPassword,
      );

      if (unlockResult.success && unlockResult.walletSession != null) {
        final session = unlockResult.walletSession!;
        print('✓ Wallet unlocked successfully');
        print('  - User ID: ${session.userId}');
        print('  - Name: ${session.name}');
        print('  - Type: ${session.type}');
        print('  - Coin Type: ${session.coinType}');
        print('  - Seed length: ${session.seed.length} bytes');
        print('  - Unlocked at: ${session.unlockedAt}');

        // Dispose session
        session.dispose();
        print('✓ Session disposed');
      } else {
        print('✗ Wallet unlock failed: ${unlockResult.error}');
        return;
      }

      // 9. Test unlock with wrong password
      print('--- Testing unlock with wrong password ---');
      final wrongUnlockResult = await WalletUnlockService.unlockWallet(
        userId: testUserId,
        password: 'WrongPassword123!',
      );

      if (!wrongUnlockResult.success) {
        print('✓ Wrong password correctly rejected: ${wrongUnlockResult.error}');
      } else {
        print('✗ Wrong password test failed (should have been rejected)');
      }

      // 10. Test password verification
      final correctPasswordVerify = await WalletUnlockService.verifyPassword(
        userId: testUserId,
        password: testPassword,
      );
      print('✓ Correct password verification: ${correctPasswordVerify ? 'PASSED' : 'FAILED'}');

      final wrongPasswordVerify = await WalletUnlockService.verifyPassword(
        userId: testUserId,
        password: 'WrongPassword',
      );
      print('✓ Wrong password verification: ${wrongPasswordVerify ? 'FAILED' : 'PASSED'}');

      // 11. Test wallet import
      print('--- Testing wallet import ---');
      const importUserId = 'import_user_456';
      final importResult = await WalletCreationService.importWallet(
        userId: importUserId,
        password: testPassword,
        mnemonic: createResult.mnemonic!,
      );

      if (importResult.success) {
        print('✓ Wallet imported successfully');
        
        // Unlock imported wallet
        final importUnlockResult = await WalletUnlockService.unlockWallet(
          userId: importUserId,
          password: testPassword,
        );
        
        if (importUnlockResult.success) {
          print('✓ Imported wallet unlocked successfully');
          importUnlockResult.walletSession?.dispose();
        }
      } else {
        print('✗ Wallet import failed: ${importResult.error}');
      }

      // 12. Cleanup test wallets
      print('--- Cleaning up test wallets ---');
      final deleted1 = await WalletCreationService.deleteWallet(testUserId);
      final deleted2 = await WalletCreationService.deleteWallet(importUserId);
      print('✓ Test wallets deleted: ${deleted1 && deleted2 ? 'SUCCESS' : 'PARTIAL'}');

      print('=== Wallet Flow Test Completed Successfully ===');

    } catch (e) {
      print('✗ Wallet Flow Test Failed: $e');
      rethrow;
    }
  }

  /// Test password strength validation
  static void testPasswordStrength() {
    print('=== Password Strength Test ===');

    final testPasswords = [
      '123',
      'password',
      'Password1',
      'Password123!',
      'MyVerySecurePassword123!@#',
    ];

    for (final password in testPasswords) {
      final strength = WalletCreationService.validatePasswordStrength(password);
      print('Password: "$password" -> ${strength.displayName}');
      print('  ${strength.description}');
    }

    print('=== Password Strength Test Completed ===');
  }

  /// Test mnemonic operations
  static void testMnemonicOperations() {
    print('=== Mnemonic Operations Test ===');

    // Test generation
    final mnemonic1 = WalletCreationService.generateMnemonic();
    final mnemonic2 = WalletCreationService.generateMnemonic();
    print('✓ Generated mnemonic 1: ${mnemonic1.split(' ').length} words');
    print('✓ Generated mnemonic 2: ${mnemonic2.split(' ').length} words');
    print('✓ Mnemonics are different: ${mnemonic1 != mnemonic2 ? 'YES' : 'NO'}');

    // Test validation
    final validTests = [
      mnemonic1,
      mnemonic2,
      'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
      'invalid mnemonic phrase here',
      'abandon abandon abandon', // too short
    ];

    for (final test in validTests) {
      final isValid = WalletCreationService.validateMnemonic(test);
      print('Mnemonic: "${test.substring(0, 20)}..." -> ${isValid ? 'VALID' : 'INVALID'}');
    }

    print('=== Mnemonic Operations Test Completed ===');
  }
}
