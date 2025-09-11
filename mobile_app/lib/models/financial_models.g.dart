// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'financial_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FinancialSummary _$FinancialSummaryFromJson(
  Map<String, dynamic> json,
) => FinancialSummary(
  totalEmploymentIncome: (json['total_employment_income'] as num).toDouble(),
  totalSelfEmploymentIncome: (json['total_self_employment_income'] as num)
      .toDouble(),
  totalExpenses: (json['total_expenses'] as num).toDouble(),
  totalTaxLiability: (json['total_tax_liability'] as num).toDouble(),
  constructionBudgetUsed: (json['construction_budget_used'] as num).toDouble(),
  constructionBudgetRemaining: (json['construction_budget_remaining'] as num)
      .toDouble(),
  netBalance: (json['net_balance'] as num).toDouble(),
  monthlyCashFlow: (json['monthly_cash_flow'] as num).toDouble(),
  mainAccountBalance: (json['main_account_balance'] as num).toDouble(),
  sparkontoBalance: (json['sparkonto_balance'] as num).toDouble(),
  cashOnHand: (json['cash_on_hand'] as num).toDouble(),
  totalTransfersFromSparkonto: (json['total_transfers_from_sparkonto'] as num)
      .toDouble(),
  cashAccountBalance: (json['cash_account_balance'] as num).toDouble(),
  aktienBalance: (json['aktien_balance'] as num).toDouble(),
  fondsBalance: (json['fonds_balance'] as num).toDouble(),
  totalInvestmentValue: (json['total_investment_value'] as num).toDouble(),
);

Map<String, dynamic> _$FinancialSummaryToJson(FinancialSummary instance) =>
    <String, dynamic>{
      'total_employment_income': instance.totalEmploymentIncome,
      'total_self_employment_income': instance.totalSelfEmploymentIncome,
      'total_expenses': instance.totalExpenses,
      'total_tax_liability': instance.totalTaxLiability,
      'construction_budget_used': instance.constructionBudgetUsed,
      'construction_budget_remaining': instance.constructionBudgetRemaining,
      'net_balance': instance.netBalance,
      'monthly_cash_flow': instance.monthlyCashFlow,
      'main_account_balance': instance.mainAccountBalance,
      'sparkonto_balance': instance.sparkontoBalance,
      'cash_on_hand': instance.cashOnHand,
      'total_transfers_from_sparkonto': instance.totalTransfersFromSparkonto,
      'cash_account_balance': instance.cashAccountBalance,
      'aktien_balance': instance.aktienBalance,
      'fonds_balance': instance.fondsBalance,
      'total_investment_value': instance.totalInvestmentValue,
    };

IncomeEntry _$IncomeEntryFromJson(Map<String, dynamic> json) => IncomeEntry(
  id: json['id'] as String,
  type: json['type'] as String,
  amount: (json['amount'] as num).toDouble(),
  description: json['description'] as String,
  date: DateTime.parse(json['date'] as String),
  employer: json['employer'] as String?,
  category: json['category'] as String?,
);

Map<String, dynamic> _$IncomeEntryToJson(IncomeEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'amount': instance.amount,
      'description': instance.description,
      'date': instance.date.toIso8601String(),
      'employer': instance.employer,
      'category': instance.category,
    };

ExpenseEntry _$ExpenseEntryFromJson(Map<String, dynamic> json) => ExpenseEntry(
  id: json['id'] as String,
  category: json['category'] as String,
  amount: (json['amount'] as num).toDouble(),
  description: json['description'] as String,
  date: DateTime.parse(json['date'] as String),
  isBusinessExpense: json['isBusinessExpense'] as bool,
  receiptPath: json['receiptPath'] as String?,
);

Map<String, dynamic> _$ExpenseEntryToJson(ExpenseEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'category': instance.category,
      'amount': instance.amount,
      'description': instance.description,
      'date': instance.date.toIso8601String(),
      'isBusinessExpense': instance.isBusinessExpense,
      'receiptPath': instance.receiptPath,
    };

TransactionDetail _$TransactionDetailFromJson(Map<String, dynamic> json) =>
    TransactionDetail(
      id: json['id'] as String,
      date: json['date'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      category: json['category'] as String,
      accountFrom: json['account_from'] as String,
      accountTo: json['account_to'] as String,
      transactionType: json['transaction_type'] as String,
      isTransfer: json['is_transfer'] as bool,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$TransactionDetailToJson(TransactionDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date,
      'amount': instance.amount,
      'description': instance.description,
      'category': instance.category,
      'account_from': instance.accountFrom,
      'account_to': instance.accountTo,
      'transaction_type': instance.transactionType,
      'is_transfer': instance.isTransfer,
      'created_at': instance.createdAt,
    };

ConstructionBudget _$ConstructionBudgetFromJson(Map<String, dynamic> json) =>
    ConstructionBudget(
      totalBudget: (json['totalBudget'] as num).toDouble(),
      usedBudget: (json['usedBudget'] as num).toDouble(),
      remainingBudget: (json['remainingBudget'] as num).toDouble(),
      loanAmount: (json['loanAmount'] as num).toDouble(),
      interestRate: (json['interestRate'] as num).toDouble(),
      loanTermMonths: (json['loanTermMonths'] as num).toInt(),
      monthlyPayment: (json['monthlyPayment'] as num).toDouble(),
      expenses: (json['expenses'] as List<dynamic>)
          .map((e) => ConstructionExpense.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ConstructionBudgetToJson(ConstructionBudget instance) =>
    <String, dynamic>{
      'totalBudget': instance.totalBudget,
      'usedBudget': instance.usedBudget,
      'remainingBudget': instance.remainingBudget,
      'loanAmount': instance.loanAmount,
      'interestRate': instance.interestRate,
      'loanTermMonths': instance.loanTermMonths,
      'monthlyPayment': instance.monthlyPayment,
      'expenses': instance.expenses,
    };

ConstructionExpense _$ConstructionExpenseFromJson(Map<String, dynamic> json) =>
    ConstructionExpense(
      id: json['id'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      date: DateTime.parse(json['date'] as String),
      contractor: json['contractor'] as String?,
      receiptPath: json['receiptPath'] as String?,
    );

Map<String, dynamic> _$ConstructionExpenseToJson(
  ConstructionExpense instance,
) => <String, dynamic>{
  'id': instance.id,
  'category': instance.category,
  'amount': instance.amount,
  'description': instance.description,
  'date': instance.date.toIso8601String(),
  'contractor': instance.contractor,
  'receiptPath': instance.receiptPath,
};

TaxReport _$TaxReportFromJson(Map<String, dynamic> json) => TaxReport(
  grossIncome: (json['grossIncome'] as num).toDouble(),
  taxableIncome: (json['taxableIncome'] as num).toDouble(),
  incomeTax: (json['incomeTax'] as num).toDouble(),
  socialSecurity: (json['socialSecurity'] as num).toDouble(),
  totalTax: (json['totalTax'] as num).toDouble(),
  netIncome: (json['netIncome'] as num).toDouble(),
  recommendations: (json['recommendations'] as List<dynamic>)
      .map((e) => TaxRecommendation.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$TaxReportToJson(TaxReport instance) => <String, dynamic>{
  'grossIncome': instance.grossIncome,
  'taxableIncome': instance.taxableIncome,
  'incomeTax': instance.incomeTax,
  'socialSecurity': instance.socialSecurity,
  'totalTax': instance.totalTax,
  'netIncome': instance.netIncome,
  'recommendations': instance.recommendations,
};

TaxRecommendation _$TaxRecommendationFromJson(Map<String, dynamic> json) =>
    TaxRecommendation(
      title: json['title'] as String,
      description: json['description'] as String,
      potentialSavings: (json['potentialSavings'] as num).toDouble(),
      priority: json['priority'] as String,
    );

Map<String, dynamic> _$TaxRecommendationToJson(TaxRecommendation instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'potentialSavings': instance.potentialSavings,
      'priority': instance.priority,
    };
