import 'package:cloud_firestore/cloud_firestore.dart';

class Budget {
  final String? id;
  final String userId;
  final String name;
  final double amount;
  final String period; // 'weekly' or 'monthly'
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final DateTime createdAt;

  Budget({
    this.id,
    required this.userId,
    required this.name,
    required this.amount,
    required this.period,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'amount': amount,
      'period': period,
      'startDate': startDate,
      'endDate': endDate,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }

  factory Budget.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Budget(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      period: data['period'] ?? 'monthly',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
