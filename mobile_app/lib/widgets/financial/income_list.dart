import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:homie_app/providers/financial_provider.dart';
import 'package:homie_app/theme/app_theme.dart';

class IncomeList extends StatelessWidget {
  const IncomeList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinancialProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.incomeEntries.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Income Entries',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddIncomeDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Income'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: provider.incomeEntries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.attach_money,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No income entries',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add income entries to track your earnings',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: provider.incomeEntries.length,
                      itemBuilder: (context, index) {
                        final entry = provider.incomeEntries[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.success.withOpacity(0.1),
                              child: Icon(
                                entry.type == 'employment'
                                    ? Icons.work
                                    : Icons.business,
                                color: AppColors.success,
                              ),
                            ),
                            title: Text(
                              entry.description,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.type == 'employment' ? 'Employment' : 'Self-Employment',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (entry.employer != null)
                                  Text(
                                    entry.employer!,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                Text(
                                  _formatDate(entry.date),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '€${entry.amount.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
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
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAddIncomeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Income Entry'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'e.g., Salary, Freelance work',
                ),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Amount (€)',
                  hintText: '0.00',
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Employer (optional)',
                  hintText: 'Company name',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement add income
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Income functionality coming soon')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
} 