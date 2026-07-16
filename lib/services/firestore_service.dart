import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/customer_model.dart';
import '../utils/text_utils.dart';

/// Handles all communication with Cloud Firestore.
/// Contains no UI code — only data access logic.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _customersRef =>
      _db.collection('shops').doc(_uid).collection('customers');

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
  /// Throws if a customer with the same name already exists, or if
  /// [initialBalance] is negative.
  Future<void> addCustomer(String name, {double initialBalance = 0.0}) async {
    if (initialBalance < 0) {
      throw Exception('لا يمكن أن يكون المبلغ سالباً');
    }

    final exists = await customerExists(name);
    if (exists) {
      throw Exception('يوجد عميل بهذا الاسم مسبقاً');
    }

    final now = DateTime.now();

    await _customersRef.add({
      'name': name.trim(),
      'searchName': TextUtils.generateSearchName(name),
      'balance': initialBalance,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });
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

  /// Increases a customer's balance by [amount].
  Future<void> increaseBalance(String customerId, double amount) async {
    if (amount <= 0) {
      throw Exception('يجب أن يكون المبلغ أكبر من صفر');
    }

    final docRef = _customersRef.doc(customerId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final currentBalance = (snapshot.data()?['balance'] as num?) ?? 0;

      transaction.update(docRef, {
        'balance': currentBalance.toDouble() + amount,
        'updatedAt': Timestamp.now(),
      });
    });
  }

  /// Decreases a customer's balance by [amount].
  /// Throws if the result would go below zero.
  Future<void> decreaseBalance(String customerId, double amount) async {
    if (amount <= 0) {
      throw Exception('يجب أن يكون المبلغ أكبر من صفر');
    }

    final docRef = _customersRef.doc(customerId);

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
    });
  }
}
