import 'dart:async';

import 'package:get/get.dart';

import '../models/transaction_model.dart';
import '../services/firestore_service.dart';

class TransactionController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription<List<TransactionModel>>? _subscription;

  final transactions = <TransactionModel>[].obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }

  void loadTransactions(String customerId) {
    isLoading.value = true;
    _subscription?.cancel();
    _subscription = _firestoreService.getTransactions(customerId).listen(
      (data) {
        transactions.value = data;
        isLoading.value = false;
      },
      onError: (_) {
        errorMessage.value = 'فشل تحميل سجل الحركات';
        isLoading.value = false;
      },
    );
  }
}
