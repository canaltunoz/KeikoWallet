import 'dart:convert';
import '../models/wallet_blob.dart';
import 'database_service.dart';

class WalletBlobService {
  /// Save wallet blob for user
  static Future<bool> saveWalletBlob({
    required String userId,
    required Map<String, dynamic> walletData,
  }) async {
    try {
      final result = await DatabaseService.insertOrUpdateWalletBlob(
        userId: userId,
        blobJson: json.encode(walletData),
      );
      return result > 0;
    } catch (e) {
      print('Error saving wallet blob: $e');
      return false;
    }
  }

  /// Get wallet blob for user
  static Future<WalletBlob?> getWalletBlob(String userId) async {
    try {
      final map = await DatabaseService.getWalletBlob(userId);
      if (map != null) {
        return WalletBlob.fromMap(map);
      }
      return null;
    } catch (e) {
      print('Error getting wallet blob: $e');
      return null;
    }
  }

  /// Get wallet data for user
  static Future<Map<String, dynamic>?> getWalletData(String userId) async {
    try {
      final blob = await getWalletBlob(userId);
      return blob?.blobData;
    } catch (e) {
      print('Error getting wallet data: $e');
      return null;
    }
  }

  /// Check if user has wallet
  static Future<bool> hasWallet(String userId) async {
    try {
      return await DatabaseService.walletBlobExists(userId);
    } catch (e) {
      print('Error checking wallet existence: $e');
      return false;
    }
  }

  /// Delete wallet for user
  static Future<bool> deleteWallet(String userId) async {
    try {
      final result = await DatabaseService.deleteWalletBlob(userId);
      return result > 0;
    } catch (e) {
      print('Error deleting wallet: $e');
      return false;
    }
  }

  /// Get all wallet blobs
  static Future<List<WalletBlob>> getAllWalletBlobs() async {
    try {
      final maps = await DatabaseService.getAllWalletBlobs();
      return maps.map((map) => WalletBlob.fromMap(map)).toList();
    } catch (e) {
      print('Error getting all wallet blobs: $e');
      return [];
    }
  }

  /// Update wallet data for user
  static Future<bool> updateWalletData({
    required String userId,
    required Map<String, dynamic> walletData,
  }) async {
    return await saveWalletBlob(userId: userId, walletData: walletData);
  }

  /// Initialize database (call this in main.dart)
  static Future<void> initialize() async {
    try {
      await DatabaseService.database;
      print('Database initialized successfully');
    } catch (e) {
      print('Error initializing database: $e');
    }
  }
}
