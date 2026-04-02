import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_expenses_tracker_/services/firebase_service.dart';
import 'package:app_expenses_tracker_/services/currency_service.dart';
import 'package:app_expenses_tracker_/screens/auth/login_screen.dart';
import 'package:app_expenses_tracker_/screens/auth/register_screen.dart';
import 'package:app_expenses_tracker_/screens/home/home_screen.dart';
import 'package:app_expenses_tracker_/screens/budget/add_budget_screen.dart';
import 'package:app_expenses_tracker_/screens/expense/add_expense_screen.dart';
import 'package:app_expenses_tracker_/screens/expense/expense_list_screen.dart';
import 'package:app_expenses_tracker_/models/budget_model.dart';
import 'package:app_expenses_tracker_/models/expense_model.dart';
import 'package:app_expenses_tracker_/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  await CurrencyService.initializeCurrencyData();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showLogin = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ExpenseVault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: StreamBuilder<User?>(
        stream: FirebaseService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            return HomeScreen(
              userId: snapshot.data!.uid,
              onLogout: () async {
                await FirebaseService().logoutUser();
              },
            );
          }

          return AuthScreen(
            showLogin: _showLogin,
            onSwitchToRegister: () {
              setState(() => _showLogin = false);
            },
            onSwitchToLogin: () {
              setState(() => _showLogin = true);
            },
          );
        },
      ),
      onGenerateRoute: _handleRoute,
    );
  }

  /// Route handler for named navigation
  Route<dynamic>? _handleRoute(RouteSettings settings) {
    final user = FirebaseService().getCurrentUser();
    if (user == null) return null;

    switch (settings.name) {
      case '/add-budget':
        return MaterialPageRoute(
          builder: (context) => AddBudgetScreen(userId: user.uid),
        );

      case '/add-expense':
        final args = settings.arguments;
        Budget? budget;
        Expense? expense;

        if (args is Budget) {
          budget = args;
        } else if (args is Map<String, dynamic>) {
          budget = args['budget'] as Budget?;
          expense = args['expense'] as Expense?;
        }

        if (budget != null) {
          return MaterialPageRoute(
            builder: (context) => AddExpenseScreen(
              budget: budget as Budget,
              expense: expense,
              userId: user.uid,
            ),
          );
        }
        break;

      case '/expenses':
        final args = settings.arguments;
        if (args is Budget) {
          return MaterialPageRoute(
            builder: (context) => ExpenseListScreen(budget: args),
          );
        }
        // Return null if no budget is provided
        return null;
    }

    return null;
  }
}

class AuthScreen extends StatefulWidget {
  final bool showLogin;
  final VoidCallback onSwitchToRegister;
  final VoidCallback onSwitchToLogin;

  const AuthScreen({
    super.key,
    required this.showLogin,
    required this.onSwitchToRegister,
    required this.onSwitchToLogin,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool _showLogin;

  @override
  void initState() {
    super.initState();
    _showLogin = widget.showLogin;
  }

  @override
  Widget build(BuildContext context) {
    return _showLogin
        ? LoginScreen(
            onSwitchToRegister: () {
              setState(() => _showLogin = false);
              widget.onSwitchToRegister();
            },
          )
        : RegisterScreen(
            onSwitchToLogin: () {
              setState(() => _showLogin = true);
              widget.onSwitchToLogin();
            },
          );
  }
}
