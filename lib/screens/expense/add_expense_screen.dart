import 'package:flutter/material.dart';
import 'package:app_expenses_tracker_/models/budget_model.dart';
import 'package:app_expenses_tracker_/models/expense_model.dart';
import 'package:app_expenses_tracker_/services/firebase_service.dart';
import 'package:app_expenses_tracker_/theme/app_colors.dart';
import 'package:app_expenses_tracker_/theme/app_typography.dart';
import 'package:app_expenses_tracker_/theme/app_theme.dart';
import 'package:app_expenses_tracker_/utils/format_utils.dart';

class AddExpenseScreen extends StatefulWidget {
  final Budget budget;
  final Expense? expense;
  final String userId;

  const AddExpenseScreen({
    super.key,
    required this.budget,
    this.expense,
    required this.userId,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late String _selectedCategory;
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;

  static const List<String> _categories = [
    'Food',
    'Transport',
    'Entertainment',
    'Shopping',
    'Utilities',
    'Health',
    'Education',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.expense?.name ?? '');
    _amountController = TextEditingController(
      text: widget.expense?.amount.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.expense?.description ?? '',
    );
    _selectedDate = widget.expense?.date ?? DateTime.now();
    _selectedCategory = widget.expense?.category ?? 'Food';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: widget.budget.startDate,
      lastDate: widget.budget.endDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      if (mounted) {
        setState(() => _selectedDate = picked);
      }
    }
  }

  void _saveExpense() async {
    if (_nameController.text.isEmpty || _amountController.text.isEmpty) {
      _showErrorSnackBar('Please fill in all required fields');
      return;
    }

    if (!FormatUtils.isValidAmount(_amountController.text)) {
      _showErrorSnackBar('Please enter a valid amount');
      return;
    }

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final expense = Expense(
        id: widget.expense?.id,
        userId: widget.userId,
        budgetId: widget.budget.id!,
        name: _nameController.text.trim(),
        amount: FormatUtils.parseAmount(_amountController.text),
        category: _selectedCategory,
        date: _selectedDate,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (widget.expense != null) {
        await _firebaseService.updateExpense(widget.expense!.id!, {
          'name': expense.name,
          'amount': expense.amount,
          'category': expense.category,
          'date': expense.date,
          'description': expense.description,
        });
        _showSuccessSnackBar('Expense updated successfully');
      } else {
        await _firebaseService.createExpense(expense);
        _showSuccessSnackBar('Expense added successfully');
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error saving expense: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expense != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Expense' : 'Add Expense'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingXLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel('Expense Name *'),
            const SizedBox(height: AppDimensions.spacingSmall),
            _buildNameTextField(),
            const SizedBox(height: AppDimensions.spacingLarge),
            _buildSectionLabel('Amount *'),
            const SizedBox(height: AppDimensions.spacingSmall),
            _buildAmountTextField(),
            const SizedBox(height: AppDimensions.spacingLarge),
            _buildSectionLabel('Category'),
            const SizedBox(height: AppDimensions.spacingSmall),
            _buildCategoryDropdown(),
            const SizedBox(height: AppDimensions.spacingLarge),
            _buildSectionLabel('Date'),
            const SizedBox(height: AppDimensions.spacingSmall),
            _buildDatePicker(),
            const SizedBox(height: AppDimensions.spacingLarge),
            _buildSectionLabel('Description (Optional)'),
            const SizedBox(height: AppDimensions.spacingSmall),
            _buildDescriptionTextField(),
            const SizedBox(height: 40),
            _buildSaveButton(isEditing),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: AppTypography.heading4.copyWith(color: AppColors.textDark),
    );
  }

  Widget _buildNameTextField() {
    return TextField(
      controller: _nameController,
      decoration: InputDecoration(
        hintText: 'Enter expense name',
        prefixIcon: const Icon(Icons.receipt_long),
      ),
    );
  }

  Widget _buildAmountTextField() {
    return TextField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        hintText: 'Enter amount (numbers only)',
        prefixIcon: const Icon(Icons.attach_money),
        helperText: 'Amounts will be formatted automatically',
        helperStyle: AppTypography.caption,
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      items: _categories
          .map((category) => DropdownMenuItem(
                value: category,
                child: Text(category),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedCategory = value);
        }
      },
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.category),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          color: AppColors.surface,
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.primary),
            const SizedBox(width: AppDimensions.spacingMedium),
            Text(
              FormatUtils.formatDate(_selectedDate),
              style: AppTypography.body1,
            ),
            const Spacer(),
            Icon(Icons.edit, color: AppColors.primary.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionTextField() {
    return TextField(
      controller: _descriptionController,
      maxLines: 3,
      maxLength: 500,
      decoration: InputDecoration(
        hintText: 'Add notes or details about this expense',
        prefixIcon: const Icon(Icons.description),
        counterStyle: AppTypography.caption,
      ),
    );
  }

  Widget _buildSaveButton(bool isEditing) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveExpense,
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(isEditing ? 'Update Expense' : 'Add Expense'),
      ),
    );
  }
}
