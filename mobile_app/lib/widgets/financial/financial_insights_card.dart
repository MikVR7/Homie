import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:homie_app/providers/financial_provider.dart';
import 'package:homie_app/theme/app_theme.dart';

class FinancialInsightsCard extends StatelessWidget {
  const FinancialInsightsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinancialProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return _buildLoadingCard();
        }

        final summary = provider.summary;
        if (summary == null) {
          return _buildEmptyCard();
        }

        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.surfaceGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildInsightsList(summary),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 200,
      decoration: BoxDecoration(
        gradient: AppColors.surfaceGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.surfaceGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.insights_outlined,
            size: 48,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Financial Insights',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add income and expenses to see insights',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.insights,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Financial Insights',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                'Austrian Tax & Budget Analysis',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsList(summary) {
    final insights = _generateInsights(summary);
    
    return Column(
      children: insights.map((insight) => _buildInsightItem(insight)).toList(),
    );
  }

  Widget _buildInsightItem(FinancialInsight insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: insight.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: insight.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: insight.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              insight.icon,
              color: insight.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: insight.color,
                  ),
                ),
                if (insight.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    insight.subtitle!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (insight.value != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: insight.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                insight.value!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: insight.color,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<FinancialInsight> _generateInsights(summary) {
    final insights = <FinancialInsight>[];

    // Tax burden analysis
    final taxBurden = summary.totalTaxLiability / summary.totalIncome * 100;
    if (taxBurden > 0) {
      insights.add(FinancialInsight(
        icon: Icons.account_balance,
        title: 'Tax Burden',
        subtitle: 'Your effective tax rate',
        value: '${taxBurden.toStringAsFixed(1)}%',
        color: taxBurden > 30 ? Colors.red : (taxBurden > 20 ? Colors.orange : Colors.green),
      ));
    }

    // Monthly cash flow
    if (summary.monthlyCashFlow > 0) {
      insights.add(FinancialInsight(
        icon: Icons.trending_up,
        title: 'Monthly Cash Flow',
        subtitle: 'Average monthly surplus',
        value: '€${summary.monthlyCashFlow.toStringAsFixed(0)}',
        color: Colors.green,
      ));
    } else if (summary.monthlyCashFlow < 0) {
      insights.add(FinancialInsight(
        icon: Icons.trending_down,
        title: 'Monthly Deficit',
        subtitle: 'You\'re spending more than earning',
        value: '€${summary.monthlyCashFlow.abs().toStringAsFixed(0)}',
        color: Colors.red,
      ));
    }

    // Construction budget status
    if (summary.constructionBudgetUsed > 0) {
      final usage = summary.constructionBudgetUsed / 
          (summary.constructionBudgetUsed + summary.constructionBudgetRemaining) * 100;
      insights.add(FinancialInsight(
        icon: Icons.construction,
        title: 'Construction Progress',
        subtitle: 'Budget utilization',
        value: '${usage.toStringAsFixed(1)}%',
        color: usage > 80 ? Colors.red : (usage > 60 ? Colors.orange : Colors.blue),
      ));
    }

    // Savings rate
    final savingsRate = summary.monthlyCashFlow / (summary.totalIncome / 12) * 100;
    if (savingsRate > 0) {
      insights.add(FinancialInsight(
        icon: Icons.savings,
        title: 'Savings Rate',
        subtitle: 'Percentage of income saved',
        value: '${savingsRate.toStringAsFixed(1)}%',
        color: savingsRate > 20 ? Colors.green : (savingsRate > 10 ? Colors.orange : Colors.red),
      ));
    }

    // Income diversification
    final selfEmploymentRatio = summary.totalSelfEmploymentIncome / summary.totalIncome * 100;
    if (selfEmploymentRatio > 0) {
      insights.add(FinancialInsight(
        icon: Icons.work,
        title: 'Income Diversification',
        subtitle: 'Self-employment income ratio',
        value: '${selfEmploymentRatio.toStringAsFixed(1)}%',
        color: selfEmploymentRatio > 50 ? Colors.purple : Colors.blue,
      ));
    }

    // Add default insight if no meaningful data
    if (insights.isEmpty) {
      insights.add(FinancialInsight(
        icon: Icons.info_outline,
        title: 'Getting Started',
        subtitle: 'Add income and expenses to see personalized insights',
        color: Colors.blue,
      ));
    }

    return insights;
  }
}

class FinancialInsight {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? value;
  final Color color;

  FinancialInsight({
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    required this.color,
  });
} 