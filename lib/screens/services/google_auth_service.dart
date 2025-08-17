import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GoogleAuthService {
  static GoogleSignIn? _googleSignIn;

  /// Google Sign-In başlatma (opsiyonel serverClientId ile)
  static void _initialize({required bool withServerId}) {
    print('Initializing Google Sign-In...');
    String? webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];

    if (withServerId && (webClientId == null || webClientId.isEmpty)) {
      print(
        'WARN: GOOGLE_WEB_CLIENT_ID .env dosyasında bulunamadı; serverClientId olmadan devam edilecek.',
      );
      withServerId = false;
      webClientId = null;
    }

    if (withServerId && webClientId != null) {
      print('Web Client ID: ${webClientId.substring(0, 20)}...');
    }

    _googleSignIn = GoogleSignIn(
      serverClientId: withServerId ? webClientId : null,
      scopes: const ['email', 'profile'],
    );
    print(
      'Google Sign-In initialized successfully${withServerId ? ' (with serverClientId)' : ''}',
    );
  }

  /// Initialize Google Sign-In with Web Client ID
  static GoogleSignIn get _instance {
    if (_googleSignIn == null) {
      final withServerId =
          (dotenv.env['GOOGLE_WITH_SERVER_ID'] ?? 'true').toLowerCase() ==
          'true';
      _initialize(withServerId: withServerId);
    }
    return _googleSignIn!;
  }

  /// Sign in with Google
  static Future<GoogleSignInAccount?> signIn() async {
    try {
      final GoogleSignInAccount? account = await _instance.signIn();
      return account;
    } catch (error) {
      print('Google Sign-In Error: $error');
      return null;
    }
  }

  /// Sign out from Google
  static Future<void> signOut() async {
    try {
      await _instance.signOut();
    } catch (error) {
      print('Google Sign-Out Error: $error');
    }
  }

  /// Get current signed-in user
  static GoogleSignInAccount? get currentUser {
    return _instance.currentUser;
  }

  /// Check if user is signed in
  static bool get isSignedIn {
    return _instance.currentUser != null;
  }

  /// Get user authentication details
  static Future<GoogleSignInAuthentication?> getAuthentication() async {
    try {
      final GoogleSignInAccount? account = _instance.currentUser;
      if (account != null) {
        return await account.authentication;
      }
      return null;
    } catch (error) {
      print('Google Authentication Error: $error');
      return null;
    }
  }

  /// Silent sign-in (if user was previously signed in)
  static Future<GoogleSignInAccount?> signInSilently() async {
    try {
      final GoogleSignInAccount? account = await _instance.signInSilently();
      return account;
    } catch (error) {
      print('Google Silent Sign-In Error: $error');
      return null;
    }
  }

  /// Disconnect from Google (revoke access)
  static Future<void> disconnect() async {
    try {
      await _instance.disconnect();
    } catch (error) {
      print('Google Disconnect Error: $error');
    }
  }
}
