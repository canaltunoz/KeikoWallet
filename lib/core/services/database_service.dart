import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'keiko_wallet.db';
  static const int _databaseVersion = 5;

  // Table names
  static const String tableWalletBlobs = 'wallet_blobs';

  // Wallet blobs table columns
  static const String columnUserId = 'user_id';
  static const String columnBlobJson = 'blob_json';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';

  /// Get database instance (singleton)
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  static Future<void> _onCreate(Database db, int version) async {
    // Create wallet_blobs table
    await db.execute('''
      CREATE TABLE $tableWalletBlobs (
        $columnUserId TEXT PRIMARY KEY,
        $columnBlobJson TEXT NOT NULL,
        $columnCreatedAt INTEGER NOT NULL,
        $columnUpdatedAt INTEGER NOT NULL
      )
    ''');
  }

  /// Handle database upgrades
  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    print('Database upgrade: $oldVersion → $newVersion');

    // Version 2 → 3: Remove wallets table
    if (oldVersion <= 2 && newVersion >= 3) {
      print('Removing unused wallets table...');
      try {
        await db.execute('DROP TABLE IF EXISTS wallets');
        print('Wallets table removed successfully');
      } catch (e) {
        print('Error removing wallets table: $e');
      }
    }

    // Version 3 → 4: Clear old wallet blobs for security upgrade
    if (oldVersion <= 3 && newVersion >= 4) {
      print('Clearing old wallet blobs for security upgrade...');
      try {
        await db.execute('DELETE FROM wallet_blobs');
        print('Old wallet blobs cleared successfully');
      } catch (e) {
        print('Error clearing wallet blobs: $e');
      }
    }

    // Version 4 → 5: Clear incompatible wallet blobs (memory parameter fix)
    if (oldVersion <= 4 && newVersion >= 5) {
      print('Clearing incompatible wallet blobs (memory parameter fix)...');
      try {
        await db.execute('DELETE FROM wallet_blobs');
        print('Incompatible wallet blobs cleared successfully');
      } catch (e) {
        print('Error clearing incompatible wallet blobs: $e');
      }
    }
  }

  /// Insert or update wallet blob
  static Future<int> insertOrUpdateWalletBlob({
    required String userId,
    required String blobJson,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Check if record exists
    final existing = await getWalletBlob(userId);

    if (existing != null) {
      // Update existing record
      return await db.update(
        tableWalletBlobs,
        {columnBlobJson: blobJson, columnUpdatedAt: now},
        where: '$columnUserId = ?',
        whereArgs: [userId],
      );
    } else {
      // Insert new record
      return await db.insert(tableWalletBlobs, {
        columnUserId: userId,
        columnBlobJson: blobJson,
        columnCreatedAt: now,
        columnUpdatedAt: now,
      });
    }
  }

  /// Get wallet blob by user ID
  static Future<Map<String, dynamic>?> getWalletBlob(String userId) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      tableWalletBlobs,
      where: '$columnUserId = ?',
      whereArgs: [userId],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  /// Delete wallet blob by user ID
  static Future<int> deleteWalletBlob(String userId) async {
    final db = await database;

    return await db.delete(
      tableWalletBlobs,
      where: '$columnUserId = ?',
      whereArgs: [userId],
    );
  }

  /// Get all wallet blobs
  static Future<List<Map<String, dynamic>>> getAllWalletBlobs() async {
    final db = await database;
    return await db.query(tableWalletBlobs);
  }

  /// Check if wallet blob exists for user
  static Future<bool> walletBlobExists(String userId) async {
    final blob = await getWalletBlob(userId);
    return blob != null;
  }

  /// Clear all data from database (for "Forget Me" functionality)
  static Future<void> clearAllData() async {
    final db = await database;

    try {
      // Delete all wallet blobs
      await db.delete('wallet_blobs');
      print('DatabaseService: All wallet data cleared');

      // Note: We don't delete android_metadata as it's system table
    } catch (e) {
      print('DatabaseService: Error clearing data: $e');
      rethrow;
    }
  }

  /// Close database connection
  static Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Delete database (for testing purposes)
  static Future<void> deleteDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
