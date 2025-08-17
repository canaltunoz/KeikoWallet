import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/wallet_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/constants/app_constants.dart';
import 'core/services/env_service.dart';
import 'core/services/wallet_blob_service.dart';
import 'core/services/crypto_service.dart';

import 'core/theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/settings/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment variables
  await EnvService.initialize();

  // Validate required environment variables
  EnvService.validateRequiredVars();

  // Initialize database
  await WalletBlobService.initialize();

  // Initialize crypto service
  await CryptoService.initialize();

  runApp(const KeikoWalletApp());
}

class KeikoWalletApp extends StatelessWidget {
  const KeikoWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => WalletProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: AppConstants.appName,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
            routes: {
              '/splash': (context) => const SplashScreen(),
              '/settings': (context) => const SettingsScreen(),
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
