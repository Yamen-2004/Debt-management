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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('Last Update: ${_formatDate(customer.updatedAt)}'),
        trailing: Text(
          '${customer.balance.toStringAsFixed(2)} JD',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: customer.balance > 0 ? Colors.redAccent : Colors.green,
          ),
        ),
      ),
    );
  }
}
