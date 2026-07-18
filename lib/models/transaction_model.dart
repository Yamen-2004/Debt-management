import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String type;
  final double amount;
  final String note;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.note,
    required this.createdAt,
  });

  bool get isIncrease => type == 'increase';

  factory TransactionModel.fromMap(String id, Map<String, dynamic> map) {
    return TransactionModel(
      id: id,
      type: map['type'] as String? ?? 'increase',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      note: map['note'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'amount': amount,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
