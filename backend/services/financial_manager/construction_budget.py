"""
Construction Budget Manager
Handles house construction loan and budget tracking
"""

import json
import os
from datetime import datetime
from typing import Dict, List, Optional
from dataclasses import dataclass, asdict

@dataclass
class ConstructionExpense:
    """Construction expense entry"""
    id: str
    amount: float
    date: str
    category: str
    vendor: str
    description: str
    receipt_path: Optional[str]
    created_at: str

class ConstructionBudgetManager:
    """Manages house construction budget and loan tracking"""
    
    def __init__(self, data_directory: str, loan_config: Dict):
        self.data_dir = data_directory
        self.expenses_file = os.path.join(data_directory, 'construction_expenses.json')
        self.loan_config = loan_config
        self.expenses = self._load_expenses()
        
        # Construction categories
        self.categories = {
            "foundation": "Foundation & Excavation",
            "structure": "Structural Work",
            "roofing": "Roofing",
            "electrical": "Electrical Work", 
            "plumbing": "Plumbing",
            "heating": "Heating/HVAC",
            "insulation": "Insulation",
            "drywall": "Drywall & Interior",
            "flooring": "Flooring",
            "windows": "Windows & Doors",
            "kitchen": "Kitchen",
            "bathroom": "Bathroom",
            "exterior": "Exterior Finishes",
            "landscaping": "Landscaping",
            "permits": "Permits & Fees",
            "other": "Other"
        }
    
    def _load_expenses(self) -> List[ConstructionExpense]:
        """Load construction expenses"""
        if not os.path.exists(self.expenses_file):
            return []
        
        try:
            with open(self.expenses_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                return [ConstructionExpense(**item) for item in data]
        except (json.JSONDecodeError, TypeError):
            return []
    
    def _save_expenses(self):
        """Save construction expenses"""
        with open(self.expenses_file, 'w', encoding='utf-8') as f:
            json.dump([asdict(expense) for expense in self.expenses], f, indent=2, ensure_ascii=False)
    
    def add_expense(self, amount: float, date: str, category: str, vendor: str, description: str, receipt_path: str = None) -> bool:
        """Add construction expense"""
        try:
            datetime.strptime(date, '%Y-%m-%d')
            
            expense = ConstructionExpense(
                id=f"const_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{len(self.expenses)}",
                amount=round(amount, 2),
                date=date,
                category=category,
                vendor=vendor,
                description=description,
                receipt_path=receipt_path,
                created_at=datetime.now().isoformat()
            )
            
            self.expenses.append(expense)
            self._save_expenses()
            return True
            
        except (ValueError, TypeError) as e:
            print(f"Error adding construction expense: {e}")
            return False
    
    def get_total_spent(self) -> float:
        """Get total construction spending"""
        total = sum(exp.amount for exp in self.expenses)
        return round(total, 2)
    
    def get_remaining_budget(self) -> float:
        """Get remaining construction budget"""
        total_budget = self.loan_config.get('total_amount', 0)
        spent = self.get_total_spent()
        return round(total_budget - spent, 2)
    
    def get_monthly_spending(self, year: int, month: int) -> float:
        """Get construction spending for specific month"""
        year_month = f"{year}-{month:02d}"
        total = sum(exp.amount for exp in self.expenses if exp.date.startswith(year_month))
        return round(total, 2)
    
    def get_spending_by_category(self) -> Dict[str, float]:
        """Get spending grouped by category"""
        category_totals = {}
        for expense in self.expenses:
            if expense.category not in category_totals:
                category_totals[expense.category] = 0
            category_totals[expense.category] += expense.amount
        
        return {k: round(v, 2) for k, v in category_totals.items()}
    
    def get_budget_status(self) -> Dict:
        """Get comprehensive budget status"""
        total_budget = self.loan_config.get('total_amount', 0)
        total_spent = self.get_total_spent()
        remaining = total_budget - total_spent
        
        percentage_used = (total_spent / total_budget * 100) if total_budget > 0 else 0
        
        return {
            "total_budget": total_budget,
            "total_spent": round(total_spent, 2),
            "remaining_budget": round(remaining, 2),
            "percentage_used": round(percentage_used, 2),
            "is_over_budget": total_spent > total_budget,
            "loan_info": self.loan_config
        }
    
    def update_loan_config(self, loan_config: Dict):
        """Update loan configuration"""
        self.loan_config = loan_config
    
    def export_data(self, year: int = None) -> Dict:
        """Export construction data"""
        if year:
            expenses_data = [asdict(exp) for exp in self.expenses if exp.date.startswith(str(year))]
        else:
            expenses_data = [asdict(exp) for exp in self.expenses]
        
        return {
            "construction_expenses": expenses_data,
            "budget_status": self.get_budget_status(),
            "spending_by_category": self.get_spending_by_category(),
            "categories": self.categories
        } 