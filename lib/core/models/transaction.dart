import 'package:equatable/equatable.dart';

enum TransactionStatus {
  pending,
  confirmed,
  failed,
}

enum TransactionType {
  send,
  receive,
  contractInteraction,
}

class Transaction extends Equatable {
  final String hash;
  final String from;
  final String to;
  final BigInt value;
  final BigInt gasPrice;
  final BigInt gasLimit;
  final BigInt? gasUsed;
  final String? data;
  final int nonce;
  final TransactionStatus status;
  final TransactionType type;
  final DateTime timestamp;
  final int? blockNumber;
  final String? tokenSymbol;
  final String? tokenAddress;
  final int? tokenDecimals;

  const Transaction({
    required this.hash,
    required this.from,
    required this.to,
    required this.value,
    required this.gasPrice,
    required this.gasLimit,
    this.gasUsed,
    this.data,
    required this.nonce,
    required this.status,
    required this.type,
    required this.timestamp,
    this.blockNumber,
    this.tokenSymbol,
    this.tokenAddress,
    this.tokenDecimals,
  });

  bool get isTokenTransfer => tokenAddress != null;

  String get formattedValue {
    final decimals = tokenDecimals ?? 18;
    final divisor = BigInt.from(10).pow(decimals);
    final wholePart = value ~/ divisor;
    final fractionalPart = value % divisor;
    
    if (fractionalPart == BigInt.zero) {
      return wholePart.toString();
    }
    
    final fractionalStr = fractionalPart.toString().padLeft(decimals, '0');
    final trimmedFractional = fractionalStr.replaceAll(RegExp(r'0+$'), '');
    
    if (trimmedFractional.isEmpty) {
      return wholePart.toString();
    }
    
    return '$wholePart.$trimmedFractional';
  }

  String get displaySymbol => tokenSymbol ?? 'ETH';

  Map<String, dynamic> toJson() {
    return {
      'hash': hash,
      'from': from,
      'to': to,
      'value': value.toString(),
      'gasPrice': gasPrice.toString(),
      'gasLimit': gasLimit.toString(),
      'gasUsed': gasUsed?.toString(),
      'data': data,
      'nonce': nonce,
      'status': status.name,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'blockNumber': blockNumber,
      'tokenSymbol': tokenSymbol,
      'tokenAddress': tokenAddress,
      'tokenDecimals': tokenDecimals,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      hash: json['hash'] as String,
      from: json['from'] as String,
      to: json['to'] as String,
      value: BigInt.parse(json['value'] as String),
      gasPrice: BigInt.parse(json['gasPrice'] as String),
      gasLimit: BigInt.parse(json['gasLimit'] as String),
      gasUsed: json['gasUsed'] != null ? BigInt.parse(json['gasUsed'] as String) : null,
      data: json['data'] as String?,
      nonce: json['nonce'] as int,
      status: TransactionStatus.values.firstWhere((e) => e.name == json['status']),
      type: TransactionType.values.firstWhere((e) => e.name == json['type']),
      timestamp: DateTime.parse(json['timestamp'] as String),
      blockNumber: json['blockNumber'] as int?,
      tokenSymbol: json['tokenSymbol'] as String?,
      tokenAddress: json['tokenAddress'] as String?,
      tokenDecimals: json['tokenDecimals'] as int?,
    );
  }

  @override
  List<Object?> get props => [
        hash,
        from,
        to,
        value,
        gasPrice,
        gasLimit,
        gasUsed,
        data,
        nonce,
        status,
        type,
        timestamp,
        blockNumber,
        tokenSymbol,
        tokenAddress,
        tokenDecimals,
      ];
}
