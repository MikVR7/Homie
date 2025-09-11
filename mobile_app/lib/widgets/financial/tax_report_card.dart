import 'package:flutter/material.dart';
import 'package:homie_app/models/financial_models.dart';
import 'package:homie_app/theme/app_theme.dart';

class TaxReportCard extends StatelessWidget {
  final TaxReport taxReport;

  const TaxReportCard({
    super.key,
    required this.taxReport,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Austrian Tax Report 2024',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTaxItem(
                  context,
                  'Gross Income',
                  taxReport.grossIncome,
                  Icons.trending_up,
                  AppColors.info,
                ),
                _buildTaxItem(
                  context,
                  'Taxable Income',
                  taxReport.taxableIncome,
                  Icons.account_balance,
                  AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTaxItem(
                  context,
                  'Income Tax',
                  taxReport.incomeTax,
                  Icons.receipt_long,
                  AppColors.warning,
                ),
                _buildTaxItem(
                  context,
                  'Social Security',
                  taxReport.socialSecurity,
                  Icons.security,
                  AppColors.secondary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTaxItem(
                  context,
                  'Total Tax',
                  taxReport.totalTax,
                  Icons.money_off,
                  AppColors.error,
                ),
                _buildTaxItem(
                  context,
                  'Net Income',
                  taxReport.netIncome,
                  Icons.savings,
                  AppColors.success,
                ),
              ],
            ),
            if (taxReport.recommendations.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Tax Optimization Recommendations',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...taxReport.recommendations.map((recommendation) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: AppColors.surface,
                  child: ListTile(
                    leading: Icon(
                      _getPriorityIcon(recommendation.priority),
                      color: _getPriorityColor(recommendation.priority),
                    ),
                    title: Text(
                      recommendation.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      recommendation.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Save',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '€${recommendation.potentialSavings.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTaxItem(
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
            '€${value.toStringAsFixed(2)}',
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

  IconData _getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Icons.priority_high;
      case 'medium':
        return Icons.remove;
      case 'low':
        return Icons.low_priority;
      default:
        return Icons.info;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      case 'low':
        return AppColors.success;
      default:
        return AppColors.info;
    }
  }
} 