import 'dart:convert';

class WalletBlob {
  final String userId;
  final String blobJson;
  final DateTime createdAt;
  final DateTime updatedAt;

  WalletBlob({
    required this.userId,
    required this.blobJson,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create WalletBlob from database map
  factory WalletBlob.fromMap(Map<String, dynamic> map) {
    return WalletBlob(
      userId: map['user_id'] as String,
      blobJson: map['blob_json'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  /// Convert WalletBlob to database map
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'blob_json': blobJson,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Parse blob JSON to Map
  Map<String, dynamic> get blobData {
    try {
      return json.decode(blobJson) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('Invalid JSON in blob_json: $e');
    }
  }

  /// Create WalletBlob with blob data as Map
  factory WalletBlob.withBlobData({
    required String userId,
    required Map<String, dynamic> blobData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return WalletBlob(
      userId: userId,
      blobJson: json.encode(blobData),
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  /// Copy with updated fields
  WalletBlob copyWith({
    String? userId,
    String? blobJson,
    Map<String, dynamic>? blobData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WalletBlob(
      userId: userId ?? this.userId,
      blobJson: blobData != null ? json.encode(blobData) : (blobJson ?? this.blobJson),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'WalletBlob(userId: $userId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WalletBlob &&
        other.userId == userId &&
        other.blobJson == blobJson &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        blobJson.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
