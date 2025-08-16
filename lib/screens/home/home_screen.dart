import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/providers/wallet_provider.dart';
import '../../core/constants/app_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh balances when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WalletProvider>(context, listen: false).refreshBalances();
    });
  }

  void _copyAddress() {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    if (walletProvider.currentWallet != null) {
      Clipboard.setData(
        ClipboardData(text: walletProvider.currentWallet!.address),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatAddress(String address) {
    if (address.length <= 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body: Consumer<WalletProvider>(
        builder: (context, walletProvider, child) {
          if (walletProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (walletProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${walletProvider.error}',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      walletProvider.refreshBalances();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!walletProvider.hasWallet) {
            return const Center(child: Text('No wallet found'));
          }

          final screenSize = MediaQuery.of(context).size;
          final screenWidth = screenSize.width;
          final screenHeight = screenSize.height;

          return RefreshIndicator(
            onRefresh: () => walletProvider.refreshBalances(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(screenWidth * 0.04), // %4 of screen width
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWalletCard(walletProvider, screenWidth, screenHeight),
                  SizedBox(height: screenHeight * 0.03), // %3 of screen height
                  _buildBalanceSection(
                    walletProvider,
                    screenWidth,
                    screenHeight,
                  ),
                  SizedBox(height: screenHeight * 0.03), // %3 of screen height
                  _buildActionButtons(screenWidth, screenHeight),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWalletCard(
    WalletProvider walletProvider,
    double screenWidth,
    double screenHeight,
  ) {
    final wallet = walletProvider.currentWallet!;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04), // %4 of screen width
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: screenWidth * 0.05, // %5 of screen width
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Icon(
                    Icons.account_balance_wallet,
                    size: screenWidth * 0.06, // %6 of screen width
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                SizedBox(width: screenWidth * 0.03), // %3 of screen width
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wallet.name ?? 'My Wallet',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: screenHeight * 0.005,
                      ), // %0.5 of screen height
                      Row(
                        children: [
                          Text(
                            _formatAddress(wallet.address),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          SizedBox(
                            width: screenWidth * 0.02,
                          ), // %2 of screen width
                          GestureDetector(
                            onTap: _copyAddress,
                            child: Icon(
                              Icons.copy,
                              size: screenWidth * 0.04, // %4 of screen width
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceSection(
    WalletProvider walletProvider,
    double screenWidth,
    double screenHeight,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Balances',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: screenHeight * 0.02), // %2 of screen height

        if (walletProvider.tokenBalances.isEmpty)
          Card(
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.04), // %4 of screen width
              child: Center(
                child: Text(
                  'No tokens found',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          )
        else
          ...walletProvider.tokenBalances.map((tokenBalance) {
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Text(
                    tokenBalance.token.symbol.substring(0, 1),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(tokenBalance.token.name),
                subtitle: Text(tokenBalance.token.symbol),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      tokenBalance.formattedBalance,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (tokenBalance.usdValue != null)
                      Text(
                        '\$${tokenBalance.usdValue!.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildActionButtons(double screenWidth, double screenHeight) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Navigate to send screen
            },
            icon: Icon(
              Icons.send,
              size: screenWidth * 0.05,
            ), // %5 of screen width
            label: const Text('Send'),
          ),
        ),
        SizedBox(width: screenWidth * 0.04), // %4 of screen width
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Navigate to receive screen
            },
            icon: Icon(
              Icons.qr_code,
              size: screenWidth * 0.05,
            ), // %5 of screen width
            label: const Text('Receive'),
          ),
        ),
      ],
    );
  }
}
