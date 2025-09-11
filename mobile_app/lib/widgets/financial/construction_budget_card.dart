import 'package:flutter/material.dart';
import 'package:homie_app/models/financial_models.dart';
import 'package:homie_app/theme/app_theme.dart';

class ConstructionBudgetCard extends StatelessWidget {
  final ConstructionBudget budget;

  const ConstructionBudgetCard({
    super.key,
    required this.budget,
  });

  @override
  Widget build(BuildContext context) {
    final usedPercentage = budget.totalBudget > 0 
        ? (budget.usedBudget / budget.totalBudget) * 100 
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Budget Overview',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  '${usedPercentage.toStringAsFixed(1)}% used',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: usedPercentage > 90 ? AppColors.error : AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: usedPercentage / 100,
              backgroundColor: AppColors.textSecondary.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                usedPercentage > 90 ? AppColors.error : AppColors.success,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBudgetItem(
                  context,
                  'Total Budget',
                  budget.totalBudget,
                  Icons.account_balance,
                  AppColors.info,
                ),
                _buildBudgetItem(
                  context,
                  'Used',
                  budget.usedBudget,
                  Icons.trending_down,
                  AppColors.error,
                ),
                _buildBudgetItem(
                  context,
                  'Remaining',
                  budget.remainingBudget,
                  Icons.savings,
                  AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Loan Information',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLoanItem(
                  context,
                  'Loan Amount',
                  '€${budget.loanAmount.toStringAsFixed(2)}',
                ),
                _buildLoanItem(
                  context,
                  'Interest Rate',
                  '${budget.interestRate.toStringAsFixed(2)}%',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLoanItem(
                  context,
                  'Term',
                  '${budget.loanTermMonths} months',
                ),
                _buildLoanItem(
                  context,
                  'Monthly Payment',
                  '€${budget.monthlyPayment.toStringAsFixed(2)}',
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Expenses',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to full expense list
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (budget.expenses.isEmpty)
              Center(
                child: Text(
                  'No expenses recorded yet',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else
              Column(
                children: budget.expenses.take(3).map((expense) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _getCategoryIcon(expense.category),
                      color: AppColors.primary,
                    ),
                    title: Text(
                      expense.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    subtitle: Text(
                      '${expense.category} • ${_formatDate(expense.date)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: Text(
                      '€${expense.amount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetItem(
    BuildContext context,
    String label,
    double value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: color,
          ),
          const SizedBox(height: 4),
          Text(
            '€${value.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoanItem(BuildContext context, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'materials':
        return Icons.build_circle;
      case 'labor':
        return Icons.engineering;
      case 'permits':
        return Icons.gavel;
      case 'equipment':
        return Icons.build;
      case 'utilities':
        return Icons.electrical_services;
      default:
        return Icons.construction;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 