import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/customer_controller.dart';
import '../../widgets/add_customer_dialog.dart';
import '../../widgets/customer_bottom_sheet.dart';
import '../../widgets/customer_card.dart';
import '../../widgets/summary_card.dart';
import '../login/login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final customerController = Get.put(CustomerController());
    final authController = Get.put(AuthController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('DebtBook'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authController.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Total Customers / Total Debt summary cards.
          // Total Debt is always derived from the customers list,
          // never stored in Firestore, to guarantee consistency.
          Padding(
            padding: const EdgeInsets.all(12),
            child: Obx(() => Row(
                  children: [
                    SummaryCard(
                      title: 'Total Customers',
                      value: '${customerController.totalCustomers} Customers',
                      icon: Icons.people_outline,
                      color: Colors.indigo,
                    ),
                    const SizedBox(width: 12),
                    SummaryCard(
                      title: 'Total Debt',
                      value:
                          '${customerController.totalDebt.toStringAsFixed(2)} JD',
                      icon: Icons.account_balance_wallet_outlined,
                      color: Colors.redAccent,
                    ),
                  ],
                )),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              onChanged: customerController.search,
              decoration: InputDecoration(
                hintText: 'Search customer...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
                return const Center(child: Text('No customers found'));
              }

              return ListView.builder(
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddCustomerDialog.show(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
