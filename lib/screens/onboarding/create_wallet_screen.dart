import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/providers/wallet_provider.dart';
import '../../core/constants/app_constants.dart';
import 'verify_mnemonic_screen.dart';

class CreateWalletScreen extends StatefulWidget {
  const CreateWalletScreen({super.key});

  @override
  State<CreateWalletScreen> createState() => _CreateWalletScreenState();
}

class _CreateWalletScreenState extends State<CreateWalletScreen> {
  String? _mnemonic;
  bool _isCreating = false;
  bool _mnemonicRevealed = false;
  bool _hasConfirmedBackup = false;

  Future<void> _createWallet() async {
    setState(() {
      _isCreating = true;
    });

    try {
      final walletProvider = Provider.of<WalletProvider>(
        context,
        listen: false,
      );
      final mnemonic = await walletProvider.createNewWallet();

      setState(() {
        _mnemonic = mnemonic;
        _isCreating = false;
      });
    } catch (e) {
      setState(() {
        _isCreating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create wallet: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _copyMnemonic() {
    if (_mnemonic != null) {
      Clipboard.setData(ClipboardData(text: _mnemonic!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seed phrase copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _proceedToVerification() {
    if (_mnemonic != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VerifyMnemonicScreen(mnemonic: _mnemonic!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Wallet')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: _mnemonic == null ? _buildCreateStep() : _buildBackupStep(),
        ),
      ),
    );
  }

  Widget _buildCreateStep() {
    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),

              Text(
                'Create Your Wallet',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              Text(
                'We\'ll generate a secure 12-word seed phrase for you. This phrase is the key to your wallet and must be kept safe.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

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
                        'Never share your seed phrase with anyone. Anyone with access to it can control your wallet.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isCreating ? null : _createWallet,
            child: _isCreating
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Generate Wallet'),
          ),
        ),
      ],
    );
  }

  Widget _buildBackupStep() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Backup Your Seed Phrase',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'Write down these 12 words in the exact order shown. Store them in a safe place.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),

                // Seed Phrase Display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(
                      AppConstants.defaultBorderRadius,
                    ),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: Column(
                    children: [
                      if (!_mnemonicRevealed) ...[
                        Icon(
                          Icons.visibility_off,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tap to reveal your seed phrase',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _mnemonicRevealed = true;
                            });
                          },
                          child: const Text('Reveal Seed Phrase'),
                        ),
                      ] else ...[
                        _buildMnemonicGrid(),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton.icon(
                              onPressed: _copyMnemonic,
                              icon: const Icon(Icons.copy),
                              label: const Text('Copy'),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _mnemonicRevealed = false;
                                });
                              },
                              icon: const Icon(Icons.visibility_off),
                              label: const Text('Hide'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Confirmation Checkbox
                CheckboxListTile(
                  value: _hasConfirmedBackup,
                  onChanged: (value) {
                    setState(() {
                      _hasConfirmedBackup = value ?? false;
                    });
                  },
                  title: const Text('I have safely stored my seed phrase'),
                  subtitle: const Text(
                    'I understand that losing it means losing access to my wallet',
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
        ),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _hasConfirmedBackup ? _proceedToVerification : null,
            child: const Text('Doğrulama Adımına Geç'),
          ),
        ),
      ],
    );
  }

  Widget _buildMnemonicGrid() {
    final words = _mnemonic!.split(' ');

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive dimensions
        final availableWidth = constraints.maxWidth;
        final spacing = 8.0;
        final itemWidth = (availableWidth - (spacing * 2)) / 3;
        final itemHeight = itemWidth * 0.7; // Adjusted ratio

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: itemWidth / itemHeight,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: words.length,
          itemBuilder: (context, index) {
            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: itemWidth * 0.05,
                vertical: itemHeight * 0.1,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Index number
                  Container(
                    constraints: BoxConstraints(maxHeight: itemHeight * 0.25),
                    child: FittedBox(
                      child: Text(
                        '${index + 1}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),

                  // Spacing
                  SizedBox(height: itemHeight * 0.05),

                  // Word
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          words[index],
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
