import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/wallet_provider.dart';
import '../../core/services/wallet_service.dart';
import '../../core/constants/app_constants.dart';
import 'verify_mnemonic_screen.dart';
import '../home/home_screen.dart';

class ImportWalletScreen extends StatefulWidget {
  const ImportWalletScreen({super.key});

  @override
  State<ImportWalletScreen> createState() => _ImportWalletScreenState();
}

class _ImportWalletScreenState extends State<ImportWalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _mnemonicController = TextEditingController();
  final _privateKeyController = TextEditingController();
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mnemonicController.dispose();
    _privateKeyController.dispose();
    super.dispose();
  }

  Future<void> _importFromMnemonic() async {
    final mnemonic = _mnemonicController.text.trim();

    if (mnemonic.isEmpty) {
      _showError('Please enter your seed phrase');
      return;
    }

    if (!WalletService.validateMnemonic(mnemonic)) {
      _showError('Invalid seed phrase. Please check and try again.');
      return;
    }

    setState(() {
      _isImporting = true;
    });

    try {
      final walletProvider = Provider.of<WalletProvider>(
        context,
        listen: false,
      );
      await walletProvider.importWalletFromMnemonic(mnemonic);

      if (mounted) {
        // Mnemonic import için doğrulama adımına git
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => VerifyMnemonicScreen(mnemonic: mnemonic),
          ),
        );
      }
    } catch (e) {
      _showError('Failed to import wallet: $e');
    } finally {
      setState(() {
        _isImporting = false;
      });
    }
  }

  Future<void> _importFromPrivateKey() async {
    final privateKey = _privateKeyController.text.trim();

    if (privateKey.isEmpty) {
      _showError('Please enter your private key');
      return;
    }

    setState(() {
      _isImporting = true;
    });

    try {
      final walletProvider = Provider.of<WalletProvider>(
        context,
        listen: false,
      );
      await walletProvider.importWalletFromPrivateKey(privateKey);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      _showError('Failed to import wallet: $e');
    } finally {
      setState(() {
        _isImporting = false;
      });
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Wallet'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Seed Phrase'),
            Tab(text: 'Private Key'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildMnemonicImport(), _buildPrivateKeyImport()],
      ),
    );
  }

  Widget _buildMnemonicImport() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter Your Seed Phrase',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Text(
              'Enter your 12 or 24-word seed phrase to restore your wallet.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: TextField(
                controller: _mnemonicController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: 'Enter your seed phrase here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.defaultBorderRadius,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(
                  AppConstants.defaultBorderRadius,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Separate each word with a space. Make sure the words are in the correct order.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isImporting ? null : _importFromMnemonic,
                child: _isImporting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Import Wallet'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivateKeyImport() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter Your Private Key',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Text(
              'Enter your private key to import your wallet.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _privateKeyController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Enter your private key...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.defaultBorderRadius,
                  ),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(
                  AppConstants.defaultBorderRadius,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Never share your private key with anyone. Keep it secure and private.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isImporting ? null : _importFromPrivateKey,
                child: _isImporting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Import Wallet'),
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}
