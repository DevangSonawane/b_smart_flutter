import '../models/wallet_model.dart';
import 'ledger_service.dart';
import '../models/ledger_model.dart';

class WalletService {
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;

  final LedgerService _ledgerService = LedgerService();
  AccountDetails? _accountDetails;
  final String _currentUserId = 'user-1'; // In real app, get from auth

  WalletService._internal();

  // Convert ledger transaction to wallet transaction for UI
  CoinTransaction _ledgerToWalletTransaction(LedgerTransaction ledger) {
    TransactionType type;
    switch (ledger.type) {
      case LedgerTransactionType.adReward:
        type = TransactionType.adReward;
        break;
      case LedgerTransactionType.giftReceived:
        type = TransactionType.giftReceived;
        break;
      case LedgerTransactionType.giftSent:
        type = TransactionType.giftSent;
        break;
      default:
        type = TransactionType.adReward;
    }

    TransactionStatus status;
    switch (ledger.status) {
      case LedgerTransactionStatus.completed:
        status = TransactionStatus.completed;
        break;
      case LedgerTransactionStatus.pending:
        status = TransactionStatus.pending;
        break;
      case LedgerTransactionStatus.failed:
      case LedgerTransactionStatus.blocked:
        status = TransactionStatus.failed;
        break;
    }

    return CoinTransaction(
      id: ledger.id,
      type: type,
      amount: ledger.amount,
      timestamp: ledger.timestamp,
      status: status,
      description: ledger.description,
      relatedUserId: ledger.relatedId,
    );
  }

  // Get current coin balance (calculated from ledger - NEVER stored directly)
  int getCoinBalance() {
    return _ledgerService.calculateBalance(_currentUserId);
  }

  // Get equivalent value (assuming 1 coin = $0.01 or similar)
  double getEquivalentValue() {
    return getCoinBalance() * 0.01;
  }

  // Get all transactions (latest first) - converted from ledger
  List<CoinTransaction> getTransactions() {
    final ledgerTransactions = _ledgerService.getUserTransactions(_currentUserId);
    return ledgerTransactions.map(_ledgerToWalletTransaction).toList();
  }

  // Get filtered transactions - converted from ledger
  List<CoinTransaction> getFilteredTransactions({
    TransactionType? type,
    TransactionStatus? status,
  }) {
    LedgerTransactionType? ledgerType;
    if (type != null) {
      switch (type) {
        case TransactionType.adReward:
          ledgerType = LedgerTransactionType.adReward;
          break;
        case TransactionType.giftReceived:
          ledgerType = LedgerTransactionType.giftReceived;
          break;
        case TransactionType.giftSent:
          ledgerType = LedgerTransactionType.giftSent;
          break;
      }
    }

    LedgerTransactionStatus? ledgerStatus;
    if (status != null) {
      switch (status) {
        case TransactionStatus.completed:
          ledgerStatus = LedgerTransactionStatus.completed;
          break;
        case TransactionStatus.pending:
          ledgerStatus = LedgerTransactionStatus.pending;
          break;
        case TransactionStatus.failed:
          ledgerStatus = LedgerTransactionStatus.failed;
          break;
      }
    }

    final ledgerTransactions = _ledgerService.getFilteredTransactions(
      userId: _currentUserId,
      type: ledgerType,
      status: ledgerStatus,
    );
    return ledgerTransactions.map(_ledgerToWalletTransaction).toList();
  }

  // Add coins via ledger (for ad rewards) - CRITICAL: Uses ledger, never direct balance update
  Future<bool> addCoinsViaLedger({
    required int amount,
    required String description,
    required String adId,
    Map<String, dynamic>? metadata,
  }) async {
    if (amount <= 0) return false;
    
    // Create ledger transaction
    final ledgerTransaction = _ledgerService.addTransaction(
      userId: _currentUserId,
      type: LedgerTransactionType.adReward,
      amount: amount,
      description: description,
      relatedId: adId,
      metadata: metadata,
    );
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Mark as completed (in real app, this would be after server confirmation)
    _ledgerService.updateTransactionStatus(
      ledgerTransaction.id,
      LedgerTransactionStatus.completed,
    );
    
    return true;
  }

  // Send gift coins via ledger
  Future<bool> sendGiftCoins(int amount, String receiverUserId, String receiverName) async {
    if (amount <= 0) return false;
    if (getCoinBalance() < amount) return false; // Insufficient balance
    
    // Create ledger transaction
    final ledgerTransaction = _ledgerService.addTransaction(
      userId: _currentUserId,
      type: LedgerTransactionType.giftSent,
      amount: -amount,
      description: 'Gift to $receiverName',
      relatedId: receiverUserId,
    );
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Mark as completed
    _ledgerService.updateTransactionStatus(
      ledgerTransaction.id,
      LedgerTransactionStatus.completed,
    );
    
    return true;
  }

  // Receive gift coins via ledger
  Future<bool> receiveGiftCoins(int amount, String senderUserId, String senderName) async {
    if (amount <= 0) return false;
    
    // Create ledger transaction
    final ledgerTransaction = _ledgerService.addTransaction(
      userId: _currentUserId,
      type: LedgerTransactionType.giftReceived,
      amount: amount,
      description: 'Gift from $senderName',
      relatedId: senderUserId,
    );
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Mark as completed
    _ledgerService.updateTransactionStatus(
      ledgerTransaction.id,
      LedgerTransactionStatus.completed,
    );
    
    return true;
  }

  // Get account details
  AccountDetails? getAccountDetails() {
    return _accountDetails;
  }

  // Save account details
  Future<bool> saveAccountDetails(AccountDetails details) async {
    // Simulate validation
    if (details.accountHolderName.isEmpty ||
        details.paymentMethod.isEmpty ||
        details.accountNumber.isEmpty) {
      return false;
    }
    
    if (_accountDetails == null) {
      _accountDetails = details;
    } else {
      _accountDetails = details.copyWith(
        id: _accountDetails!.id,
        createdAt: _accountDetails!.createdAt,
        updatedAt: DateTime.now(),
      );
    }
    return true;
  }

  // Delete account details
  void deleteAccountDetails() {
    _accountDetails = null;
  }

  // Check if user has sufficient balance (calculated from ledger)
  bool hasSufficientBalance(int amount) {
    return getCoinBalance() >= amount;
  }
}
