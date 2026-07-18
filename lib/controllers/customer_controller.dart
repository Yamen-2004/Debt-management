import 'dart:async';

import 'package:get/get.dart';

import '../models/customer_model.dart';
import '../services/backup_service.dart';
import '../services/firestore_service.dart';
import '../utils/text_utils.dart';

class CustomerController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final BackupService _backupService = BackupService();
  StreamSubscription<List<CustomerModel>>? _subscription;
  bool _autoBackupChecked = false;

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
        _checkAutomaticBackup();
      },
      onError: (_) {
        errorMessage.value = 'فشل تحميل العملاء';
        isLoading.value = false;
      },
    );
  }

  /// Silently backs up all customers once per session, if a backup is due.
  /// Runs only after the first successful customer load, so a fresh
  /// session never backs up a still-empty in-memory list. Never blocks or
  /// surfaces errors — see [BackupService.runAutomaticBackupIfDue].
  void _checkAutomaticBackup() {
    if (_autoBackupChecked) return;
    _autoBackupChecked = true;
    _backupService.runAutomaticBackupIfDue(customers);
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

  Future<bool> addCustomer(
    String name, {
    double initialBalance = 0.0,
    String note = '',
  }) async {
    if (name.trim().isEmpty) {
      errorMessage.value = 'لا يمكن أن يكون الاسم فارغاً';
      return false;
    }

    try {
      await _firestoreService.addCustomer(
        name,
        initialBalance: initialBalance,
        note: note,
      );
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

  Future<bool> increaseBalance(
    String customerId,
    double amount, {
    String note = '',
  }) async {
    try {
      await _firestoreService.increaseBalance(customerId, amount, note: note);
      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    }
  }

  Future<bool> decreaseBalance(
    String customerId,
    double amount, {
    String note = '',
  }) async {
    try {
      await _firestoreService.decreaseBalance(customerId, amount, note: note);
      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    }
  }

  Future<bool> deleteHistory(String customerId) async {
    try {
      await _firestoreService.deleteTransactionHistory(customerId);
      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    }
  }
}
