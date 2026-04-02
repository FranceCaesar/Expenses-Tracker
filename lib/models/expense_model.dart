import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String? id;
  final String userId;
  final String budgetId;
  final String name;
  final double amount;
  final String category;
  final DateTime date;
  final String? description;

  Expense({
    this.id,
    required this.userId,
    required this.budgetId,
    required this.name,
    required this.amount,
    required this.category,
    required this.date,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'budgetId': budgetId,
      'name': name,
      'amount': amount,
      'category': category,
      'date': date,
      'description': description,
    };
  }

  factory Expense.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Expense(
      id: doc.id,
      userId: data['userId'] ?? '',
      budgetId: data['budgetId'] ?? '',
      name: data['name'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      category: data['category'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: data['description'],
    );
  }
}
