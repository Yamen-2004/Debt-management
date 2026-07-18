import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/customer_controller.dart';
import '../../controllers/transaction_controller.dart';
import '../../models/customer_model.dart';
import '../../models/transaction_model.dart';

const _kPrimary = Color(0xFF4F46E5);

class CustomerHistoryScreen extends StatefulWidget {
  final CustomerModel customer;

  const CustomerHistoryScreen({super.key, required this.customer});

  @override
  State<CustomerHistoryScreen> createState() => _CustomerHistoryScreenState();
}

class _CustomerHistoryScreenState extends State<CustomerHistoryScreen> {
  late final TransactionController _transactionController;

  @override
  void initState() {
    super.initState();
    _transactionController = Get.put(
      TransactionController(),
      tag: widget.customer.id,
    );
    _transactionController.loadTransactions(widget.customer.id);
  }

  @override
  void dispose() {
    Get.delete<TransactionController>(tag: widget.customer.id);
    super.dispose();
  }

  String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} - $hour:$minute';
  }

  Future<void> _confirmDeleteHistory(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف السجل'),
        content: const Text(
          'هل أنت متأكد من حذف كل سجل الحركات لهذا العميل؟ لا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('نعم، احذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final customerController = Get.find<CustomerController>();
    final success = await customerController.deleteHistory(widget.customer.id);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'تم حذف سجل الحركات'
              : customerController.errorMessage.value ?? 'حدث خطأ',
        ),
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction) {
    final isIncrease = transaction.isIncrease;
    final color = isIncrease ? Colors.redAccent : Colors.green;

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(
            isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
            color: color,
          ),
        ),
        title: Text(
          '${transaction.amount.toStringAsFixed(2)} د.أ',
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        subtitle: Text(
          transaction.note.trim().isEmpty
              ? _formatDateTime(transaction.createdAt)
              : '${transaction.note}\n${_formatDateTime(transaction.createdAt)}',
        ),
        isThreeLine: transaction.note.trim().isNotEmpty,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: Text(
          widget.customer.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'حذف السجل',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDeleteHistory(context),
          ),
        ],
      ),
      body: Obx(() {
        if (_transactionController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final transactions = _transactionController.transactions;

        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 56, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'لا يوجد حركات',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: transactions.length,
          itemBuilder: (context, index) =>
              _buildTransactionCard(transactions[index]),
        );
      }),
    );
  }
}
