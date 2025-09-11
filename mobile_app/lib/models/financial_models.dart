import 'package:json_annotation/json_annotation.dart';

part 'financial_models.g.dart';

@JsonSerializable()
class FinancialSummary {
  @JsonKey(name: 'total_employment_income')
  final double totalEmploymentIncome;
  
  @JsonKey(name: 'total_self_employment_income') 
  final double totalSelfEmploymentIncome;
  
  @JsonKey(name: 'total_expenses')
  final double totalExpenses;
  
  @JsonKey(name: 'total_tax_liability')
  final double totalTaxLiability;
  
  @JsonKey(name: 'construction_budget_used')
  final double constructionBudgetUsed;
  
  @JsonKey(name: 'construction_budget_remaining')
  final double constructionBudgetRemaining;
  
  @JsonKey(name: 'net_balance')
  final double netBalance;
  
  @JsonKey(name: 'monthly_cash_flow')
  final double monthlyCashFlow;

  @JsonKey(name: 'main_account_balance')
  final double mainAccountBalance;

  @JsonKey(name: 'sparkonto_balance')
  final double sparkontoBalance;

  @JsonKey(name: 'cash_on_hand')
  final double cashOnHand;

  @JsonKey(name: 'total_transfers_from_sparkonto')
  final double totalTransfersFromSparkonto;

  @JsonKey(name: 'cash_account_balance')
  final double cashAccountBalance;

  @JsonKey(name: 'aktien_balance')
  final double aktienBalance;

  @JsonKey(name: 'fonds_balance')
  final double fondsBalance;

  @JsonKey(name: 'total_investment_value')
  final double totalInvestmentValue;

  FinancialSummary({
    required this.totalEmploymentIncome,
    required this.totalSelfEmploymentIncome,
    required this.totalExpenses,
    required this.totalTaxLiability,
    required this.constructionBudgetUsed,
    required this.constructionBudgetRemaining,
    required this.netBalance,
    required this.monthlyCashFlow,
    required this.mainAccountBalance,
    required this.sparkontoBalance,
    required this.cashOnHand,
    required this.totalTransfersFromSparkonto,
    required this.cashAccountBalance,
    required this.aktienBalance,
    required this.fondsBalance,
    required this.totalInvestmentValue,
  });

  // Computed properties for convenience
  double get totalIncome => totalEmploymentIncome + totalSelfEmploymentIncome;
  double get netIncome => totalIncome - totalExpenses - totalTaxLiability;

  factory FinancialSummary.fromJson(Map<String, dynamic> json) => _$FinancialSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$FinancialSummaryToJson(this);
}

@JsonSerializable()
class IncomeEntry {
  final String id;
  final String type; // 'employment' or 'self_employment'
  final double amount;
  final String description;
  final DateTime date;
  final String? employer;
  final String? category;

  IncomeEntry({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    this.employer,
    this.category,
  });

  factory IncomeEntry.fromJson(Map<String, dynamic> json) => _$IncomeEntryFromJson(json);
  Map<String, dynamic> toJson() => _$IncomeEntryToJson(this);
}

@JsonSerializable()
class ExpenseEntry {
  final String id;
  final String category;
  final double amount;
  final String description;
  final DateTime date;
  final bool isBusinessExpense;
  final String? receiptPath;

  ExpenseEntry({
    required this.id,
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
    required this.isBusinessExpense,
    this.receiptPath,
  });

  factory ExpenseEntry.fromJson(Map<String, dynamic> json) => _$ExpenseEntryFromJson(json);
  Map<String, dynamic> toJson() => _$ExpenseEntryToJson(this);
}

@JsonSerializable()
class TransactionDetail {
  final String id;
  final String date;
  final double amount;
  final String description;
  final String category;
  @JsonKey(name: 'account_from')
  final String accountFrom;
  @JsonKey(name: 'account_to')
  final String accountTo;
  @JsonKey(name: 'transaction_type')
  final String transactionType;
  @JsonKey(name: 'is_transfer')
  final bool isTransfer;
  @JsonKey(name: 'created_at')
  final String createdAt;

  TransactionDetail({
    required this.id,
    required this.date,
    required this.amount,
    required this.description,
    required this.category,
    required this.accountFrom,
    required this.accountTo,
    required this.transactionType,
    required this.isTransfer,
    required this.createdAt,
  });

  factory TransactionDetail.fromJson(Map<String, dynamic> json) => _$TransactionDetailFromJson(json);
  Map<String, dynamic> toJson() => _$TransactionDetailToJson(this);
}

@JsonSerializable()
class ConstructionBudget {
  final double totalBudget;
  final double usedBudget;
  final double remainingBudget;
  final double loanAmount;
  final double interestRate;
  final int loanTermMonths;
  final double monthlyPayment;
  final List<ConstructionExpense> expenses;

  ConstructionBudget({
    required this.totalBudget,
    required this.usedBudget,
    required this.remainingBudget,
    required this.loanAmount,
    required this.interestRate,
    required this.loanTermMonths,
    required this.monthlyPayment,
    required this.expenses,
  });

  factory ConstructionBudget.fromJson(Map<String, dynamic> json) => _$ConstructionBudgetFromJson(json);
  Map<String, dynamic> toJson() => _$ConstructionBudgetToJson(this);
}

@JsonSerializable()
class ConstructionExpense {
  final String id;
  final String category;
  final double amount;
  final String description;
  final DateTime date;
  final String? contractor;
  final String? receiptPath;

  ConstructionExpense({
    required this.id,
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
    this.contractor,
    this.receiptPath,
  });

  factory ConstructionExpense.fromJson(Map<String, dynamic> json) => _$ConstructionExpenseFromJson(json);
  Map<String, dynamic> toJson() => _$ConstructionExpenseToJson(this);
}

@JsonSerializable()
class TaxReport {
  final double grossIncome;
  final double taxableIncome;
  final double incomeTax;
  final double socialSecurity;
  final double totalTax;
  final double netIncome;
  final List<TaxRecommendation> recommendations;

  TaxReport({
    required this.grossIncome,
    required this.taxableIncome,
    required this.incomeTax,
    required this.socialSecurity,
    required this.totalTax,
    required this.netIncome,
    required this.recommendations,
  });

  factory TaxReport.fromJson(Map<String, dynamic> json) => _$TaxReportFromJson(json);
  Map<String, dynamic> toJson() => _$TaxReportToJson(this);
}

@JsonSerializable()
class TaxRecommendation {
  final String title;
  final String description;
  final double potentialSavings;
  final String priority;

  TaxRecommendation({
    required this.title,
    required this.description,
    required this.potentialSavings,
    required this.priority,
  });

  factory TaxRecommendation.fromJson(Map<String, dynamic> json) => _$TaxRecommendationFromJson(json);
  Map<String, dynamic> toJson() => _$TaxRecommendationToJson(this);
} 