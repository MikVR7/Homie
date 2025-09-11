import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:homie_app/providers/financial_provider.dart';
import 'package:homie_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class AccountManagementDialog extends StatefulWidget {
  const AccountManagementDialog({super.key});

  @override
  State<AccountManagementDialog> createState() => _AccountManagementDialogState();
}

class _AccountManagementDialogState extends State<AccountManagementDialog> {
  @override
  void initState() {
    super.initState();
    // No data loading needed - use existing provider data
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          gradient: AppColors.surfaceGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Account Management',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Consumer<FinancialProvider>(
                  builder: (context, provider, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Add New Account Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showAddAccountDialog(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Add New Account'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Simple placeholder content
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: AppColors.surfaceGradient,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border, width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'User Accounts',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Create and manage your custom accounts',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: Text(
                                  'No accounts yet. Add your first account above.',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(Map<String, dynamic> account, FinancialProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getAccountTypeIcon(account['type']),
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${_getAccountTypeName(account['type'])} • €${account['balance'].toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteAccountDialog(account['id'], account['name'], provider);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Account'),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
    );
  }

  Widget _buildLegacyAccountCard(String name, IconData icon, double balance, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Balance: €${balance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'set_balance',
                    child: Row(
                      children: [
                        Icon(Icons.account_balance_wallet, size: 20),
                        SizedBox(width: 8),
                        Text('Set Balance'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'import_csv',
                    child: Row(
                      children: [
                        Icon(Icons.upload_file, size: 20),
                        SizedBox(width: 8),
                        Text('Import CSV'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'view_transactions',
                    child: Row(
                      children: [
                        Icon(Icons.list_alt, size: 20),
                        SizedBox(width: 8),
                        Text('View Transactions'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'transfer',
                    child: Row(
                      children: [
                        Icon(Icons.swap_horiz, size: 20),
                        SizedBox(width: 8),
                        Text('Transfer Money'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) => _handleLegacyAccountAction(value, name, balance, color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityCard(Map<String, dynamic> security, FinancialProvider provider) {
    final isPositive = security['gain_loss'] >= 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      security['symbol'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      security['name'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                                              onPressed: () => _SecurityDialogHelpers.showSecurityHistory(context, security),
                icon: const Icon(Icons.show_chart, color: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quantity: ${security['quantity']}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    Text(
                      'Current: €${security['current_price'].toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Value: €${security['total_value'].toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${isPositive ? '+' : ''}€${security['gain_loss'].toStringAsFixed(2)} (${security['gain_loss_percent'].toStringAsFixed(1)}%)',
                      style: TextStyle(
                        fontSize: 12,
                        color: isPositive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getAccountTypeIcon(String type) {
    switch (type) {
      case 'checking':
        return Icons.account_balance;
      case 'savings':
        return Icons.savings;
      case 'investment':
        return Icons.trending_up;
      case 'cash':
        return Icons.payments;
      default:
        return Icons.account_balance_wallet;
    }
  }

  String _getAccountTypeName(String type) {
    switch (type) {
      case 'checking':
        return 'Checking Account';
      case 'savings':
        return 'Savings Account';
      case 'investment':
        return 'Investment Account';
      case 'cash':
        return 'Cash Account';
      default:
        return 'Account';
    }
  }

  void _showAddAccountDialog(BuildContext context) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    String selectedType = 'checking';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Account Name',
                  hintText: 'My Checking Account',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Account Type'),
                items: const [
                  DropdownMenuItem(value: 'checking', child: Text('Checking Account')),
                  DropdownMenuItem(value: 'savings', child: Text('Savings Account')),
                  DropdownMenuItem(value: 'investment', child: Text('Investment Account')),
                  DropdownMenuItem(value: 'cash', child: Text('Cash Account')),
                ],
                onChanged: (value) => setState(() => selectedType = value!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: balanceController,
                decoration: const InputDecoration(
                  labelText: 'Initial Balance (€)',
                  hintText: '0.00',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                
                final balance = double.tryParse(balanceController.text) ?? 0.0;
                
                Navigator.of(context).pop();
                
                final provider = Provider.of<FinancialProvider>(context, listen: false);
                final success = await provider.createUserAccount(
                  nameController.text.trim(),
                  selectedType,
                  balance,
                );
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Account created successfully!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to create account')),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(String accountId, String accountName, FinancialProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text('Are you sure you want to delete "$accountName"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              final success = await provider.deleteUserAccount(accountId);
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Account deleted successfully!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to delete account')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }



  void _handleLegacyAccountAction(String action, String accountName, double currentBalance, Color color) {
    final accountType = _getAccountTypeFromName(accountName);
    
    switch (action) {
      case 'set_balance':
        _showEnhancedSetBalanceDialog(accountType, accountName, currentBalance);
        break;
      case 'import_csv':
        _showImportCsvDialog(accountType, accountName);
        break;
      case 'view_transactions':
        _showTransactionsDialog(accountType, accountName);
        break;
      case 'transfer':
        _showTransferDialog(accountType, accountName, currentBalance);
        break;
    }
  }
  
  String _getAccountTypeFromName(String accountName) {
    switch (accountName) {
      case 'Main Account':
        return 'main';
      case 'Sparkonto':
        return 'sparkonto';
      case 'Cash on Hand':
        return 'cash_on_hand';
      case 'Cash Account':
        return 'cash_account';
      case 'Aktien':
        return 'aktien';
      case 'Fonds':
        return 'fonds';
      default:
        return accountName.toLowerCase().replaceAll(' ', '_');
    }
  }
  
  void _showEnhancedSetBalanceDialog(String accountType, String accountName, double currentBalance) {
    final balanceController = TextEditingController(text: currentBalance.toStringAsFixed(2));
    final descriptionController = TextEditingController();
    String adjustmentType = 'set'; // 'set', 'add', 'subtract'
    DateTime selectedDate = DateTime.now(); // Date when balance was/will be set

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Adjust $accountName'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Balance: €${currentBalance.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                
                // Adjustment Type Selection
                const Text('Adjustment Type:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Set Balance', style: TextStyle(fontSize: 12)),
                        value: 'set',
                        groupValue: adjustmentType,
                        onChanged: (value) => setState(() => adjustmentType = value!),
                        dense: true,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Add Amount', style: TextStyle(fontSize: 12)),
                        value: 'add',
                        groupValue: adjustmentType,
                        onChanged: (value) => setState(() => adjustmentType = value!),
                        dense: true,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Subtract', style: TextStyle(fontSize: 12)),
                        value: 'subtract',
                        groupValue: adjustmentType,
                        onChanged: (value) => setState(() => adjustmentType = value!),
                        dense: true,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Amount Input
                TextField(
                  controller: balanceController,
                  decoration: InputDecoration(
                    labelText: adjustmentType == 'set' ? 'New Balance (€)' : 'Amount (€)',
                    hintText: '0.00',
                    prefixIcon: Icon(
                      adjustmentType == 'add' ? Icons.add : 
                      adjustmentType == 'subtract' ? Icons.remove : Icons.account_balance_wallet
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                
                const SizedBox(height: 16),
                
                // Description Input
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Manual adjustment, correction, etc.',
                    prefixIcon: Icon(Icons.note),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Date Selection
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Balance Date'),
                    subtitle: Text(
                      'When was this balance effective: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                        helpText: 'Select when this balance was effective',
                      );
                      if (pickedDate != null) {
                        setState(() => selectedDate = pickedDate);
                      }
                    },
                  ),
                ),
                
                if (adjustmentType != 'set') ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'New balance will be: €${_calculateNewBalance(currentBalance, adjustmentType, balanceController.text).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(balanceController.text);
                if (amount == null) return;
                
                final newBalance = adjustmentType == 'set' ? amount : 
                                   _calculateNewBalance(currentBalance, adjustmentType, balanceController.text);
                
                Navigator.of(context).pop();
                
                final provider = Provider.of<FinancialProvider>(context, listen: false);
                final success = await provider.setAccountBalance(
                  accountType, 
                  newBalance, 
                  manualBalanceDate: '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}'
                );
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$accountName balance updated to €${newBalance.toStringAsFixed(2)}!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to update balance')),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
  
  double _calculateNewBalance(double currentBalance, String adjustmentType, String amountText) {
    final amount = double.tryParse(amountText) ?? 0.0;
    switch (adjustmentType) {
      case 'add':
        return currentBalance + amount;
      case 'subtract':
        return currentBalance - amount;
      default:
        return amount;
    }
  }
  
  void _showImportCsvDialog(String accountType, String accountName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Import CSV for $accountName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.upload_file, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              'Import bank transactions from CSV file for $accountName.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Supported formats:\n• Raiffeisen Bank CSV\n• Standard bank exports',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Close the account management dialog and trigger CSV import
              Navigator.of(context).pop();
              _triggerCsvImport(accountType);
            },
            child: const Text('Select CSV File'),
          ),
        ],
      ),
    );
  }
  
  void _triggerCsvImport(String accountType) {
    // This would trigger the CSV import functionality
    // For now, show a message that this would import
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV import for $accountType would be triggered here')),
    );
  }
  
  void _showTransactionsDialog(String accountType, String accountName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$accountName Transactions'),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.list_alt, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Transaction history would be displayed here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Future enhancement: Filter by date, category, amount, etc.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _showTransferDialog(String fromAccountType, String fromAccountName, double currentBalance) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    String toAccountType = 'main';
    
    // Get available account types for transfer
    final availableAccounts = ['main', 'sparkonto', 'cash_on_hand', 'cash_account', 'aktien', 'fonds']
        .where((account) => account != fromAccountType)
        .toList();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Transfer from $fromAccountName'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available Balance: €${currentBalance.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.green),
                ),
                const SizedBox(height: 16),
                
                // To Account Selection
                DropdownButtonFormField<String>(
                  value: toAccountType,
                  decoration: const InputDecoration(
                    labelText: 'Transfer To',
                    prefixIcon: Icon(Icons.arrow_forward),
                  ),
                  items: availableAccounts.map((account) => DropdownMenuItem(
                    value: account,
                    child: Text(_getAccountDisplayName(account)),
                  )).toList(),
                  onChanged: (value) => setState(() => toAccountType = value!),
                ),
                
                const SizedBox(height: 16),
                
                // Amount Input
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Transfer Amount (€)',
                    hintText: '0.00',
                    prefixIcon: Icon(Icons.euro),
                  ),
                  keyboardType: TextInputType.number,
                ),
                
                const SizedBox(height: 16),
                
                // Description Input
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Transfer description',
                    prefixIcon: Icon(Icons.note),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Quick Amount Buttons
                const Text('Quick Amounts:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [100, 500, 1000, 5000].map((amount) => 
                    OutlinedButton(
                      onPressed: () => amountController.text = amount.toString(),
                      child: Text('€$amount'),
                    ),
                  ).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) return;
                if (amount > currentBalance) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Insufficient balance for transfer')),
                  );
                  return;
                }
                
                Navigator.of(context).pop();
                
                // This would call a transfer API
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Transfer of €${amount.toStringAsFixed(2)} from $fromAccountName to ${_getAccountDisplayName(toAccountType)} would be processed')),
                );
              },
              child: const Text('Transfer'),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getAccountDisplayName(String accountType) {
    switch (accountType) {
      case 'main':
        return 'Main Account';
      case 'sparkonto':
        return 'Sparkonto';
      case 'cash_on_hand':
        return 'Cash on Hand';
      case 'cash_account':
        return 'Cash Account';
      case 'aktien':
        return 'Aktien';
      case 'fonds':
        return 'Fonds';
      default:
        return accountType;
    }
  }

  void _showAddSecurityDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _AddSecurityDialog(),
    );
  }
}

class _SecurityDialogHelpers {
  static void deleteSecurity(BuildContext context, String securityId, String symbol, FinancialProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Security'),
        content: Text('Are you sure you want to delete $symbol from your portfolio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              final success = await provider.deleteSecurity(securityId);
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$symbol deleted successfully!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to delete security')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  static void showSecurityHistory(BuildContext context, Map<String, dynamic> security) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${security['symbol']} Price History'),
        content: Container(
          width: double.maxFinite,
          height: 200,
          child: const Center(
            child: Text(
              'Price history chart would be displayed here.\nIntegrate with real financial API for live data.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
} 

class _AddSecurityDialog extends StatefulWidget {
  const _AddSecurityDialog({Key? key}) : super(key: key);

  @override
  _AddSecurityDialogState createState() => _AddSecurityDialogState();
}

class _AddSecurityDialogState extends State<_AddSecurityDialog> {
  final _symbolController = TextEditingController();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _dateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _lookupSuggestions = [];
  bool _isSearching = false;
  String? _searchError;

  @override
  void dispose() {
    _symbolController.dispose();
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _dateController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _lookupSuggestions = [];
        _searchError = null;
      });
      return;
    }

    // Start search - show loading
    setState(() {
      _isSearching = true;
      _lookupSuggestions = [];
      _searchError = null;
    });

    try {
      final provider = Provider.of<FinancialProvider>(context, listen: false);
      final suggestions = await provider.lookupSecurity(query);

      // Finished - show results
      if (mounted) {
        setState(() {
          _isSearching = false;
          _lookupSuggestions = suggestions;
          _searchError = suggestions.isEmpty ? "No stocks found for '$query'" : null;
        });
      }
    } catch (e) {
      // Error - show error message
      if (mounted) {
        setState(() {
          _isSearching = false;
          _lookupSuggestions = [];
          _searchError = 'Search failed';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Security/Wertpapier'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Security',
                hintText: 'e.g., "nvidia", "apple", "bitcoin"',
                errorText: _searchError,
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () => _performSearch(_searchController.text.trim()),
                      ),
              ),
              onSubmitted: (value) => _performSearch(value.trim()),
            ),
            if (_lookupSuggestions.isNotEmpty)
              SizedBox(
                height: 150,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _lookupSuggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _lookupSuggestions[index];
                    return ListTile(
                      title: Text(suggestion['name'] ?? 'N/A'),
                      subtitle: Text(suggestion['symbol'] ?? 'N/A'),
                      onTap: () {
                        setState(() {
                          _symbolController.text = suggestion['symbol'] ?? '';
                          _nameController.text = suggestion['name'] ?? '';
                          _lookupSuggestions = [];
                          _searchController.clear();
                          _searchError = null;
                        });
                      },
                    );
                  },
                ),
              ),
            TextField(
              controller: _symbolController,
              decoration: const InputDecoration(labelText: 'Symbol/Ticker'),
            ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Purchase Price'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(labelText: 'Purchase Date'),
              readOnly: true,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final provider = Provider.of<FinancialProvider>(context, listen: false);
            final success = await provider.addSecurity(
              _symbolController.text,
              _nameController.text,
              double.tryParse(_quantityController.text) ?? 0,
              double.tryParse(_priceController.text) ?? 0,
              _dateController.text,
            );
            if (success) {
              Navigator.of(context).pop();
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

// Separate widget to isolate dialog content from provider rebuilds
class _AccountManagementContent extends StatefulWidget {
  const _AccountManagementContent({Key? key}) : super(key: key);

  @override
  State<_AccountManagementContent> createState() => _AccountManagementContentState();
}

class _AccountManagementContentState extends State<_AccountManagementContent> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _userAccounts = [];
  List<Map<String, dynamic>> _securities = [];

  @override
  void initState() {
    super.initState();
    // Load data after the current build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final provider = Provider.of<FinancialProvider>(context, listen: false);
      
      // Just get the current data snapshot without triggering loads
      if (mounted) {
        setState(() {
          _userAccounts = List.from(provider.userAccounts);
          _securities = List.from(provider.securities);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load account data: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading account data...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      );
    }

    // Show error state
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading data',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      );
    }

    // Show content - this is now isolated from provider rebuilds
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add New Account Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showAddAccountDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add New Account'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // User Accounts Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.surfaceGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User Accounts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Create and manage your custom accounts',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              
              if (_userAccounts.isNotEmpty) ...[
                ..._userAccounts.map((account) => _buildUserAccountCard(account)),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Text(
                    'No user accounts created yet. Add your first account above.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Securities Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.surfaceGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Securities Portfolio',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Track your stocks, ETFs, and investments',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddSecurityDialog(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Security'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              if (_securities.isNotEmpty) ...[
                ..._securities.map((security) => _buildSecurityCard(security)),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Text(
                    'No securities added yet. Add your stocks, ETFs, or crypto to track their performance.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Helper methods - these are copies from the original dialog but without provider rebuilds
  void _showAddSecurityDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _AddSecurityDialog(),
    );
  }

  Widget _buildUserAccountCard(Map<String, dynamic> account) {
    // Implementation here
    return Container();
  }

  Widget _buildSecurityCard(Map<String, dynamic> security) {
    // Implementation here  
    return Container();
  }

  void _showAddAccountDialog(BuildContext context) {
    // Simple placeholder dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Account'),
          content: const Text('Account creation feature coming soon!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

