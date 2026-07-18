import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/customer_controller.dart';

class AddCustomerDialog extends StatelessWidget {
  const AddCustomerDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const AddCustomerDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final controller = Get.find<CustomerController>();

    return AlertDialog(
      title: const Text('إضافة عميل'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'اسم العميل'),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'مبلغ الدين الابتدائي (اختياري)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: noteController,
            decoration: const InputDecoration(labelText: 'ملاحظة (اختياري)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () async {
            final initialBalance =
                double.tryParse(amountController.text.trim()) ?? 0.0;
            final success = await controller.addCustomer(
              nameController.text,
              initialBalance: initialBalance,
              note: noteController.text,
            );
            if (context.mounted) {
              Navigator.pop(context);
              if (!success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text(controller.errorMessage.value ?? 'حدث خطأ')),
                );
              }
            }
          },
          child: const Text('إضافة'),
        ),
      ],
    );
  }
}
