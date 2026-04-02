import 'package:flutter/material.dart';
import 'package:app_expenses_tracker_/models/budget_model.dart';
import 'package:app_expenses_tracker_/services/firebase_service.dart';
import 'package:app_expenses_tracker_/theme/app_colors.dart';
import 'package:app_expenses_tracker_/theme/app_typography.dart';
import 'package:app_expenses_tracker_/theme/app_theme.dart';
import 'package:app_expenses_tracker_/utils/format_utils.dart';

class AddBudgetScreen extends StatefulWidget {
  final String userId;

  const AddBudgetScreen({
    super.key,
    required this.userId,
  });

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  late DateTime _startDate;
  late DateTime _endDate;
  String _selectedPeriod = 'monthly';
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _updateEndDate();
  }

  void _updateEndDate() {
    if (_selectedPeriod == 'weekly') {
      _endDate = _startDate.add(const Duration(days: 6));
    } else {
      _endDate = DateTime(
        _startDate.year,
        _startDate.month + 1,
        _startDate.day - 1,
      );
    }
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
    if (picked != null && picked != _startDate) {
      if (mounted) {
        setState(() {
          _startDate = picked;
          _updateEndDate();
        });
      }
    }
  }

  void _createBudget() async {
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
      final budget = Budget(
        userId: widget.userId,
        name: _nameController.text.trim(),
        amount: FormatUtils.parseAmount(_amountController.text),
        period: _selectedPeriod,
        startDate: _startDate,
        endDate: _endDate,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await _firebaseService.createBudget(budget);

      if (mounted) {
        Navigator.of(context).pop();
        _showSuccessSnackBar('Budget created successfully');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error creating budget: ${e.toString()}');
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
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Budget'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingXLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel('Budget Name *'),
            const SizedBox(height: AppDimensions.spacingSmall),
            _buildNameTextField(),
            const SizedBox(height: AppDimensions.spacingLarge),
            _buildSectionLabel('Budget Amount *'),
            const SizedBox(height: AppDimensions.spacingSmall),
            _buildAmountTextField(),
            const SizedBox(height: AppDimensions.spacingLarge),
            _buildSectionLabel('Budget Period'),
            const SizedBox(height: AppDimensions.spacingSmall),
            _buildPeriodSelector(),
            const SizedBox(height: AppDimensions.spacingLarge),
            _buildSectionLabel('Start Date'),
            const SizedBox(height: AppDimensions.spacingSmall),
            _buildStartDatePicker(),
            const SizedBox(height: AppDimensions.spacingLarge),
            _buildSectionLabel('End Date'),
            const SizedBox(height: AppDimensions.spacingSmall),
            _buildEndDateDisplay(),
            const SizedBox(height: 40),
            _buildCreateButton(),
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
        hintText: 'e.g., Monthly Expenses',
        prefixIcon: const Icon(Icons.label_outline),
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

  Widget _buildPeriodSelector() {
    return Row(
      children: [
        Expanded(
          child: RadioListTile<String>(
            dense: true,
            title: const Text('Weekly'),
            value: 'weekly',
            groupValue: _selectedPeriod,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedPeriod = value;
                  _updateEndDate();
                });
              }
            },
            activeColor: AppColors.primary,
          ),
        ),
        Expanded(
          child: RadioListTile<String>(
            dense: true,
            title: const Text('Monthly'),
            value: 'monthly',
            groupValue: _selectedPeriod,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedPeriod = value;
                  _updateEndDate();
                });
              }
            },
            activeColor: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildStartDatePicker() {
    return GestureDetector(
      onTap: _selectStartDate,
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
              FormatUtils.formatDate(_startDate),
              style: AppTypography.body1,
            ),
            const Spacer(),
            Icon(Icons.edit, color: AppColors.primary.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }

  Widget _buildEndDateDisplay() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lightGray),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        color: AppColors.surfaceAlt,
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: AppColors.textLight),
          const SizedBox(width: AppDimensions.spacingMedium),
          Text(
            FormatUtils.formatDate(_endDate),
            style: AppTypography.body2,
          ),
          const Spacer(),
          Text(
            '(Auto-calculated)',
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createBudget,
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text('Create Budget'),
      ),
    );
  }
}
