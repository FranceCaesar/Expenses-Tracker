import 'package:flutter/material.dart';
import 'package:app_expenses_tracker_/models/budget_model.dart';
import 'package:app_expenses_tracker_/models/expense_model.dart';
import 'package:app_expenses_tracker_/services/firebase_service.dart';
import 'package:app_expenses_tracker_/services/api_service.dart';
import 'package:app_expenses_tracker_/services/currency_service.dart';
import 'package:app_expenses_tracker_/theme/app_colors.dart';
import 'package:app_expenses_tracker_/theme/app_typography.dart';
import 'package:app_expenses_tracker_/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  final VoidCallback onLogout;

  const HomeScreen({
    super.key,
    required this.userId,
    required this.onLogout,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

String _format12HourTime(DateTime dateTime) {
  return DateFormat('hh:mm a').format(dateTime);
}

String _formatCurrency(double amount) {
  final formatter = NumberFormat('#,##0.00', 'en_US');
  return formatter.format(amount);
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  String _selectedCurrency = 'PHP';
  String _currencySymbol = '₱';
  Map<String, double> _exchangeRates = {};
  Map<String, Map<String, String>> _currencyMetadata = {};
  bool _isLoadingRates = true;
  DateTime? _ratesFetchTime;
  String? _userEmail;
  late AnimationController _fadeController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController.forward();
    _slideController.forward();
    
    // Defer heavy operations to after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrency();
      _loadUserEmail();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadUserEmail() async {
    final user = _firebaseService.getCurrentUser();
    if (mounted) {
      setState(() {
        _userEmail = user?.email ?? 'User';
      });
    }
  }

  Future<void> _loadCurrency() async {
    try {
      if (kDebugMode) print('[HomeScreen] Loading currency...');
      final currency = await CurrencyService.getSelectedCurrency();
      final symbol = await CurrencyService.getCurrencySymbol(currency);
      if (mounted) {
        setState(() {
          _selectedCurrency = currency;
          _currencySymbol = symbol;
        });
      }
    } catch (e) {
      if (kDebugMode) print('[HomeScreen] Error loading currency: $e');
      // Use defaults on error
      if (mounted) {
        setState(() {
          _selectedCurrency = 'PHP';
          _currencySymbol = '₱';
        });
      }
    }
    _fetchExchangeRates();
  }

  Future<void> _fetchExchangeRates() async {
    if (!mounted) return;
    
    try {
      if (kDebugMode) print('[HomeScreen] Fetching exchange rates for: $_selectedCurrency');
      setState(() {
        _isLoadingRates = true;
      });

      // Check internet connection first
      final hasConnection = await ApiService.checkConnection();
      if (kDebugMode) print('[HomeScreen] Internet connection: $hasConnection');
      if (!hasConnection) {
        if (mounted) {
          setState(() {
            _isLoadingRates = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No internet connection. Please check your network.'),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Retry',
                onPressed: _fetchExchangeRates,
              ),
            ),
          );
        }
        return;
      }

      // Fetch rates from API
      if (kDebugMode) print('[HomeScreen] Calling ApiService.getExchangeRates()');
      final rates = await ApiService.getExchangeRates(_selectedCurrency);
      if (kDebugMode) print('[HomeScreen] Successfully fetched ${rates.length} exchange rates');
      
      if (kDebugMode) print('[HomeScreen] Calling ApiService.getCurrencyMetadata()');
      final metadata = await ApiService.getCurrencyMetadata();
      if (kDebugMode) print('[HomeScreen] Successfully fetched ${metadata.length} currencies');

      // Remove base currency from rates
      rates.remove(_selectedCurrency);

      if (mounted) {
        setState(() {
          _exchangeRates = rates;
          _currencyMetadata = metadata;
          _isLoadingRates = false;
          _ratesFetchTime = DateTime.now();
        });
      }
    } catch (e) {
      if (kDebugMode) print('[HomeScreen] Error in _fetchExchangeRates: $e');
      _handleExchangeRateError(e);
    }
  }

  void _handleExchangeRateError(dynamic error) {
    if (!mounted) return;

    setState(() {
      _isLoadingRates = false;
    });

    String message = 'Failed to fetch exchange rates';
    String details = error.toString();

    if (details.contains('No internet')) {
      message = 'No internet connection';
    } else if (details.contains('timed out')) {
      message = 'Request took too long. Please try again.';
    } else if (details.contains('Connection refused')) {
      message = 'Cannot connect to API server';
    } else if (details.contains('rate limit')) {
      message = 'API rate limit exceeded. Try again later.';
    } else if (details.contains('Currency not found')) {
      message = 'Currency code not supported by API';
    } else if (details.contains('network')) {
      message = 'Network error occurred';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: _fetchExchangeRates,
        ),
      ),
    );
  }

  void _showCurrencySelector() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
            color: AppColors.background,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Currency',
                      style: AppTypography.heading3,
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<String>>(
                  future: CurrencyService.getPopularCurrencies(),
                  builder: (context, currenciesSnapshot) {
                    if (currenciesSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (currenciesSnapshot.hasError) {
                      return Center(child: Text('Error: ${currenciesSnapshot.error}'));
                    }
                    
                    final currencies = currenciesSnapshot.data ?? [];
                    
                    return FutureBuilder<Map<String, String>>(
                      future: CurrencyService.getCurrencyCountries(),
                      builder: (context, countriesSnapshot) {
                        if (countriesSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (countriesSnapshot.hasError) {
                          return Center(child: Text('Error: ${countriesSnapshot.error}'));
                        }
                        
                        final currencyCountries = countriesSnapshot.data ?? {};
                        
                        return ListView(
                          shrinkWrap: true,
                          children: currencies.map((currency) {
                            final country = currencyCountries[currency] ?? 'Unknown';
                            final isSelected = currency == _selectedCurrency;
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ListTile(
                                selected: isSelected,
                                selectedTileColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
                                title: Text(
                                  '$currency - $country',
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                    fontSize: 14,
                                    color: isSelected ? AppColors.primary : AppColors.textDark,
                                  ),
                                ),
                                trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                                onTap: () async {
                                  final symbol = await CurrencyService.getCurrencySymbol(currency);
                                  await CurrencyService.setSelectedCurrency(currency);
                                  if (mounted) {
                                    setState(() {
                                      _selectedCurrency = currency;
                                      _currencySymbol = symbol;
                                      _isLoadingRates = true;
                                    });
                                  }
                                  _fetchExchangeRates();
                                  if (mounted) Navigator.pop(context);
                                },
                              ),
                            );
                          }).toList(),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
        title: const Text(
          'Logout',
          style: AppTypography.heading2,
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: AppTypography.body1,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTypography.body1.copyWith(
                color: AppColors.textMedium,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Logout',
              style: AppTypography.buttonText,
            ),
          ),
        ],
      ),
    );
  }

  void _showBudgetHistory() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge)),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Budget History',
                style: AppTypography.heading3,
              ),
              const SizedBox(height: AppDimensions.paddingMedium),
              Text(
                'Past & Expired Budgets',
                style: AppTypography.caption,
              ),
              const SizedBox(height: AppDimensions.paddingMedium),
              SizedBox(
                height: 300,
                child: StreamBuilder<List<Budget>>(
                  stream: _firebaseService.getBudgetHistory(widget.userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final budgets = snapshot.data ?? [];
                    if (budgets.isEmpty) {
                      return const Center(
                        child: Text('No budget history'),
                      );
                    }

                    return ListView.builder(
                      itemCount: budgets.length,
                      itemBuilder: (context, index) {
                        final budget = budgets[index];
                        final isExpired = DateTime.now().isAfter(budget.endDate);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isExpired ? Colors.grey[100] : Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isExpired ? Colors.grey[300]! : Colors.blue[200]!,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      budget.name,
                                      style: AppTypography.body1.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isExpired ? AppColors.errorLight : AppColors.infoLight,
                                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                                    ),
                                    child: Text(
                                      isExpired ? 'Expired' : 'Active',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isExpired ? Colors.red[700] : AppColors.info,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${DateFormat('MMM dd, yyyy').format(budget.startDate)} - ${DateFormat('MMM dd, yyyy').format(budget.endDate)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_currencySymbol${_formatCurrency(budget.amount)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExchangeRatesDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'All Exchange Rates',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              if (_ratesFetchTime != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'From $_selectedCurrency • ${_format12HourTime(_ratesFetchTime!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              Expanded(
                child: _isLoadingRates
                    ? const Center(child: CircularProgressIndicator())
                    : _exchangeRates.isEmpty
                        ? const Center(child: Text('No exchange rates available'))
                        : ListView.builder(
                            itemCount: _exchangeRates.length,
                            itemBuilder: (context, index) {
                              final entry = _exchangeRates.entries.toList()[index];
                              final targetCurrency = entry.key;
                              final metadata = _currencyMetadata[targetCurrency];
                              final countryName = metadata?['country'] ?? 'Unknown';

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            targetCurrency,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Color(0xFF1F2937),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            countryName,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF6B7280),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        entry.value.toStringAsFixed(4),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF6366F1),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
              ),
              child: Center(
                child: Text(
                  (_userEmail?.isNotEmpty ?? false)
                      ? _userEmail![0].toUpperCase()
                      : 'U',
                  style: AppTypography.body1.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account',
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.textMedium,
                    ),
                  ),
                  Text(
                    _userEmail ?? 'Loading...',
                    style: AppTypography.label.copyWith(
                      color: AppColors.textDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.textDark),
            onPressed: _showBudgetHistory,
            tooltip: 'Budget History',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textDark),
            onPressed: _showLogoutConfirmation,
            tooltip: 'Logout',
          ),
        ],
      ),

      body: StreamBuilder<List<Budget>>(
        stream: _firebaseService.getActiveBudgets(widget.userId),
        builder: (context, budgetSnapshot) {
          if (budgetSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!budgetSnapshot.hasData || budgetSnapshot.data!.isEmpty) {
            return Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.account_balance_wallet,
                        size: 80, color: AppColors.textLight),
                    const SizedBox(height: AppDimensions.paddingMedium),
                    Text('No active budget', style: AppTypography.body1),
                    const SizedBox(height: AppDimensions.paddingXLarge),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/add-budget');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text('Create Budget',
                          style: AppTypography.buttonText),
                    ),
                  ],
                ),
              ),
              
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/add-budget');
                },
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.add),
              ),
            );
          }

          final budget = budgetSnapshot.data!.first;

          return FadeTransition(
            opacity: Tween<double>(begin: 0, end: 1).animate(_fadeController),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade50, Colors.purple.shade50],
                ),
              ),

              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    SlideTransition(
                      position: Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
                          .animate(_slideController),
                      child: GestureDetector(
                        onTap: _showCurrencySelector,
                        child: Container(
                          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadowColor,
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current Currency',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.textMedium,
                                    ),
                                  ),
                                  const SizedBox(height: AppDimensions.paddingSmall),
                                  Text(
                                    '$_selectedCurrency - $_currencySymbol',
                                    style: AppTypography.heading2,
                                  ),
                                ],
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                                ),
                                padding: const EdgeInsets.all(AppDimensions.paddingSmall),
                                child: const Icon(Icons.edit, color: Colors.white, size: 20),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    
                    AnimatedCard(
                      duration: const Duration(milliseconds: 600),
                      delay: 100,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    budget.name,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        title: const Text('Delete Budget'),
                                        content: const Text('Are you sure you want to delete this budget? This action cannot be undone.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              await _firebaseService.deleteBudget(budget.id!);
                                              if (mounted) {
                                                Navigator.pop(context);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Budget deleted successfully'),
                                                    backgroundColor: Colors.green,
                                                  ),
                                                );
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                            ),
                                            child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Budget Period',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          budget.period.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${DateFormat('MMM dd').format(budget.startDate)} - ${DateFormat('MMM dd').format(budget.endDate)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Total Budget',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '$_currencySymbol${_formatCurrency(budget.amount)}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    StreamBuilder<List<Expense>>(
                      stream: _firebaseService.getBudgetExpenses(budget.id!),
                      builder: (context, expenseSnapshot) {
                        if (expenseSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final expenses = expenseSnapshot.data ?? [];
                        final totalSpent = expenses.fold(0.0, (sum, exp) => sum + exp.amount);
                        final remaining = budget.amount - totalSpent;
                        final percentSpent = (totalSpent / budget.amount * 100).clamp(0.0, 100.0);
                        final isOverBudget = remaining < 0;

                        return Column(
                          children: [
                            AnimatedCard(
                              duration: const Duration(milliseconds: 600),
                              delay: 200,
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isOverBudget
                                        ? Colors.red.withValues(alpha: 0.3)
                                        : Colors.green.withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isOverBudget ? Colors.red : Colors.green).withValues(alpha: 0.2),
                                      blurRadius: 15,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Spent',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '$_currencySymbol${_formatCurrency(totalSpent)}',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: isOverBudget ? Colors.red : Colors.green,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: LinearProgressIndicator(
                                        value: percentSpent / 100,
                                        minHeight: 12,
                                        backgroundColor: Colors.grey[300],
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          isOverBudget ? Colors.red : Colors.green,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${percentSpent.toStringAsFixed(1)}% spent',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                        Text(
                                          isOverBudget
                                              ? '$_currencySymbol${_formatCurrency(remaining.abs())} over'
                                              : '$_currencySymbol${_formatCurrency(remaining)} remaining',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: isOverBudget ? Colors.red : Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Recent Expenses',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (expenses.isNotEmpty)
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context)
                                          .pushNamed('/expenses', arguments: budget);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6366F1),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                    ),
                                    child: const Text(
                                      'View All',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (expenses.isEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 16),
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.receipt_long,
                                        size: 56, color: Colors.grey[400]),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No expenses yet',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).pushNamed(
                                          '/add-expense',
                                          arguments: budget,
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF6366F1),
                                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                      ),
                                      child: const Text(
                                        'Add Expense',
                                        style: TextStyle(color: Colors.white, fontSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: expenses.length > 3 ? 3 : expenses.length,
                                itemBuilder: (context, index) {
                                  final expense = expenses[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey[200]!,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  expense.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 15,
                                                    color: Color(0xFF1F2937),
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  expense.category,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF6B7280),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '$_currencySymbol${_formatCurrency(expense.amount)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Color(0xFF6366F1),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        );
                      },
                    ),
                    
                    const SizedBox(height: 24),

                    AnimatedCard(
                      duration: const Duration(milliseconds: 600),
                      delay: 300,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: const Text(
                                    'Exchange Rates',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1F2937),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (_ratesFetchTime != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _format12HourTime(_ratesFetchTime!),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF6366F1),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (_ratesFetchTime != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                DateFormat('MMM dd, yyyy').format(_ratesFetchTime!),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9CA3AF),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            if (_isLoadingRates)
                              const Center(child: CircularProgressIndicator())
                            else if (_exchangeRates.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Unable to load exchange rates',
                                  style: TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            else
                              RepaintBoundary(
                                child: GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 1.3,
                                ),
                                itemCount: _exchangeRates.length > 6
                                    ? 6
                                    : _exchangeRates.length,
                                itemBuilder: (context, index) {
                                  final entry = _exchangeRates.entries.toList()[index];
                                  final targetCurrency = entry.key;
                                  final metadata = _currencyMetadata[targetCurrency];
                                  final countryName = metadata?['country'] ?? 'Unknown';
                                  
                                  return Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                          color: Colors.grey[200]!,
                                          width: 1.5),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          targetCurrency,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1F2937),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Flexible(
                                          child: Text(
                                            countryName,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF9CA3AF),
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          entry.value.toStringAsFixed(4),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF6366F1),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),

                            if (_exchangeRates.length > 6)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _showExchangeRatesDialog,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6366F1),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text(
                                      'View All Rates',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                  ],
                ),
              ),

            ),
           );

          },
        ),
    );
  }
}

class AnimatedCard extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final int delay;

  const AnimatedCard({
    super.key,
    required this.child,
    required this.duration,
    this.delay = 0,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _offsetAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _offsetAnimation,
        child: widget.child,
      ),
    );
  }
}

