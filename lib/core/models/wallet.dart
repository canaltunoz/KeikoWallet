import 'package:equatable/equatable.dart';

class Wallet extends Equatable {
  final String address;
  final String publicKey;
  final String? name;
  final DateTime createdAt;
  final bool isImported;

  const Wallet({
    required this.address,
    required this.publicKey,
    this.name,
    required this.createdAt,
    this.isImported = false,
  });

  Wallet copyWith({
    String? address,
    String? publicKey,
    String? name,
    DateTime? createdAt,
    bool? isImported,
  }) {
    return Wallet(
      address: address ?? this.address,
      publicKey: publicKey ?? this.publicKey,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      isImported: isImported ?? this.isImported,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'publicKey': publicKey,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'isImported': isImported,
    };
  }

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      address: json['address'] as String,
      publicKey: json['publicKey'] as String,
      name: json['name'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isImported: json['isImported'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [address, publicKey, name, createdAt, isImported];
}

class Token extends Equatable {
  final String symbol;
  final String name;
  final String? contractAddress;
  final int decimals;
  final String? logoUrl;
  final bool isNative;
  final int chainId;

  const Token({
    required this.symbol,
    required this.name,
    this.contractAddress,
    required this.decimals,
    this.logoUrl,
    this.isNative = false,
    required this.chainId,
  });

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'contractAddress': contractAddress,
      'decimals': decimals,
      'logoUrl': logoUrl,
      'isNative': isNative,
      'chainId': chainId,
    };
  }

  factory Token.fromJson(Map<String, dynamic> json) {
    return Token(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      contractAddress: json['contractAddress'] as String?,
      decimals: json['decimals'] as int,
      logoUrl: json['logoUrl'] as String?,
      isNative: json['isNative'] as bool? ?? false,
      chainId: json['chainId'] as int,
    );
  }

  @override
  List<Object?> get props => [symbol, name, contractAddress, decimals, logoUrl, isNative, chainId];
}

class TokenBalance extends Equatable {
  final Token token;
  final BigInt balance;
  final double? usdValue;

  const TokenBalance({
    required this.token,
    required this.balance,
    this.usdValue,
  });

  String get formattedBalance {
    final divisor = BigInt.from(10).pow(token.decimals);
    final wholePart = balance ~/ divisor;
    final fractionalPart = balance % divisor;
    
    if (fractionalPart == BigInt.zero) {
      return wholePart.toString();
    }
    
    final fractionalStr = fractionalPart.toString().padLeft(token.decimals, '0');
    final trimmedFractional = fractionalStr.replaceAll(RegExp(r'0+$'), '');
    
    if (trimmedFractional.isEmpty) {
      return wholePart.toString();
    }
    
    return '$wholePart.$trimmedFractional';
  }

  @override
  List<Object?> get props => [token, balance, usdValue];
}
