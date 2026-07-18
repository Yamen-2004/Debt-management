import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/customer_controller.dart';
import '../../services/backup_service.dart';
import '../../widgets/add_customer_dialog.dart';
import '../../widgets/customer_bottom_sheet.dart';
import '../../widgets/customer_card.dart';
import '../../widgets/summary_card.dart';

const _kPrimary = Color(0xFF4F46E5);

Future<void> _handleManualBackup(
  BuildContext context,
  CustomerController customerController,
) async {
  try {
    final file =
        await BackupService().runManualBackup(customerController.customers);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إنشاء نسخة احتياطية بنجاح')),
    );

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'نسخة احتياطية من دفتر الديون',
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('فشل إنشاء النسخة الاحتياطية')),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final customerController = Get.put(CustomerController());
    final authController = Get.put(AuthController());

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
        ),
        title: const Text(
          'دفتر الديون',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'نسخة احتياطية',
            icon: const Icon(Icons.backup_outlined),
            onPressed: () => _handleManualBackup(context, customerController),
          ),
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authController.logout();
              // إزالة الـ CustomerController المسجّل حتى يُنشأ من جديد
              // ويشترك من جديد في Firestore عند تسجيل الدخول التالي،
              // بدل إعادة استخدام مستمع قديم مرتبط بحساب سابق.
              Get.delete<CustomerController>();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // بطاقتا "عدد العملاء" و"إجمالي الديون".
          // إجمالي الديون يُحسب دائماً من قائمة العملاء مباشرة،
          // ولا يُخزَّن في Firestore، لضمان دقة البيانات دائماً.
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
            child: Obx(() => Row(
                  children: [
                    SummaryCard(
                      title: 'عدد العملاء',
                      value: '${customerController.totalCustomers} عميل',
                      icon: Icons.people_alt_rounded,
                      color: _kPrimary,
                    ),
                    const SizedBox(width: 12),
                    SummaryCard(
                      title: 'إجمالي الديون',
                      value:
                          '${customerController.totalDebt.toStringAsFixed(2)} د.أ',
                      icon: Icons.account_balance_wallet_rounded,
                      color: Colors.redAccent,
                    ),
                  ],
                )),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              onChanged: customerController.search,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: 'ابحث عن عميل...',
                filled: true,
                fillColor: _kPrimary.withOpacity(0.1),
                prefixIcon: const Icon(Icons.search, color: _kPrimary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _kPrimary, width: 1.4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Obx(() {
              if (customerController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (customerController.filteredCustomers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline,
                          size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'لا يوجد عملاء',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 90),
                itemCount: customerController.filteredCustomers.length,
                itemBuilder: (context, index) {
                  final customer =
                      customerController.filteredCustomers[index];
                  return CustomerCard(
                    customer: customer,
                    onTap: () => CustomerBottomSheet.show(context, customer),
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddCustomerDialog.show(context),
        backgroundColor: _kPrimary,
        icon: const Icon(Icons.add , color: Colors.white),
        label: const Text('عميل جديد' , style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}
