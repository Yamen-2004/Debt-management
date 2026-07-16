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
    final controller = Get.find<CustomerController>();

    return AlertDialog(
      title: const Text('Add Customer'),
      content: TextField(
        controller: nameController,
        decoration: const InputDecoration(labelText: 'Customer Name'),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final success = await controller.addCustomer(nameController.text);
            if (context.mounted) {
              Navigator.pop(context);
              if (!success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(controller.errorMessage.value ?? 'Error')),
                );
              }
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
