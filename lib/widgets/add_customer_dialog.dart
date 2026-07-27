import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final isSubmitting = false.obs;

    Future<void> handleAdd() async {
      if (isSubmitting.value) return;

      final amountText = amountController.text.trim();
      double initialBalance = 0.0;
      if (amountText.isNotEmpty) {
        final parsed = double.tryParse(amountText);
        if (parsed == null || parsed < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('الرجاء إدخال مبلغ دين ابتدائي صحيح'),
            ),
          );
          return;
        }
        initialBalance = parsed;
      }

      isSubmitting.value = true;

      final success = await controller.addCustomer(
        nameController.text,
        initialBalance: initialBalance,
        note: noteController.text,
      );

      isSubmitting.value = false;
      if (!context.mounted) return;

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة العميل بنجاح')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(controller.errorMessage.value ?? 'حدث خطأ')),
        );
      }
    }

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
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
            ],
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
        Obx(() => ElevatedButton(
              onPressed: isSubmitting.value ? null : handleAdd,
              child: isSubmitting.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('إضافة'),
            )),
      ],
    );
  }
}
