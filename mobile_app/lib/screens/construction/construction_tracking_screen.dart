import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';
import '../../models/construction_models.dart';
import '../../providers/construction_provider.dart';
import '../../widgets/construction/add_construction_expense_form.dart';
import '../../widgets/construction/add_planned_expense_form.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';

class ConstructionTrackingScreen extends StatefulWidget {
  const ConstructionTrackingScreen({Key? key}) : super(key: key);

  @override
  State<ConstructionTrackingScreen> createState() => _ConstructionTrackingScreenState();
}

class _ConstructionTrackingScreenState extends State<ConstructionTrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ConstructionPhaseType _selectedPhase = ConstructionPhaseType.foundation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Consumer<ConstructionProvider>(
            builder: (context, provider, child) {
              return Column(
                children: [
                  // Modern App Bar
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.construction,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Construction Tracking',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Text(
                                      provider.currentProject?.name ?? 'No project selected',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.8),
                                        fontWeight: FontWeight.w300,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Refresh Button
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.refresh, color: Colors.white),
                                  onPressed: () => provider.refresh(),
                                  tooltip: 'Refresh',
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Tab Bar
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.white.withOpacity(0.7),
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            tabs: const [
                              Tab(text: 'Overview'),
                              Tab(text: 'Real Costs'),
                              Tab(text: 'Planned'),
                              Tab(text: 'Analytics'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: provider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : provider.currentProject == null
                            ? _buildNoProjectView()
                            : Column(
                                children: [
                                  _buildProjectHeader(provider),
                                  _buildPhaseSelector(),
                                  Expanded(
                                    child: TabBarView(
                                      controller: _tabController,
                                      children: [
                                        _buildOverviewTab(provider),
                                        _buildRealCostsTab(provider),
                                        _buildPlannedCostsTab(provider),
                                        _buildAnalyticsTab(provider),
                                      ],
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
      floatingActionButton: Consumer<ConstructionProvider>(
        builder: (context, provider, child) {
          return provider.currentProject != null ? _buildSpeedDial(provider) : Container();
        },
      ),
    );
  }

  Widget _buildNoProjectView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No Construction Project Found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Create a construction project to start tracking costs',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectHeader(ConstructionProvider provider) {
    final project = provider.currentProject!;
    final progress = project.budgetUtilization;
    final remainingBudget = project.remainingBudget;
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        project.name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        project.description,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(project.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    project.status.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildBudgetCard(
                    'Total Budget',
                    '€${NumberFormat('#,##0').format(project.totalBudget)}',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildBudgetCard(
                    'Spent',
                    '€${NumberFormat('#,##0').format(project.totalSpent)}',
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildBudgetCard(
                    'Remaining',
                    '€${NumberFormat('#,##0').format(remainingBudget)}',
                    remainingBudget >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 90 ? Colors.red : progress > 75 ? Colors.orange : Colors.green,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${progress.toStringAsFixed(1)}% of budget used',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseSelector() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: ConstructionPhaseType.values.length,
        itemBuilder: (context, index) {
          final phase = ConstructionPhaseType.values[index];
          final isSelected = phase == _selectedPhase;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedPhase = phase;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected ? null : AppColors.surface,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? Colors.transparent : AppColors.onSurface.withOpacity(0.2),
                ),
              ),
              child: Center(
                child: Text(
                  phase.displayName,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBudgetCard(String title, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 12, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(ConstructionProvider provider) {
    final project = provider.currentProject!;
    final currentPhase = project.phases.firstWhere(
      (p) => p.type == _selectedPhase, 
      orElse: () => project.phases.first,
    );
    
          return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPhaseOverviewCard(currentPhase),
          const SizedBox(height: 16),
          _buildRecentActivityCard(provider),
          const SizedBox(height: 16),
          _buildQuickStatsCard(provider),
        ],
      );
  }

  Widget _buildPhaseOverviewCard(ConstructionPhase phase) {
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
                  phase.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(phase.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    phase.status.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              phase.description,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPhaseStatCard(
                    'Budget',
                    '€${NumberFormat('#,##0').format(phase.budget)}',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPhaseStatCard(
                    'Spent',
                    '€${NumberFormat('#,##0').format(phase.totalSpent)}',
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPhaseStatCard(
                    'Planned',
                    '€${NumberFormat('#,##0').format(phase.totalPlanned)}',
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: phase.phaseProgress / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                phase.phaseProgress > 100 ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${phase.phaseProgress.toStringAsFixed(1)}% of phase budget used',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseStatCard(String title, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 10, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard(ConstructionProvider provider) {
    final expenses = provider.getExpensesForPhase(_selectedPhase);
    final recentExpenses = expenses.take(5).toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (recentExpenses.isEmpty)
              const Text(
                'No recent expenses',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...recentExpenses.map((expense) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.withOpacity(0.2),
                      child: const Icon(Icons.receipt, color: Colors.orange),
                    ),
                    title: Text(expense.description),
                    subtitle: Text(
                      '${expense.category} • ${DateFormat('dd.MM.yyyy').format(expense.date)}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '€${NumberFormat('#,##0').format(expense.amount)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getPaymentStatusColor(expense.paymentStatus),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            expense.paymentStatus.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsCard(ConstructionProvider provider) {
    final expenses = provider.getExpensesForPhase(_selectedPhase);
    final plannedExpenses = provider.getPlannedExpensesForPhase(_selectedPhase);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Stats',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickStat(
                    'Total Expenses',
                    expenses.length.toString(),
                    Icons.receipt_long,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildQuickStat(
                    'Planned Items',
                    plannedExpenses.length.toString(),
                    Icons.schedule,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildQuickStat(
                    'Pending Payments',
                    expenses.where((e) => e.paymentStatus == 'pending').length.toString(),
                    Icons.pending_actions,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildQuickStat(
                    'High Priority',
                    plannedExpenses.where((p) => p.isHighPriority).length.toString(),
                    Icons.priority_high,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRealCostsTab(ConstructionProvider provider) {
    final expenses = provider.getExpensesForPhase(_selectedPhase);
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (expenses.isEmpty)
          const Center(
            child: Column(
              children: [
                SizedBox(height: 50),
                Icon(Icons.receipt_long, size: 60, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No expenses recorded yet',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                Text(
                  'Tap the + button to add your first expense',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          )
        else
          ...expenses.map((expense) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.withOpacity(0.2),
                    child: const Icon(Icons.receipt, color: Colors.orange),
                  ),
                  title: Text(expense.description),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${expense.category} • ${expense.subcategory}'),
                      Text('${expense.supplierName ?? 'Unknown Supplier'} • ${DateFormat('dd.MM.yyyy').format(expense.date)}'),
                      if (expense.invoiceNumber != null)
                        Text('Invoice: ${expense.invoiceNumber}'),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '€${NumberFormat('#,##0.00').format(expense.amount)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getPaymentStatusColor(expense.paymentStatus),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          expense.paymentStatus.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              )),
      ],
    );
  }

  Widget _buildPlannedCostsTab(ConstructionProvider provider) {
    final plannedExpenses = provider.getPlannedExpensesForPhase(_selectedPhase);
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (plannedExpenses.isEmpty)
          const Center(
            child: Column(
              children: [
                SizedBox(height: 50),
                Icon(Icons.schedule, size: 60, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No future expenses planned',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                Text(
                  'Plan your future costs to better manage your budget',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          )
        else
          ...plannedExpenses.map((planned) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getPriorityColor(planned.priority).withOpacity(0.2),
                    child: Icon(
                      _getPriorityIcon(planned.priority),
                      color: _getPriorityColor(planned.priority),
                    ),
                  ),
                  title: Text(planned.description),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${planned.category} • ${planned.subcategory}'),
                      if (planned.plannedDate != null)
                        Text('Planned: ${DateFormat('dd.MM.yyyy').format(planned.plannedDate!)}'),
                      if (planned.deadlineDate != null)
                        Text('Deadline: ${DateFormat('dd.MM.yyyy').format(planned.deadlineDate!)}'),
                      if (planned.supplierName?.isNotEmpty == true)
                        Text('Supplier: ${planned.supplierName}'),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '€${NumberFormat('#,##0').format(planned.estimatedCost)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (planned.minCost != null && planned.maxCost != null)
                        Text(
                          '€${NumberFormat('#,##0').format(planned.minCost!)} - €${NumberFormat('#,##0').format(planned.maxCost!)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(planned.priority),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          planned.priority.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              )),
      ],
    );
  }

  Widget _buildAnalyticsTab(ConstructionProvider provider) {
    final analytics = provider.getAnalytics();
    final costOverruns = provider.getCostOverruns();
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (costOverruns.isNotEmpty) ...[
          _buildCostOverrunsCard(costOverruns),
          const SizedBox(height: 16),
        ],
        _buildCategoryBreakdownCard(analytics),
        const SizedBox(height: 16),
        _buildCashFlowCard(analytics),
      ],
    );
  }

  Widget _buildCostOverrunsCard(List<Map<String, dynamic>> costOverruns) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cost Overruns',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...costOverruns.map((overrun) => ListTile(
                  leading: const Icon(Icons.warning, color: Colors.red),
                  title: Text(overrun['phase']),
                  subtitle: Text(
                    'Budget: €${NumberFormat('#,##0').format(overrun['budget'])} • '
                    'Actual: €${NumberFormat('#,##0').format(overrun['actual'])}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '+€${NumberFormat('#,##0').format(overrun['overrun'])}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '+${overrun['overrunPercentage'].toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdownCard(Map<String, dynamic> analytics) {
    final categoryBreakdown = analytics['categoryBreakdown'] as Map<String, dynamic>? ?? {};
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Spending by Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (categoryBreakdown.isEmpty)
              const Text(
                'No spending data available',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...categoryBreakdown.entries.map((entry) {
                final amount = entry.value as double;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getCategoryColor(entry.key).withOpacity(0.2),
                    child: Icon(
                      _getCategoryIcon(entry.key),
                      color: _getCategoryColor(entry.key),
                    ),
                  ),
                  title: Text(ConstructionCategories.getCategoryDisplayName(entry.key)),
                  trailing: Text(
                    '€${NumberFormat('#,##0').format(amount)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildCashFlowCard(Map<String, dynamic> analytics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Budget Health',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildHealthMetric(
                    'Budget Used',
                    '${(analytics['budgetUtilization'] ?? 0).toStringAsFixed(1)}%',
                    (analytics['budgetUtilization'] ?? 0) > 90 ? Colors.red : Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildHealthMetric(
                    'Projected Overrun',
                    '${(analytics['overrunPercentage'] ?? 0).toStringAsFixed(1)}%',
                    (analytics['overrunPercentage'] ?? 0) > 0 ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildHealthMetric(
                    'Completion',
                    '${(analytics['completionPercentage'] ?? 0).toStringAsFixed(1)}%',
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildHealthMetric(
                    'Days Remaining',
                    '${analytics['scheduleDaysRemaining'] ?? 0}',
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthMetric(String title, String value, Color color) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedDial(ConstructionProvider provider) {
    final selectedPhaseId = provider.currentProject?.phases
        .firstWhere((p) => p.type == _selectedPhase, orElse: () => provider.currentProject!.phases.first)
        .id ?? '';
    
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      backgroundColor: Colors.orange,
      foregroundColor: Colors.white,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.receipt_long),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          label: 'Add Real Expense',
                            onTap: () {
            if (selectedPhaseId.isNotEmpty) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddConstructionExpenseForm(
                    phaseId: selectedPhaseId,
                    onExpenseAdded: () => provider.refresh(),
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select a construction phase first')),
              );
            }
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.schedule),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          label: 'Plan Future Cost',
                            onTap: () {
            if (selectedPhaseId.isNotEmpty) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddPlannedExpenseForm(
                    phaseId: selectedPhaseId,
                    onPlannedExpenseAdded: () => provider.refresh(),
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select a construction phase first')),
              );
            }
          },
        ),
      ],
    );
  }

  // Helper methods for colors and icons
  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'delayed':
        return Colors.red;
      case 'paused':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'critical':
        return Icons.warning;
      case 'high':
        return Icons.priority_high;
      case 'medium':
        return Icons.schedule;
      case 'low':
        return Icons.low_priority;
      default:
        return Icons.help;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'foundation':
        return Colors.brown;
      case 'structure':
        return Colors.grey;
      case 'envelope':
        return Colors.blue;
      case 'mechanical':
        return Colors.green;
      case 'interior':
        return Colors.purple;
      case 'exterior':
        return Colors.orange;
      case 'permits_fees':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'foundation':
        return Icons.foundation;
      case 'structure':
        return Icons.apartment;
      case 'envelope':
        return Icons.home;
      case 'mechanical':
        return Icons.settings;
      case 'interior':
        return Icons.chair;
      case 'exterior':
        return Icons.landscape;
      case 'permits_fees':
        return Icons.gavel;
      default:
        return Icons.construction;
    }
  }
} 