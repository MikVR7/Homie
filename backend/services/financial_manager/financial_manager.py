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
    manual_balance_date: str = None  # Date when balance was manually set (for CSV import filtering)

@dataclass
class UserAccount:
    """User-created account"""
    id: str
    name: str
    account_type: str  # 'checking', 'savings', 'investment', 'cash'
    balance: float
    created_at: str
    last_updated: str

@dataclass
class Security:
    """Investment security (stock, ETF, crypto, etc.)"""
    id: str
    symbol: str  # e.g., 'AAPL', 'BTC-EUR', 'IWDA.AS'
    name: str
    quantity: float
    purchase_price: float
    current_price: float
    purchase_date: str  # Date when this specific lot was purchased
    last_price_update: str
    created_at: str

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
        
        # User account and securities tracking
        self.user_accounts = self._load_user_accounts()
        self.securities = self._load_securities()
    
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
                balances = {}
                for k, v in data.items():
                    # Handle backward compatibility for existing data without manual_balance_date
                    if 'manual_balance_date' not in v:
                        v['manual_balance_date'] = None
                    balances[k] = AccountBalance(**v)
                return balances
        except (json.JSONDecodeError, TypeError):
            return {}
    
    def _save_account_balances(self, balances: Dict[str, AccountBalance] = None):
        """Save account balances"""
        balances_file = os.path.join(self.data_dir, 'account_balances.json')
        balances_to_save = balances or self.account_balances
        with open(balances_file, 'w', encoding='utf-8') as f:
            json.dump({k: asdict(v) for k, v in balances_to_save.items()}, f, indent=2, ensure_ascii=False)
    
    def _load_user_accounts(self) -> Dict[str, UserAccount]:
        """Load user-created accounts"""
        accounts_file = os.path.join(self.data_dir, 'user_accounts.json')
        if not os.path.exists(accounts_file):
            return {}
        
        try:
            with open(accounts_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                return {k: UserAccount(**v) for k, v in data.items()}
        except (json.JSONDecodeError, TypeError):
            return {}
    
    def _save_user_accounts(self):
        """Save user-created accounts"""
        accounts_file = os.path.join(self.data_dir, 'user_accounts.json')
        with open(accounts_file, 'w', encoding='utf-8') as f:
            json.dump({k: asdict(v) for k, v in self.user_accounts.items()}, f, indent=2, ensure_ascii=False)
    
    def _load_securities(self) -> Dict[str, Security]:
        """Load securities portfolio"""
        securities_file = os.path.join(self.data_dir, 'securities.json')
        if not os.path.exists(securities_file):
            return {}
        
        try:
            with open(securities_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                securities = {}
                for k, v in data.items():
                    # Handle backward compatibility for existing data without purchase_date
                    if 'purchase_date' not in v:
                        v['purchase_date'] = v.get('created_at', datetime.now().strftime('%Y-%m-%d'))
                    securities[k] = Security(**v)
                return securities
        except (json.JSONDecodeError, TypeError):
            return {}
    
    def _save_securities(self):
        """Save securities portfolio"""
        securities_file = os.path.join(self.data_dir, 'securities.json')
        with open(securities_file, 'w', encoding='utf-8') as f:
            json.dump({k: asdict(v) for k, v in self.securities.items()}, f, indent=2, ensure_ascii=False)
    
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
    
    def set_account_balance(self, account_type: str, balance: float, manual_balance_date: str = None):
        """Set account balance (for initial setup or corrections)"""
        if account_type not in self.account_balances:
            self.account_balances[account_type] = AccountBalance(account_type, 0.0, datetime.now().isoformat())
        
        self.account_balances[account_type].balance = round(balance, 2)
        self.account_balances[account_type].last_updated = datetime.now().isoformat()
        
        # Set manual balance date (for CSV import filtering)
        if manual_balance_date:
            self.account_balances[account_type].manual_balance_date = manual_balance_date
        else:
            # If no date provided, use today's date
            self.account_balances[account_type].manual_balance_date = datetime.now().strftime('%Y-%m-%d')
            
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
    
    # User Account Management Methods
    def get_user_accounts(self) -> List[Dict]:
        """Get all user-created accounts"""
        accounts = []
        for account_id, account in self.user_accounts.items():
            accounts.append({
                'id': account.id,
                'name': account.name,
                'type': account.account_type,
                'balance': account.balance,
                'created_at': account.created_at,
                'last_updated': account.last_updated
            })
        return accounts
    
    def create_user_account(self, name: str, account_type: str, initial_balance: float = 0.0) -> bool:
        """Create a new user account"""
        try:
            import uuid
            account_id = str(uuid.uuid4())
            
            account = UserAccount(
                id=account_id,
                name=name,
                account_type=account_type,
                balance=round(initial_balance, 2),
                created_at=datetime.now().isoformat(),
                last_updated=datetime.now().isoformat()
            )
            
            self.user_accounts[account_id] = account
            self._save_user_accounts()
            
            # Record initial balance transaction if > 0
            if initial_balance > 0:
                self.add_transaction(
                    amount=initial_balance,
                    date=datetime.now().strftime('%Y-%m-%d'),
                    description=f'Initial balance for {name}',
                    category='Initial Balance',
                    account_from='external',
                    account_to=account_id,
                    transaction_type='initial_balance'
                )
            
            return True
            
        except Exception as e:
            print(f"Error creating user account: {e}")
            return False
    
    def delete_user_account(self, account_id: str) -> bool:
        """Delete a user account"""
        try:
            if account_id not in self.user_accounts:
                return False
            
            # Remove account
            del self.user_accounts[account_id]
            self._save_user_accounts()
            
            # TODO: Handle transactions related to this account
            # For now, we'll leave transactions as they are for data integrity
            
            return True
            
        except Exception as e:
            print(f"Error deleting user account: {e}")
            return False
    
    def update_user_account_balance(self, account_id: str, new_balance: float) -> bool:
        """Update user account balance"""
        try:
            if account_id not in self.user_accounts:
                return False
            
            self.user_accounts[account_id].balance = round(new_balance, 2)
            self.user_accounts[account_id].last_updated = datetime.now().isoformat()
            self._save_user_accounts()
            
            return True
            
        except Exception as e:
            print(f"Error updating user account balance: {e}")
            return False
    
    # Securities Management Methods
    def get_securities_portfolio(self) -> List[Dict]:
        """Get all securities in portfolio"""
        securities = []
        for security_id, security in self.securities.items():
            total_value = security.quantity * security.current_price
            gain_loss = (security.current_price - security.purchase_price) * security.quantity
            gain_loss_percent = ((security.current_price - security.purchase_price) / security.purchase_price * 100) if security.purchase_price > 0 else 0
            
            securities.append({
                'id': security.id,
                'symbol': security.symbol,
                'name': security.name,
                'quantity': security.quantity,
                'purchase_price': security.purchase_price,
                'current_price': security.current_price,
                'purchase_date': security.purchase_date,
                'total_value': total_value,
                'gain_loss': gain_loss,
                'gain_loss_percent': gain_loss_percent,
                'last_price_update': security.last_price_update,
                'created_at': security.created_at
            })
        return securities
    
    def add_security(self, symbol: str, name: str, quantity: float, purchase_price: float, purchase_date: str = None) -> bool:
        """Add a new security to portfolio (allows multiple purchases of same symbol)"""
        try:
            import uuid
            security_id = str(uuid.uuid4())
            
            # Use provided purchase_date or default to today
            if not purchase_date:
                purchase_date = datetime.now().strftime('%Y-%m-%d')
            
            # Fetch current price (initially set to purchase price)
            current_price = purchase_price  # We'll update this with real data later
            
            security = Security(
                id=security_id,
                symbol=symbol.upper(),
                name=name,
                quantity=quantity,
                purchase_price=purchase_price,
                current_price=current_price,
                purchase_date=purchase_date,
                last_price_update=datetime.now().isoformat(),
                created_at=datetime.now().isoformat()
            )
            
            self.securities[security_id] = security
            self._save_securities()
            
            return True
            
        except Exception as e:
            print(f"Error adding security: {e}")
            return False
    
    def delete_security(self, security_id: str) -> bool:
        """Delete a security from portfolio"""
        try:
            if security_id not in self.securities:
                return False
            
            # Remove security
            del self.securities[security_id]
            self._save_securities()
            
            return True
            
        except Exception as e:
            print(f"Error deleting security: {e}")
            return False
    
    def lookup_security_symbol(self, search_query: str) -> Dict:
        """Use AI to find correct security symbol/name from search query"""
        try:
            # Use the same AI service as file organizer
            api_key = os.getenv('GEMINI_API_KEY')
            if not api_key:
                return {
                    'success': False,
                    'error': 'AI service not available - GEMINI_API_KEY not configured',
                    'suggestions': []
                }
            
            import google.generativeai as genai
            genai.configure(api_key=api_key)
            model = genai.GenerativeModel('gemini-1.5-flash')
            
            prompt = f"""
You are a financial data expert. The user is searching for a security (stock, ETF, cryptocurrency, etc.) and wants to find the correct symbol.

USER SEARCH QUERY: "{search_query}"

Please help identify the most likely securities they're looking for. Consider:
- Company names (e.g., "nvidia" → NVDA)
- Popular stock symbols (e.g., "apple" → AAPL)
- ETFs (e.g., "msci world" → IWDA.AS or VTI)
- Cryptocurrencies (e.g., "bitcoin" → BTC-EUR)
- Austrian/European markets (Vienna Stock Exchange uses .VI suffix)

Return your response as JSON with this structure:
{{
    "suggestions": [
        {{
            "symbol": "NVDA",
            "name": "NVIDIA Corporation",
            "market": "NASDAQ",
            "type": "stock",
            "confidence": 95,
            "description": "Leading graphics processing unit manufacturer"
        }},
        {{
            "symbol": "BTC-EUR",
            "name": "Bitcoin",
            "market": "Crypto",
            "type": "cryptocurrency", 
            "confidence": 90,
            "description": "Largest cryptocurrency by market cap"
        }}
    ],
    "search_performed": "{search_query}",
    "total_suggestions": 2
}}

Provide 3-5 most relevant suggestions, ordered by confidence. Include Austrian/European options when relevant.
"""
            
            response = model.generate_content(prompt)
            json_text = response.text.strip()
            
            # Clean JSON response
            if json_text.startswith('```json'):
                json_text = json_text[7:]
            if json_text.endswith('```'):
                json_text = json_text[:-3]
            
            ai_response = json.loads(json_text.strip())
            
            return {
                'success': True,
                'suggestions': ai_response.get('suggestions', []),
                'search_query': search_query,
                'total_suggestions': len(ai_response.get('suggestions', []))
            }
            
        except Exception as e:
            print(f"Error in security lookup: {e}")
            # Fallback to basic suggestions based on common patterns
            fallback_suggestions = self._get_fallback_security_suggestions(search_query)
            return {
                'success': True,
                'suggestions': fallback_suggestions,
                'search_query': search_query,
                'total_suggestions': len(fallback_suggestions),
                'note': 'AI lookup failed, using fallback suggestions'
            }
    
    def _get_fallback_security_suggestions(self, search_query: str) -> List[Dict]:
        """Fallback security suggestions when AI fails"""
        query_lower = search_query.lower()
        suggestions = []
        
        # Common stock mappings
        stock_mappings = {
            'nvidia': {'symbol': 'NVDA', 'name': 'NVIDIA Corporation', 'market': 'NASDAQ'},
            'apple': {'symbol': 'AAPL', 'name': 'Apple Inc.', 'market': 'NASDAQ'},
            'microsoft': {'symbol': 'MSFT', 'name': 'Microsoft Corporation', 'market': 'NASDAQ'},
            'google': {'symbol': 'GOOGL', 'name': 'Alphabet Inc.', 'market': 'NASDAQ'},
            'tesla': {'symbol': 'TSLA', 'name': 'Tesla Inc.', 'market': 'NASDAQ'},
            'amazon': {'symbol': 'AMZN', 'name': 'Amazon.com Inc.', 'market': 'NASDAQ'},
            'bitcoin': {'symbol': 'BTC-EUR', 'name': 'Bitcoin', 'market': 'Crypto'},
            'ethereum': {'symbol': 'ETH-EUR', 'name': 'Ethereum', 'market': 'Crypto'},
        }
        
        # Check for direct matches
        for key, info in stock_mappings.items():
            if key in query_lower or query_lower in key:
                suggestions.append({
                    'symbol': info['symbol'],
                    'name': info['name'],
                    'market': info['market'],
                    'type': 'cryptocurrency' if 'Crypto' in info['market'] else 'stock',
                    'confidence': 80,
                    'description': f"Popular {info['market']} security"
                })
        
        # If no matches, suggest to search manually
        if not suggestions:
            suggestions.append({
                'symbol': search_query.upper(),
                'name': f"Manual entry: {search_query}",
                'market': 'Unknown',
                'type': 'manual',
                'confidence': 30,
                'description': "Please verify this symbol manually"
            })
        
        return suggestions
    
    def get_security_current_price(self, symbol: str) -> Dict:
        """Get current price for a security from external API"""
        try:
            # For demo purposes, we'll return mock data
            # In production, integrate with Alpha Vantage, Yahoo Finance, or similar
            import random
            
            # Mock price data - replace with real API calls
            mock_prices = {
                'AAPL': 190.50,
                'MSFT': 410.20,
                'GOOGL': 140.75,
                'TSLA': 240.10,
                'BTC-EUR': 42000.00,
                'ETH-EUR': 2800.00,
                'IWDA.AS': 85.40,  # iShares Core MSCI World
            }
            
            base_price = mock_prices.get(symbol, 100.0)
            # Add some random variation (-5% to +5%)
            variation = random.uniform(-0.05, 0.05)
            current_price = base_price * (1 + variation)
            
            return {
                'symbol': symbol,
                'current_price': round(current_price, 2),
                'currency': 'EUR',
                'last_updated': datetime.now().isoformat(),
                'market_status': 'open'  # Mock status
            }
            
        except Exception as e:
            print(f"Error fetching price for {symbol}: {e}")
            return None
    
    def get_security_price_history(self, symbol: str, days: int = 30) -> List[Dict]:
        """Get price history for a security"""
        try:
            # Mock historical data - replace with real API calls
            import random
            from datetime import timedelta
            
            history = []
            base_price = 100.0
            current_date = datetime.now() - timedelta(days=days)
            
            for i in range(days):
                # Generate mock price movement
                change = random.uniform(-0.03, 0.03)  # -3% to +3% daily change
                base_price *= (1 + change)
                
                history.append({
                    'date': current_date.strftime('%Y-%m-%d'),
                    'price': round(base_price, 2),
                    'volume': random.randint(1000, 100000)
                })
                
                current_date += timedelta(days=1)
            
            return history
            
        except Exception as e:
            print(f"Error fetching price history for {symbol}: {e}")
            return []
    
    def update_security_price(self, symbol: str, new_price: float) -> bool:
        """Update current price for a security"""
        try:
            for security_id, security in self.securities.items():
                if security.symbol == symbol:
                    security.current_price = new_price
                    security.last_price_update = datetime.now().isoformat()
            
            self._save_securities()
            return True
            
        except Exception as e:
            print(f"Error updating security price: {e}")
            return False 