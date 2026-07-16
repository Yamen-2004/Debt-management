import 'dart:async';

import 'package:get/get.dart';

import '../models/customer_model.dart';
import '../services/firestore_service.dart';
import '../utils/text_utils.dart';

class CustomerController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription<List<CustomerModel>>? _subscription;

  final customers = <CustomerModel>[].obs;
  final filteredCustomers = <CustomerModel>[].obs;
  final searchQuery = ''.obs;

  final isLoading = false.obs;
  final errorMessage = RxnString();

  /// Total debt is always calculated dynamically from the customers
  /// list — it is never stored in Firestore, to guarantee consistency.
  double get totalDebt => customers.fold(0.0, (sum, c) => sum + c.balance);

  int get totalCustomers => customers.length;

  @override
  void onInit() {
    super.onInit();
    loadCustomers();
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }

  void loadCustomers() {
    isLoading.value = true;
    _subscription = _firestoreService.getCustomers().listen(
      (data) {
        customers.value = data;
        _applySearch();
        isLoading.value = false;
      },
      onError: (_) {
        errorMessage.value = 'فشل تحميل العملاء';
        isLoading.value = false;
      },
    );
  }

  void search(String query) {
    searchQuery.value = query;
    _applySearch();
  }

  void _applySearch() {
    if (searchQuery.value.trim().isEmpty) {
      filteredCustomers.value = customers;
      return;
    }

    final normalizedQuery = TextUtils.generateSearchName(searchQuery.value);
    filteredCustomers.value = customers
        .where((c) => c.searchName.contains(normalizedQuery))
        .toList();
  }

  Future<bool> addCustomer(String name, {double initialBalance = 0.0}) async {
    if (name.trim().isEmpty) {
      errorMessage.value = 'لا يمكن أن يكون الاسم فارغاً';
      return false;
    }

    try {
      await _firestoreService.addCustomer(name, initialBalance: initialBalance);
      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    }
  }

  Future<bool> renameCustomer(String customerId, String newName) async {
    if (newName.trim().isEmpty) {
      errorMessage.value = 'لا يمكن أن يكون الاسم فارغاً';
      return false;
    }

    try {
      await _firestoreService.updateCustomerName(customerId, newName);
      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    }
  }

  Future<bool> increaseBalance(String customerId, double amount) async {
    try {
      await _firestoreService.increaseBalance(customerId, amount);
      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    }
  }

  Future<bool> decreaseBalance(String customerId, double amount) async {
    try {
      await _firestoreService.decreaseBalance(customerId, amount);
      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    }
  }
}
