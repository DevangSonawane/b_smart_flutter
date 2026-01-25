import 'package:flutter/material.dart';
import '../services/wallet_service.dart';
import '../models/wallet_model.dart';

class CoinsHistoryScreen extends StatefulWidget {
  const CoinsHistoryScreen({super.key});

  @override
  State<CoinsHistoryScreen> createState() => _CoinsHistoryScreenState();
}

class _CoinsHistoryScreenState extends State<CoinsHistoryScreen> {
  final WalletService _walletService = WalletService();
  List<CoinTransaction> _transactions = [];
  TransactionType? _selectedType;
  TransactionStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _loadTransactions() {
    setState(() {
      if (_selectedType != null || _selectedStatus != null) {
        _transactions = _walletService.getFilteredTransactions(
          type: _selectedType,
          status: _selectedStatus,
        );
      } else {
        _transactions = _walletService.getTransactions();
      }
    });
  }

  IconData _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.adReward:
        return Icons.play_circle_outline;
      case TransactionType.giftReceived:
        return Icons.card_giftcard;
      case TransactionType.giftSent:
        return Icons.send;
    }
  }

  Color _getTransactionColor(TransactionType type) {
    switch (type) {
      case TransactionType.adReward:
        return Colors.blue;
      case TransactionType.giftReceived:
        return Colors.green;
      case TransactionType.giftSent:
        return Colors.pink;
    }
  }

  String _getTransactionTypeLabel(TransactionType type) {
    switch (type) {
      case TransactionType.adReward:
        return 'Ad Reward';
      case TransactionType.giftReceived:
        return 'Gift Received';
      case TransactionType.giftSent:
        return 'Gift Sent';
    }
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.failed:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coins History'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildFilterChip(
                      'All Types',
                      _selectedType == null,
                      () {
                        setState(() {
                          _selectedType = null;
                          _loadTransactions();
                        });
                      },
                    ),
                    _buildFilterChip(
                      'Ad Rewards',
                      _selectedType == TransactionType.adReward,
                      () {
                        setState(() {
                          _selectedType = TransactionType.adReward;
                          _loadTransactions();
                        });
                      },
                    ),
                    _buildFilterChip(
                      'Gifts',
                      _selectedType == TransactionType.giftReceived ||
                          _selectedType == TransactionType.giftSent,
                      () {
                        setState(() {
                          _selectedType = null; // Show both gift types
                          _loadTransactions();
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Transactions List
          Expanded(
            child: _transactions.isEmpty
                ? const Center(
                    child: Text('No transactions found'),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      _loadTransactions();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = _transactions[index];
                        final isPositive = transaction.amount > 0;
                        final iconColor = _getTransactionColor(transaction.type);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: iconColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getTransactionIcon(transaction.type),
                                color: iconColor,
                              ),
                            ),
                            title: Text(
                              _getTransactionTypeLabel(transaction.type),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (transaction.description != null)
                                  Text(transaction.description!),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                          transaction.status,
                                        ).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        transaction.status.name.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: _getStatusColor(
                                            transaction.status,
                                          ),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatDate(transaction.timestamp),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Text(
                              '${isPositive ? '+' : ''}${transaction.amount}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isPositive ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: Colors.amber,
      checkmarkColor: Colors.white,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
