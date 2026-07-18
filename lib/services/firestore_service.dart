import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/customer_model.dart';
import '../models/transaction_model.dart';
import '../utils/text_utils.dart';

/// Handles all communication with Cloud Firestore.
/// Contains no UI code — only data access logic.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _customersRef =>
      _db.collection('shops').doc(_uid).collection('customers');

  CollectionReference<Map<String, dynamic>> _transactionsRef(
          String customerId) =>
      _customersRef.doc(customerId).collection('transactions');

  /// Creates the shop document if it doesn't already exist.
  /// The shop document id always equals the Firebase Auth uid.
  Future<void> createShopIfNotExists({
    required String shopName,
    required String ownerName,
  }) async {
    final shopDoc = _db.collection('shops').doc(_uid);
    final snapshot = await shopDoc.get();

    if (!snapshot.exists) {
      await shopDoc.set({
        'shopName': shopName,
        'ownerName': ownerName,
        'createdAt': Timestamp.now(),
      });
    }
  }

  /// Checks whether a customer with the same normalized name already
  /// exists in this shop. [excludeId] is used when renaming, so the
  /// customer being renamed doesn't collide with itself.
  Future<bool> customerExists(String name, {String? excludeId}) async {
    final searchName = TextUtils.generateSearchName(name);

    final query =
        await _customersRef.where('searchName', isEqualTo: searchName).get();

    if (excludeId == null) {
      return query.docs.isNotEmpty;
    }

    return query.docs.any((doc) => doc.id != excludeId);
  }

  /// Realtime stream of all customers, sorted alphabetically by searchName.
  Stream<List<CustomerModel>> getCustomers() {
    return _customersRef.orderBy('searchName').snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => CustomerModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Adds a new customer with balance starting at [initialBalance] (default 0).
  /// If [initialBalance] is greater than zero, an initial 'increase'
  /// transaction is recorded in the same batch. Throws if a customer with
  /// the same name already exists, or if [initialBalance] is negative.
  Future<void> addCustomer(
    String name, {
    double initialBalance = 0.0,
    String note = '',
  }) async {
    if (initialBalance < 0) {
      throw Exception('لا يمكن أن يكون المبلغ سالباً');
    }

    final exists = await customerExists(name);
    if (exists) {
      throw Exception('يوجد عميل بهذا الاسم مسبقاً');
    }

    final now = DateTime.now();
    final customerDoc = _customersRef.doc();
    final batch = _db.batch();

    batch.set(customerDoc, {
      'name': name.trim(),
      'searchName': TextUtils.generateSearchName(name),
      'balance': initialBalance,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });

    if (initialBalance > 0) {
      final transactionDoc = _transactionsRef(customerDoc.id).doc();
      batch.set(transactionDoc, {
        'type': 'increase',
        'amount': initialBalance,
        'note': note.trim(),
        'createdAt': Timestamp.fromDate(now),
      });
    }

    await batch.commit();
  }

  /// Renames a customer, regenerating their searchName.
  /// Throws if another customer already has that name.
  Future<void> updateCustomerName(String customerId, String newName) async {
    final exists = await customerExists(newName, excludeId: customerId);
    if (exists) {
      throw Exception('يوجد عميل بهذا الاسم مسبقاً');
    }

    await _customersRef.doc(customerId).update({
      'name': newName.trim(),
      'searchName': TextUtils.generateSearchName(newName),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Increases a customer's balance by [amount], recording an 'increase'
  /// transaction in the same Firestore transaction.
  Future<void> increaseBalance(
    String customerId,
    double amount, {
    String note = '',
  }) async {
    if (amount <= 0) {
      throw Exception('يجب أن يكون المبلغ أكبر من صفر');
    }

    final docRef = _customersRef.doc(customerId);
    final transactionDoc = _transactionsRef(customerId).doc();

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final currentBalance = (snapshot.data()?['balance'] as num?) ?? 0;

      transaction.update(docRef, {
        'balance': currentBalance.toDouble() + amount,
        'updatedAt': Timestamp.now(),
      });

      transaction.set(transactionDoc, {
        'type': 'increase',
        'amount': amount,
        'note': note.trim(),
        'createdAt': Timestamp.now(),
      });
    });
  }

  /// Decreases a customer's balance by [amount], recording a 'decrease'
  /// transaction in the same Firestore transaction.
  /// Throws if the result would go below zero.
  Future<void> decreaseBalance(
    String customerId,
    double amount, {
    String note = '',
  }) async {
    if (amount <= 0) {
      throw Exception('يجب أن يكون المبلغ أكبر من صفر');
    }

    final docRef = _customersRef.doc(customerId);
    final transactionDoc = _transactionsRef(customerId).doc();

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final currentBalance =
          ((snapshot.data()?['balance'] as num?) ?? 0).toDouble();

      if (amount > currentBalance) {
        throw Exception('لا يمكن أن يصبح الرصيد سالباً');
      }

      transaction.update(docRef, {
        'balance': currentBalance - amount,
        'updatedAt': Timestamp.now(),
      });

      transaction.set(transactionDoc, {
        'type': 'decrease',
        'amount': amount,
        'note': note.trim(),
        'createdAt': Timestamp.now(),
      });
    });
  }

  /// Realtime stream of a customer's transactions, newest first.
  Stream<List<TransactionModel>> getTransactions(String customerId) {
    return _transactionsRef(customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Deletes all transaction history for a customer, in batches of at most
  /// 500 documents (Firestore's per-batch write limit). Does not touch the
  /// customer's balance field.
  Future<void> deleteTransactionHistory(String customerId) async {
    final docs = await _transactionsRef(customerId).get();

    const chunkSize = 500;
    for (var i = 0; i < docs.docs.length; i += chunkSize) {
      final chunk = docs.docs.skip(i).take(chunkSize);
      final batch = _db.batch();
      for (final doc in chunk) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}
