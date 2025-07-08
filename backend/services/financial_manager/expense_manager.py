"""
Expense Manager
Handles expense tracking and categorization
"""

import json
import os
from datetime import datetime
from typing import Dict, List, Optional
from dataclasses import dataclass, asdict

@dataclass
class Expense:
    """Expense entry"""
    id: str
    amount: float
    date: str
    category: str
    description: str
    receipt_path: Optional[str]
    is_tax_deductible: bool
    created_at: str

class ExpenseManager:
    """Manages expenses with Austrian tax categories"""
    
    def __init__(self, data_directory: str):
        self.data_dir = data_directory
        self.expenses_file = os.path.join(data_directory, 'expenses.json')
        self.expenses = self._load_expenses()
        
        # Austrian business expense categories
        self.categories = {
            "office_supplies": {"name": "Office Supplies", "deductible": True},
            "travel": {"name": "Business Travel", "deductible": True},
            "meals": {"name": "Business Meals", "deductible": True},
            "equipment": {"name": "Equipment", "deductible": True},
            "software": {"name": "Software/Subscriptions", "deductible": True},
            "marketing": {"name": "Marketing", "deductible": True},
            "professional_services": {"name": "Professional Services", "deductible": True},
            "rent": {"name": "Office Rent", "deductible": True},
            "utilities": {"name": "Utilities", "deductible": True},
            "insurance": {"name": "Business Insurance", "deductible": True},
            "education": {"name": "Education/Training", "deductible": True},
            "personal": {"name": "Personal", "deductible": False},
            "other": {"name": "Other", "deductible": False}
        }
    
    def _load_expenses(self) -> List[Expense]:
        """Load expenses from file"""
        if not os.path.exists(self.expenses_file):
            return []
        
        try:
            with open(self.expenses_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                return [Expense(**item) for item in data]
        except (json.JSONDecodeError, TypeError):
            return []
    
    def _save_expenses(self):
        """Save expenses to file"""
        with open(self.expenses_file, 'w', encoding='utf-8') as f:
            json.dump([asdict(expense) for expense in self.expenses], f, indent=2, ensure_ascii=False)
    
    def add_expense(self, amount: float, date: str, category: str, description: str, receipt_path: str = None) -> bool:
        """Add expense entry"""
        try:
            datetime.strptime(date, '%Y-%m-%d')
            
            is_deductible = self.categories.get(category, {}).get("deductible", False)
            
            expense = Expense(
                id=f"exp_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{len(self.expenses)}",
                amount=round(amount, 2),
                date=date,
                category=category,
                description=description,
                receipt_path=receipt_path,
                is_tax_deductible=is_deductible,
                created_at=datetime.now().isoformat()
            )
            
            self.expenses.append(expense)
            self._save_expenses()
            return True
            
        except (ValueError, TypeError) as e:
            print(f"Error adding expense: {e}")
            return False
    
    def get_total_expenses(self, year: int) -> float:
        """Get total expenses for year"""
        total = sum(exp.amount for exp in self.expenses if exp.date.startswith(str(year)))
        return round(total, 2)
    
    def get_monthly_expenses(self, year: int, month: int) -> float:
        """Get expenses for specific month"""
        year_month = f"{year}-{month:02d}"
        total = sum(exp.amount for exp in self.expenses if exp.date.startswith(year_month))
        return round(total, 2)
    
    def get_deductible_expenses(self, year: int) -> float:
        """Get tax-deductible expenses for year"""
        total = sum(exp.amount for exp in self.expenses 
                   if exp.date.startswith(str(year)) and exp.is_tax_deductible)
        return round(total, 2)
    
    def get_expenses_by_category(self, year: int) -> Dict[str, float]:
        """Get expenses grouped by category"""
        category_totals = {}
        for expense in self.expenses:
            if expense.date.startswith(str(year)):
                if expense.category not in category_totals:
                    category_totals[expense.category] = 0
                category_totals[expense.category] += expense.amount
        
        return {k: round(v, 2) for k, v in category_totals.items()}
    
    def export_data(self, year: int = None) -> Dict:
        """Export expense data"""
        if year:
            expenses_data = [asdict(exp) for exp in self.expenses if exp.date.startswith(str(year))]
        else:
            expenses_data = [asdict(exp) for exp in self.expenses]
        
        return {
            "expenses": expenses_data,
            "summary": {
                "total_expenses": sum(item["amount"] for item in expenses_data),
                "deductible_expenses": sum(item["amount"] for item in expenses_data if item["is_tax_deductible"]),
                "categories": self.categories
            }
        } 