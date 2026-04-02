import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_expenses_tracker_/models/budget_model.dart';
import 'package:app_expenses_tracker_/models/expense_model.dart';
import '../firebase_options.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();

  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Auth methods
  Future<UserCredential> registerUser(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> loginUser(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> logoutUser() async {
    await _auth.signOut();
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Stream<User?> get authStateChanges {
    return _auth.authStateChanges();
  }

  // Budget methods
  Future<String> createBudget(Budget budget) async {
    final docRef = await _firestore.collection('budgets').add(budget.toMap());
    return docRef.id;
  }

  Stream<List<Budget>> getActiveBudgets(String userId) {
    return _firestore
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Budget.fromFirestore(doc)).toList());
  }

  Stream<List<Budget>> getBudgetHistory(String userId) {
    return _firestore
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Budget.fromFirestore(doc)).toList());
  }

  Future<void> updateBudget(String budgetId, Map<String, dynamic> data) async {
    await _firestore.collection('budgets').doc(budgetId).update(data);
  }

  Future<void> deleteBudget(String budgetId) async {
    await _firestore.collection('budgets').doc(budgetId).delete();
  }

  // Expense methods
  Future<String> createExpense(Expense expense) async {
    final docRef = await _firestore.collection('expenses').add(expense.toMap());
    return docRef.id;
  }

  Stream<List<Expense>> getBudgetExpenses(String budgetId) {
    return _firestore
        .collection('expenses')
        .where('budgetId', isEqualTo: budgetId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Expense.fromFirestore(doc)).toList());
  }

  Stream<List<Expense>> getUserExpenses(String userId) {
    return _firestore
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Expense.fromFirestore(doc)).toList());
  }

  Future<void> updateExpense(String expenseId, Map<String, dynamic> data) async {
    await _firestore.collection('expenses').doc(expenseId).update(data);
  }

  Future<void> deleteExpense(String expenseId) async {
    await _firestore.collection('expenses').doc(expenseId).delete();
  }

  Future<void> deleteExpensesByBudgetId(String budgetId) async {
    final expenses = await _firestore
        .collection('expenses')
        .where('budgetId', isEqualTo: budgetId)
        .get();

    for (var doc in expenses.docs) {
      await doc.reference.delete();
    }
  }
}
