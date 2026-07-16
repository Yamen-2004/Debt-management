import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/customer_controller.dart';
import '../models/customer_model.dart';

class CustomerBottomSheet extends StatelessWidget {
  final CustomerModel customer;

  const CustomerBottomSheet({super.key, required this.customer});

  static void show(BuildContext context, CustomerModel customer) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => CustomerBottomSheet(customer: customer),
    );
  }

  Future<void> _showAmountDialog(
    BuildContext context, {
    required String title,
    required bool isIncrease,
  }) async {
    final amountController = TextEditingController();
    final controller = Get.find<CustomerController>();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Amount (JD)'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text.trim());
              if (amount == null || amount <= 0) {
                controller.errorMessage.value = 'Enter a valid amount';
                return;
              }

              final success = isIncrease
                  ? await controller.increaseBalance(customer.id, amount)
                  : await controller.decreaseBalance(customer.id, amount);

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                if (!success) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                        content:
                            Text(controller.errorMessage.value ?? 'Error')),
                  );
                }
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditNameDialog(BuildContext context) async {
    final nameController = TextEditingController(text: customer.name);
    final controller = Get.find<CustomerController>();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Customer Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await controller.renameCustomer(
                customer.id,
                nameController.text,
              );

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                if (!success) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                        content:
                            Text(controller.errorMessage.value ?? 'Error')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              customer.name,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading:
                  const Icon(Icons.add_circle_outline, color: Colors.redAccent),
              title: const Text('Increase Debt'),
              onTap: () {
                Navigator.pop(context);
                _showAmountDialog(context,
                    title: 'Increase Debt', isIncrease: true);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.remove_circle_outline, color: Colors.green),
              title: const Text('Decrease Debt'),
              onTap: () {
                Navigator.pop(context);
                _showAmountDialog(context,
                    title: 'Decrease Debt', isIncrease: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Name'),
              onTap: () {
                Navigator.pop(context);
                _showEditNameDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
