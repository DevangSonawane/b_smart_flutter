enum TransactionType {
  adReward,
  giftReceived,
  giftSent,
}

enum TransactionStatus {
  completed,
  pending,
  failed,
}

class CoinTransaction {
  final String id;
  final TransactionType type;
  final int amount; // Positive for earned/received, negative for sent
  final DateTime timestamp;
  final TransactionStatus status;
  final String? description;
  final String? relatedUserId; // For gift transactions

  CoinTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.timestamp,
    this.status = TransactionStatus.completed,
    this.description,
    this.relatedUserId,
  });
}

class AccountDetails {
  final String id;
  final String accountHolderName;
  final String paymentMethod; // 'Bank', 'UPI', 'PayPal', etc.
  final String accountNumber; // Account number or UPI ID
  final String? bankName;
  final String? ifscCode;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AccountDetails({
    required this.id,
    required this.accountHolderName,
    required this.paymentMethod,
    required this.accountNumber,
    this.bankName,
    this.ifscCode,
    required this.createdAt,
    this.updatedAt,
  });

  AccountDetails copyWith({
    String? id,
    String? accountHolderName,
    String? paymentMethod,
    String? accountNumber,
    String? bankName,
    String? ifscCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AccountDetails(
      id: id ?? this.id,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      accountNumber: accountNumber ?? this.accountNumber,
      bankName: bankName ?? this.bankName,
      ifscCode: ifscCode ?? this.ifscCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
