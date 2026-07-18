import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/customer_controller.dart';
import '../models/customer_model.dart';
import '../screens/history/customer_history_screen.dart';

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
    final noteController = TextEditingController();
    final controller = Get.find<CustomerController>();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'المبلغ (د.أ)'),
              autofocus: true,
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text.trim());
              if (amount == null || amount <= 0) {
                controller.errorMessage.value = 'أدخل مبلغاً صحيحاً';
                return;
              }

              final note = noteController.text;
              final success = isIncrease
                  ? await controller.increaseBalance(customer.id, amount,
                      note: note)
                  : await controller.decreaseBalance(customer.id, amount,
                      note: note);

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                if (!success) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                        content: Text(
                            controller.errorMessage.value ?? 'حدث خطأ')),
                  );
                }
              }
            },
            child: const Text('تأكيد'),
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
        title: const Text('تعديل الاسم'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'اسم العميل'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
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
                        content: Text(
                            controller.errorMessage.value ?? 'حدث خطأ')),
                  );
                }
              }
            },
            child: const Text('حفظ'),
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
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Text(
              customer.name,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${customer.balance.toStringAsFixed(2)} د.أ',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: customer.balance > 0 ? Colors.redAccent : Colors.green,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            ListTile(
              leading:
                  const Icon(Icons.add_circle_outline, color: Colors.redAccent),
              title: const Text('زيادة الدين'),
              onTap: () {
                Navigator.pop(context);
                _showAmountDialog(context,
                    title: 'زيادة الدين', isIncrease: true);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.remove_circle_outline, color: Colors.green),
              title: const Text('إنقاص الدين'),
              onTap: () {
                Navigator.pop(context);
                _showAmountDialog(context,
                    title: 'إنقاص الدين', isIncrease: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Colors.indigo),
              title: const Text('تعديل الاسم'),
              onTap: () {
                Navigator.pop(context);
                _showEditNameDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined,
                  color: Colors.indigo),
              title: const Text('سجل الحركات'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomerHistoryScreen(customer: customer),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
