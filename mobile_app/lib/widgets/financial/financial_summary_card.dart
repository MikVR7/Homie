import 'package:flutter/material.dart';
import 'package:homie_app/models/financial_models.dart';
import 'package:homie_app/theme/app_theme.dart';

class FinancialSummaryCard extends StatelessWidget {
  final FinancialSummary summary;

  const FinancialSummaryCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(
                  context,
                  'Total Income',
                  summary.totalIncome,
                  AppColors.success,
                  Icons.trending_up,
                ),
                _buildSummaryItem(
                  context,
                  'Total Expenses',
                  summary.totalExpenses,
                  AppColors.error,
                  Icons.trending_down,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(
                  context,
                  'Net Income',
                  summary.netIncome,
                  summary.netIncome >= 0 ? AppColors.success : AppColors.error,
                  Icons.account_balance,
                ),
                _buildSummaryItem(
                  context,
                  'Tax Liability',
                  summary.totalTaxLiability,
                  AppColors.warning,
                  Icons.receipt_long,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Income Breakdown',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildIncomeItem(
                  context,
                  'Employment',
                  summary.totalEmploymentIncome,
                ),
                _buildIncomeItem(
                  context,
                  'Self-Employment',
                  summary.totalSelfEmploymentIncome,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Construction Budget',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildIncomeItem(
                  context,
                  'Used',
                  summary.constructionBudgetUsed,
                ),
                _buildIncomeItem(
                  context,
                  'Remaining',
                  summary.constructionBudgetRemaining,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    double value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            '€${value.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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

  Widget _buildIncomeItem(BuildContext context, String label, double value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '€${value.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
} 