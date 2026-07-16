import 'package:flutter/material.dart';

import '../models/customer_model.dart';

class CustomerCard extends StatelessWidget {
  final CustomerModel customer;
  final VoidCallback onTap;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.onTap,
  });

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final hasDebt = customer.balance > 0;

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor:
              (hasDebt ? Colors.redAccent : Colors.green).withOpacity(0.12),
          child: Text(
            customer.name.isNotEmpty ? customer.name.substring(0, 1) : '؟',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: hasDebt ? Colors.redAccent : Colors.green,
            ),
          ),
        ),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('آخر تحديث: ${_formatDate(customer.updatedAt)}'),
        trailing: Text(
          '${customer.balance.toStringAsFixed(2)} د.أ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: hasDebt ? Colors.redAccent : Colors.green,
          ),
        ),
      ),
    );
  }
}
