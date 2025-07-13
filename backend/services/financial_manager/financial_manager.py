"""
Main Financial Manager
Coordinates all financial operations and provides unified interface
"""

import json
import os
from datetime import datetime, date
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, asdict
from decimal import Decimal, ROUND_HALF_UP

@dataclass
class AccountBalance:
    """Account balance tracking"""
    account_type: str  # 'main', 'sparkonto', 'cash_on_hand', 'cash_account', 'aktien', 'fonds'
    balance: float
    last_updated: str

@dataclass
class TransactionDetail:
    """Detailed transaction information"""
    id: str
    date: str
    amount: float
    description: str
    category: str
    account_from: str  # 'main', 'sparkonto', 'cash_on_hand', 'cash_account', 'aktien', 'fonds', 'external'
    account_to: str    # 'main', 'sparkonto', 'cash_on_hand', 'cash_account', 'aktien', 'fonds', 'external'
    transaction_type: str  # 'income', 'expense', 'transfer', 'cash_withdrawal'
    is_transfer: bool  # True if it's a transfer between accounts
    created_at: str

@dataclass
class FinancialSummary:
    """Overall financial summary"""
    total_employment_income: float
    total_self_employment_income: float
    total_expenses: float
    total_tax_liability: float
    construction_budget_used: float
    construction_budget_remaining: float
    net_balance: float  # Changed from net_worth to net_balance
    monthly_cash_flow: float
    # New fields for account tracking
    main_account_balance: float
    sparkonto_balance: float
    cash_on_hand: float
    cash_account_balance: float
    aktien_balance: float
    fonds_balance: float
    total_transfers_from_sparkonto: float
    total_investment_value: float

@dataclass
class MonthlyReport:
    """Monthly financial report"""
    year: int
    month: int
    employment_income: float
    self_employment_income: float
    total_expenses: float
    construction_costs: float
    tax_liability: float
    net_income: float

class FinancialManager:
    """
    Main Financial Manager for Austrian tax-compliant financial tracking
    Handles employment income, self-employment, construction budget, and expenses
    """
    
    def __init__(self, data_directory: str = None):
        """Initialize Financial Manager"""
        self.data_dir = data_directory or os.path.join(os.path.dirname(__file__), '../../../data/financial')
        
        # Ensure data directory exists
        os.makedirs(self.data_dir, exist_ok=True)
        
        # Initialize sub-managers (will be imported later to avoid circular imports)
        self.income_tracker = None
        self.expense_manager = None
        self.tax_calculator = None
        self.construction_budget = None
        
        # Configuration
        self.config = self._load_config()
        
        # Transaction and account tracking
        self.transactions = self._load_transactions()
        self.account_balances = self._load_account_balances()
        
    def _load_config(self) -> Dict:
        """Load financial configuration"""
        config_path = os.path.join(self.data_dir, 'config.json')
        default_config = {
            "currency": "EUR",
            "tax_year": datetime.now().year,
            "austrian_tax_rates": {
                "income_tax_brackets": [
                    {"min": 0, "max": 11000, "rate": 0.0},
                    {"min": 11000, "max": 18000, "rate": 0.2},
                    {"min": 18000, "max": 31000, "rate": 0.32}, 
                    {"min": 31000, "max": 60000, "rate": 0.42},
                    {"min": 60000, "max": 90000, "rate": 0.48},
                    {"min": 90000, "max": 1000000, "rate": 0.5},
                    {"min": 1000000, "max": float('inf'), "rate": 0.55}
                ],
                "social_security_rate": 0.1812,  # Employee portion
                "social_security_max": 5550,      # Monthly max (2024)
                "self_employment_tax_rate": 0.2739  # SVA rate
            },
            "construction_loan": {
                "total_amount": 0,
                "interest_rate": 0.0,
                "loan_term_years": 0,
                "start_date": None
            }
        }
        
        if os.path.exists(config_path):
            with open(config_path, 'r', encoding='utf-8') as f:
                return {**default_config, **json.load(f)}
        
        # Save default config
        with open(config_path, 'w', encoding='utf-8') as f:
            json.dump(default_config, f, indent=2, ensure_ascii=False)
        
        return default_config
    
    def initialize_sub_managers(self):
        """Initialize sub-managers (called after imports are available)"""
        from .income_tracker import IncomeTracker
        from .expense_manager import ExpenseManager
        from .tax_calculator import AustrianTaxCalculator
        from .construction_budget import ConstructionBudgetManager
        
        self.income_tracker = IncomeTracker(self.data_dir)
        self.expense_manager = ExpenseManager(self.data_dir)
        self.tax_calculator = AustrianTaxCalculator(self.config['austrian_tax_rates'])
        self.construction_budget = ConstructionBudgetManager(
            self.data_dir, 
            self.config['construction_loan']
        )
    
    def _load_transactions(self) -> List[TransactionDetail]:
        """Load transaction history"""
        transactions_file = os.path.join(self.data_dir, 'transactions.json')
        if not os.path.exists(transactions_file):
            return []
        
        try:
            with open(transactions_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                return [TransactionDetail(**item) for item in data]
        except (json.JSONDecodeError, TypeError):
            return []
    
    def _save_transactions(self):
        """Save transaction history"""
        transactions_file = os.path.join(self.data_dir, 'transactions.json')
        with open(transactions_file, 'w', encoding='utf-8') as f:
            json.dump([asdict(transaction) for transaction in self.transactions], f, indent=2, ensure_ascii=False)
    
    def _load_account_balances(self) -> Dict[str, AccountBalance]:
        """Load account balances"""
        balances_file = os.path.join(self.data_dir, 'account_balances.json')
        if not os.path.exists(balances_file):
            # Initialize default balances
            default_balances = {
                'main': AccountBalance('main', 0.0, datetime.now().isoformat()),
                'sparkonto': AccountBalance('sparkonto', 0.0, datetime.now().isoformat()),
                'cash_on_hand': AccountBalance('cash_on_hand', 0.0, datetime.now().isoformat()),
                'cash_account': AccountBalance('cash_account', 17000.0, datetime.now().isoformat()),  # Initial €17,000
                'aktien': AccountBalance('aktien', 0.0, datetime.now().isoformat()),
                'fonds': AccountBalance('fonds', 0.0, datetime.now().isoformat())
            }
            self._save_account_balances(default_balances)
            return default_balances
        
        try:
            with open(balances_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                return {k: AccountBalance(**v) for k, v in data.items()}
        except (json.JSONDecodeError, TypeError):
            return {}
    
    def _save_account_balances(self, balances: Dict[str, AccountBalance] = None):
        """Save account balances"""
        balances_file = os.path.join(self.data_dir, 'account_balances.json')
        balances_to_save = balances or self.account_balances
        with open(balances_file, 'w', encoding='utf-8') as f:
            json.dump({k: asdict(v) for k, v in balances_to_save.items()}, f, indent=2, ensure_ascii=False)
    
    def get_financial_summary(self, year: int = None, month: int = None, start_date: str = None, end_date: str = None) -> FinancialSummary:
        """Get comprehensive financial summary with optional time period filtering"""
        if not self.income_tracker:
            self.initialize_sub_managers()
            
        year = year or datetime.now().year
        
        # Get income totals with time filtering
        if start_date and end_date:
            # Custom date range
            employment_income = self.income_tracker.get_employment_income_for_period(start_date, end_date)
            self_employment_income = self.income_tracker.get_self_employment_income_for_period(start_date, end_date)
            total_expenses = self.expense_manager.get_expenses_for_period(start_date, end_date)
        elif month:
            # Monthly filtering
            employment_income = self.income_tracker.get_employment_income_for_month(year, month)
            self_employment_income = self.income_tracker.get_self_employment_income_for_month(year, month)
            total_expenses = self.expense_manager.get_monthly_expenses(year, month)
        else:
            # Yearly filtering (default)
            employment_income = self.income_tracker.get_employment_total(year)
            self_employment_income = self.income_tracker.get_self_employment_total(year)
            total_expenses = self.expense_manager.get_total_expenses(year)
        
        # Calculate taxes (always annual for proper tax calculation)
        total_income = employment_income + self_employment_income
        tax_liability = self.tax_calculator.calculate_annual_tax(
            self.income_tracker.get_employment_total(year),
            self.income_tracker.get_self_employment_total(year)
        )
        
        # Construction budget status (always total, not time-filtered)
        construction_used = self.construction_budget.get_total_spent()
        construction_remaining = self.construction_budget.get_remaining_budget()
        
        # Net balance calculation (simplified: Income - Expenses, no tax)
        net_balance = total_income - total_expenses
        
        # Monthly cash flow (average based on net balance)
        if start_date and end_date:
            # Calculate months between dates for proper averaging
            from datetime import datetime as dt
            start_dt = dt.strptime(start_date, '%Y-%m-%d')
            end_dt = dt.strptime(end_date, '%Y-%m-%d')
            months = (end_dt.year - start_dt.year) * 12 + (end_dt.month - start_dt.month) + 1
            monthly_cash_flow = net_balance / months if months > 0 else 0
        elif month:
            monthly_cash_flow = net_balance  # Already monthly
        else:
            monthly_cash_flow = net_balance / 12 if net_balance else 0
        
        # Calculate account balances and transfers
        main_balance = self.account_balances.get('main', AccountBalance('main', 0.0, '')).balance
        sparkonto_balance = self.account_balances.get('sparkonto', AccountBalance('sparkonto', 0.0, '')).balance
        cash_on_hand_balance = self.account_balances.get('cash_on_hand', AccountBalance('cash_on_hand', 0.0, '')).balance
        cash_account_balance = self.account_balances.get('cash_account', AccountBalance('cash_account', 0.0, '')).balance
        aktien_balance = self.account_balances.get('aktien', AccountBalance('aktien', 0.0, '')).balance
        fonds_balance = self.account_balances.get('fonds', AccountBalance('fonds', 0.0, '')).balance
        
        # Calculate total transfers from Sparkonto to main account
        sparkonto_transfers = sum(
            t.amount for t in self.transactions 
            if t.account_from == 'sparkonto' and t.account_to == 'main' and t.is_transfer
        )
        
        # Calculate total investment value
        total_investment_value = aktien_balance + fonds_balance
        
        return FinancialSummary(
            total_employment_income=employment_income,
            total_self_employment_income=self_employment_income,
            total_expenses=total_expenses,
            total_tax_liability=tax_liability,
            construction_budget_used=construction_used,
            construction_budget_remaining=construction_remaining,
            net_balance=round(net_balance, 2),
            monthly_cash_flow=round(monthly_cash_flow, 2),
            main_account_balance=round(main_balance, 2),
            sparkonto_balance=round(sparkonto_balance, 2),
            cash_on_hand=round(cash_on_hand_balance, 2),
            cash_account_balance=round(cash_account_balance, 2),
            aktien_balance=round(aktien_balance, 2),
            fonds_balance=round(fonds_balance, 2),
            total_transfers_from_sparkonto=round(sparkonto_transfers, 2),
            total_investment_value=round(total_investment_value, 2)
        )
    
    def get_monthly_report(self, year: int, month: int) -> MonthlyReport:
        """Get detailed monthly financial report"""
        if not self.income_tracker:
            self.initialize_sub_managers()
            
        # Get monthly data
        employment_income = self.income_tracker.get_employment_income_for_month(year, month)
        self_employment_income = self.income_tracker.get_self_employment_income_for_month(year, month)
        total_expenses = self.expense_manager.get_monthly_expenses(year, month)
        construction_costs = self.construction_budget.get_monthly_spending(year, month)
        
        # Calculate monthly tax liability
        annual_income = self.income_tracker.get_employment_total(year) + self.income_tracker.get_self_employment_total(year)
        annual_tax = self.tax_calculator.calculate_annual_tax(
            self.income_tracker.get_employment_total(year),
            self.income_tracker.get_self_employment_total(year)
        )
        monthly_tax = annual_tax / 12
        
        # Net income
        total_income = employment_income + self_employment_income
        net_income = total_income - total_expenses - construction_costs - monthly_tax
        
        return MonthlyReport(
            year=year,
            month=month,
            employment_income=employment_income,
            self_employment_income=self_employment_income,
            total_expenses=total_expenses,
            construction_costs=construction_costs,
            tax_liability=monthly_tax,
            net_income=net_income
        )
    
    def add_employment_income(self, amount: float, date: str, employer: str, description: str = None) -> bool:
        """Add employment income entry"""
        if not self.income_tracker:
            self.initialize_sub_managers()
        return self.income_tracker.add_employment_income(amount, date, employer, description)
    
    def add_self_employment_income(self, amount: float, date: str, client: str, description: str, invoice_number: str = None) -> bool:
        """Add self-employment income entry"""
        if not self.income_tracker:
            self.initialize_sub_managers()
        return self.income_tracker.add_self_employment_income(amount, date, client, description, invoice_number)
    
    def add_expense(self, amount: float, date: str, category: str, description: str, receipt_path: str = None) -> bool:
        """Add expense entry"""
        if not self.expense_manager:
            self.initialize_sub_managers()
        return self.expense_manager.add_expense(amount, date, category, description, receipt_path)
    
    def add_construction_expense(self, amount: float, date: str, category: str, vendor: str, description: str, receipt_path: str = None) -> bool:
        """Add construction-related expense"""
        if not self.construction_budget:
            self.initialize_sub_managers()
        return self.construction_budget.add_expense(amount, date, category, vendor, description, receipt_path)
    
    def get_tax_report(self, year: int) -> Dict:
        """Generate comprehensive Austrian tax report"""
        if not self.tax_calculator:
            self.initialize_sub_managers()
            
        employment_income = self.income_tracker.get_employment_total(year)
        self_employment_income = self.income_tracker.get_self_employment_total(year)
        
        return self.tax_calculator.generate_tax_report(employment_income, self_employment_income, year)
    
    def export_data(self, year: int = None) -> Dict:
        """Export all financial data for backup or analysis"""
        if not self.income_tracker:
            self.initialize_sub_managers()
            
        year = year or datetime.now().year
        
        return {
            "export_date": datetime.now().isoformat(),
            "year": year,
            "summary": asdict(self.get_financial_summary(year)),
            "income_data": self.income_tracker.export_data(year),
            "expense_data": self.expense_manager.export_data(year),
            "construction_data": self.construction_budget.export_data(year),
            "tax_report": self.get_tax_report(year)
        }
    
    def update_construction_loan_config(self, total_amount: float, interest_rate: float, term_years: int, start_date: str):
        """Update construction loan configuration"""
        self.config['construction_loan'] = {
            "total_amount": total_amount,
            "interest_rate": interest_rate,
            "loan_term_years": term_years,
            "start_date": start_date
        }
        
        # Save updated config
        config_path = os.path.join(self.data_dir, 'config.json')
        with open(config_path, 'w', encoding='utf-8') as f:
            json.dump(self.config, f, indent=2, ensure_ascii=False)
            
        # Update construction budget manager
        if self.construction_budget:
            self.construction_budget.update_loan_config(self.config['construction_loan'])
    
    def add_transaction(self, amount: float, date: str, description: str, category: str, 
                       account_from: str, account_to: str, transaction_type: str) -> bool:
        """Add a detailed transaction record"""
        try:
            datetime.strptime(date, '%Y-%m-%d')
            
            is_transfer = account_from in ['main', 'sparkonto', 'cash_on_hand', 'cash_account', 'aktien', 'fonds'] and account_to in ['main', 'sparkonto', 'cash_on_hand', 'cash_account', 'aktien', 'fonds']
            
            transaction = TransactionDetail(
                id=f"txn_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{len(self.transactions)}",
                date=date,
                amount=round(amount, 2),
                description=description,
                category=category,
                account_from=account_from,
                account_to=account_to,
                transaction_type=transaction_type,
                is_transfer=is_transfer,
                created_at=datetime.now().isoformat()
            )
            
            self.transactions.append(transaction)
            self._save_transactions()
            
            # Update account balances for transfers
            if is_transfer:
                self._update_account_balance(account_from, -amount)
                self._update_account_balance(account_to, amount)
            
            return True
            
        except (ValueError, TypeError) as e:
            print(f"Error adding transaction: {e}")
            return False
    
    def _update_account_balance(self, account_type: str, amount: float):
        """Update account balance"""
        if account_type in self.account_balances:
            self.account_balances[account_type].balance += amount
            self.account_balances[account_type].last_updated = datetime.now().isoformat()
            self._save_account_balances()
    
    def record_sparkonto_transfer(self, amount: float, date: str, description: str) -> bool:
        """Record transfer from Sparkonto to main account"""
        return self.add_transaction(
            amount=amount,
            date=date,
            description=description,
            category='Transfer',
            account_from='sparkonto',
            account_to='main',
            transaction_type='transfer'
        )
    
    def record_cash_withdrawal(self, amount: float, date: str, description: str) -> bool:
        """Record cash withdrawal from main account"""
        return self.add_transaction(
            amount=amount,
            date=date,
            description=description,
            category='Cash Withdrawal',
            account_from='main',
            account_to='cash_on_hand',
            transaction_type='cash_withdrawal'
        )
    
    def record_cash_expense(self, amount: float, date: str, description: str, category: str = 'Construction') -> bool:
        """Record cash expense (e.g., construction worker payment)"""
        return self.add_transaction(
            amount=amount,
            date=date,
            description=description,
            category=category,
            account_from='cash_on_hand',
            account_to='external',
            transaction_type='expense'
        )
    
    def get_transactions_for_period(self, start_date: str = None, end_date: str = None, 
                                   year: int = None, month: int = None) -> List[TransactionDetail]:
        """Get transactions for a specific period"""
        filtered_transactions = []
        
        for transaction in self.transactions:
            if start_date and end_date:
                if start_date <= transaction.date <= end_date:
                    filtered_transactions.append(transaction)
            elif year and month:
                year_month = f"{year}-{month:02d}"
                if transaction.date.startswith(year_month):
                    filtered_transactions.append(transaction)
            elif year:
                if transaction.date.startswith(str(year)):
                    filtered_transactions.append(transaction)
            else:
                filtered_transactions.append(transaction)
        
        # Sort by date (newest first)
        filtered_transactions.sort(key=lambda x: x.date, reverse=True)
        return filtered_transactions
    
    def get_account_balance(self, account_type: str) -> float:
        """Get current balance for specific account"""
        return self.account_balances.get(account_type, AccountBalance(account_type, 0.0, '')).balance
    
    def set_account_balance(self, account_type: str, balance: float):
        """Set account balance (for initial setup or corrections)"""
        if account_type not in self.account_balances:
            self.account_balances[account_type] = AccountBalance(account_type, 0.0, datetime.now().isoformat())
        
        self.account_balances[account_type].balance = round(balance, 2)
        self.account_balances[account_type].last_updated = datetime.now().isoformat()
        self._save_account_balances()
    
    def record_investment_purchase(self, amount: float, date: str, investment_type: str, description: str) -> bool:
        """Record investment purchase (Aktien or Fonds)"""
        if investment_type not in ['aktien', 'fonds']:
            return False
        
        # Record the transaction from main account to investment
        success = self.add_transaction(
            amount=amount,
            date=date,
            description=description,
            category=f'{investment_type.title()} Purchase',
            account_from='main',
            account_to=investment_type,
            transaction_type='investment_purchase'
        )
        
        return success
    
    def record_investment_sale(self, amount: float, date: str, investment_type: str, description: str) -> bool:
        """Record investment sale (Aktien or Fonds)"""
        if investment_type not in ['aktien', 'fonds']:
            return False
        
        # Record the transaction from investment to main account
        success = self.add_transaction(
            amount=amount,
            date=date,
            description=description,
            category=f'{investment_type.title()} Sale',
            account_from=investment_type,
            account_to='main',
            transaction_type='investment_sale'
        )
        
        return success
    
    def update_investment_value(self, investment_type: str, new_value: float) -> bool:
        """Update investment value (for market value changes)"""
        if investment_type not in ['aktien', 'fonds']:
            return False
        
        self.set_account_balance(investment_type, new_value)
        return True
    
    def record_cash_account_transfer(self, amount: float, date: str, description: str, to_main: bool = True) -> bool:
        """Record transfer between cash account and main account"""
        if to_main:
            # Transfer from cash account to main account
            return self.add_transaction(
                amount=amount,
                date=date,
                description=description,
                category='Cash Account Transfer',
                account_from='cash_account',
                account_to='main',
                transaction_type='transfer'
            )
        else:
            # Transfer from main account to cash account
            return self.add_transaction(
                amount=amount,
                date=date,
                description=description,
                category='Cash Account Transfer',
                account_from='main',
                account_to='cash_account',
                transaction_type='transfer'
            ) 