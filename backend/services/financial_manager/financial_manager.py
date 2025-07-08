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
class FinancialSummary:
    """Overall financial summary"""
    total_employment_income: float
    total_self_employment_income: float
    total_expenses: float
    total_tax_liability: float
    construction_budget_used: float
    construction_budget_remaining: float
    net_worth: float
    monthly_cash_flow: float

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
    
    def get_financial_summary(self, year: int = None) -> FinancialSummary:
        """Get comprehensive financial summary"""
        if not self.income_tracker:
            self.initialize_sub_managers()
            
        year = year or datetime.now().year
        
        # Get income totals
        employment_income = self.income_tracker.get_employment_total(year)
        self_employment_income = self.income_tracker.get_self_employment_total(year)
        
        # Get expenses total
        total_expenses = self.expense_manager.get_total_expenses(year)
        
        # Calculate taxes
        total_income = employment_income + self_employment_income
        tax_liability = self.tax_calculator.calculate_annual_tax(
            employment_income, 
            self_employment_income
        )
        
        # Construction budget status
        construction_used = self.construction_budget.get_total_spent()
        construction_remaining = self.construction_budget.get_remaining_budget()
        
        # Net worth calculation
        net_income = total_income - total_expenses - tax_liability
        net_worth = net_income  # Simplified for now
        
        # Monthly cash flow (average)
        monthly_cash_flow = net_income / 12 if net_income else 0
        
        return FinancialSummary(
            total_employment_income=employment_income,
            total_self_employment_income=self_employment_income,
            total_expenses=total_expenses,
            total_tax_liability=tax_liability,
            construction_budget_used=construction_used,
            construction_budget_remaining=construction_remaining,
            net_worth=net_worth,
            monthly_cash_flow=monthly_cash_flow
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