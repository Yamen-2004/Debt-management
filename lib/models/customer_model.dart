import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String id;
  final String name;
  final String searchName;
  final double balance;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomerModel({
    required this.id,
    required this.name,
    required this.searchName,
    required this.balance,
    required this.createdAt,
    required this.updatedAt,
  });

  CustomerModel copyWith({
    String? id,
    String? name,
    String? searchName,
    double? balance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      searchName: searchName ?? this.searchName,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory CustomerModel.fromMap(String id, Map<String, dynamic> map) {
    return CustomerModel(
      id: id,
      name: map['name'] as String? ?? '',
      searchName: map['searchName'] as String? ?? '',
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'searchName': searchName,
      'balance': balance,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
