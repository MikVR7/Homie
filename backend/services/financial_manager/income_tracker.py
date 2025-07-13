"""
Income Tracker
Handles employment and self-employment income tracking
"""

import json
import os
from datetime import datetime
from typing import Dict, List, Optional
from dataclasses import dataclass, asdict

@dataclass
class EmploymentIncome:
    """Employment income entry"""
    id: str
    amount: float
    date: str
    employer: str
    description: Optional[str]
    created_at: str

@dataclass
class SelfEmploymentIncome:
    """Self-employment income entry"""
    id: str
    amount: float
    date: str
    client: str
    description: str
    invoice_number: Optional[str]
    created_at: str

class IncomeTracker:
    """
    Tracks employment and self-employment income
    Handles Austrian tax requirements and categorization
    """
    
    def __init__(self, data_directory: str):
        self.data_dir = data_directory
        self.employment_file = os.path.join(data_directory, 'employment_income.json')
        self.self_employment_file = os.path.join(data_directory, 'self_employment_income.json')
        
        # Load existing data
        self.employment_income = self._load_employment_income()
        self.self_employment_income = self._load_self_employment_income()
    
    def _load_employment_income(self) -> List[EmploymentIncome]:
        """Load employment income from file"""
        if not os.path.exists(self.employment_file):
            return []
        
        try:
            with open(self.employment_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                return [EmploymentIncome(**item) for item in data]
        except (json.JSONDecodeError, TypeError):
            return []
    
    def _load_self_employment_income(self) -> List[SelfEmploymentIncome]:
        """Load self-employment income from file"""
        if not os.path.exists(self.self_employment_file):
            return []
        
        try:
            with open(self.self_employment_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                return [SelfEmploymentIncome(**item) for item in data]
        except (json.JSONDecodeError, TypeError):
            return []
    
    def _save_employment_income(self):
        """Save employment income to file"""
        with open(self.employment_file, 'w', encoding='utf-8') as f:
            json.dump([asdict(item) for item in self.employment_income], f, indent=2, ensure_ascii=False)
    
    def _save_self_employment_income(self):
        """Save self-employment income to file"""
        with open(self.self_employment_file, 'w', encoding='utf-8') as f:
            json.dump([asdict(item) for item in self.self_employment_income], f, indent=2, ensure_ascii=False)
    
    def _employment_income_exists(self, amount: float, date: str, employer: str, description: str = None) -> bool:
        """Check if employment income with same details already exists"""
        rounded_amount = round(amount, 2)
        return any(
            inc.amount == rounded_amount and 
            inc.date == date and 
            inc.employer.strip().lower() == employer.strip().lower() and
            (inc.description or '').strip().lower() == (description or '').strip().lower()
            for inc in self.employment_income
        )
    
    def _self_employment_income_exists(self, amount: float, date: str, client: str, description: str) -> bool:
        """Check if self-employment income with same details already exists"""
        rounded_amount = round(amount, 2)
        return any(
            inc.amount == rounded_amount and 
            inc.date == date and 
            inc.client.strip().lower() == client.strip().lower() and
            inc.description.strip().lower() == description.strip().lower()
            for inc in self.self_employment_income
        )
    
    def add_employment_income(self, amount: float, date: str, employer: str, description: str = None) -> bool:
        """Add employment income entry (with duplicate detection)"""
        try:
            # Validate date format
            datetime.strptime(date, '%Y-%m-%d')
            
            # Check for duplicates
            if self._employment_income_exists(amount, date, employer, description):
                print(f"Duplicate employment income detected: {amount} on {date} from {employer}")
                return False  # Skip duplicate
            
            income_entry = EmploymentIncome(
                id=f"emp_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{len(self.employment_income)}",
                amount=round(amount, 2),
                date=date,
                employer=employer,
                description=description,
                created_at=datetime.now().isoformat()
            )
            
            self.employment_income.append(income_entry)
            self._save_employment_income()
            return True
            
        except (ValueError, TypeError) as e:
            print(f"Error adding employment income: {e}")
            return False
    
    def add_self_employment_income(self, amount: float, date: str, client: str, description: str, invoice_number: str = None) -> bool:
        """Add self-employment income entry (with duplicate detection)"""
        try:
            # Validate date format
            datetime.strptime(date, '%Y-%m-%d')
            
            # Check for duplicates
            if self._self_employment_income_exists(amount, date, client, description):
                print(f"Duplicate self-employment income detected: {amount} on {date} from {client}")
                return False  # Skip duplicate
            
            income_entry = SelfEmploymentIncome(
                id=f"self_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{len(self.self_employment_income)}",
                amount=round(amount, 2),
                date=date,
                client=client,
                description=description,
                invoice_number=invoice_number,
                created_at=datetime.now().isoformat()
            )
            
            self.self_employment_income.append(income_entry)
            self._save_self_employment_income()
            return True
            
        except (ValueError, TypeError) as e:
            print(f"Error adding self-employment income: {e}")
            return False
    
    def get_employment_total(self, year: int) -> float:
        """Get total employment income for a year"""
        total = 0
        for income in self.employment_income:
            if income.date.startswith(str(year)):
                total += income.amount
        return round(total, 2)
    
    def get_self_employment_total(self, year: int) -> float:
        """Get total self-employment income for a year"""
        total = 0
        for income in self.self_employment_income:
            if income.date.startswith(str(year)):
                total += income.amount
        return round(total, 2)
    
    def get_employment_income_for_month(self, year: int, month: int) -> float:
        """Get employment income for specific month"""
        year_month = f"{year}-{month:02d}"
        total = 0
        for income in self.employment_income:
            if income.date.startswith(year_month):
                total += income.amount
        return round(total, 2)
    
    def get_self_employment_income_for_month(self, year: int, month: int) -> float:
        """Get self-employment income for specific month"""
        year_month = f"{year}-{month:02d}"
        total = 0
        for income in self.self_employment_income:
            if income.date.startswith(year_month):
                total += income.amount
        return round(total, 2)
    
    def get_employment_income_for_period(self, start_date: str, end_date: str) -> float:
        """Get employment income for custom date period"""
        total = 0
        for income in self.employment_income:
            if start_date <= income.date <= end_date:
                total += income.amount
        return round(total, 2)
    
    def get_self_employment_income_for_period(self, start_date: str, end_date: str) -> float:
        """Get self-employment income for custom date period"""
        total = 0
        for income in self.self_employment_income:
            if start_date <= income.date <= end_date:
                total += income.amount
        return round(total, 2)
    
    def get_employment_by_employer(self, year: int) -> Dict[str, float]:
        """Get employment income grouped by employer"""
        employer_totals = {}
        for income in self.employment_income:
            if income.date.startswith(str(year)):
                if income.employer not in employer_totals:
                    employer_totals[income.employer] = 0
                employer_totals[income.employer] += income.amount
        
        return {k: round(v, 2) for k, v in employer_totals.items()}
    
    def get_self_employment_by_client(self, year: int) -> Dict[str, float]:
        """Get self-employment income grouped by client"""
        client_totals = {}
        for income in self.self_employment_income:
            if income.date.startswith(str(year)):
                if income.client not in client_totals:
                    client_totals[income.client] = 0
                client_totals[income.client] += income.amount
        
        return {k: round(v, 2) for k, v in client_totals.items()}
    
    def get_monthly_breakdown(self, year: int) -> Dict[str, Dict[str, float]]:
        """Get monthly breakdown of all income"""
        monthly_data = {}
        
        for month in range(1, 13):
            month_key = f"{year}-{month:02d}"
            monthly_data[month_key] = {
                "employment": self.get_employment_income_for_month(year, month),
                "self_employment": self.get_self_employment_income_for_month(year, month),
                "total": 0
            }
            monthly_data[month_key]["total"] = (
                monthly_data[month_key]["employment"] + 
                monthly_data[month_key]["self_employment"]
            )
        
        return monthly_data
    
    def get_recent_income(self, limit: int = 10) -> Dict:
        """Get recent income entries for dashboard"""
        # Sort all income by date (newest first)
        all_income = []
        
        for income in self.employment_income:
            all_income.append({
                "type": "employment",
                "amount": income.amount,
                "date": income.date,
                "source": income.employer,
                "description": income.description or "Employment income"
            })
        
        for income in self.self_employment_income:
            all_income.append({
                "type": "self_employment", 
                "amount": income.amount,
                "date": income.date,
                "source": income.client,
                "description": income.description,
                "invoice": income.invoice_number
            })
        
        # Sort by date (newest first)
        all_income.sort(key=lambda x: x["date"], reverse=True)
        
        return {
            "recent_entries": all_income[:limit],
            "total_entries": len(all_income)
        }
    
    def export_data(self, year: int = None) -> Dict:
        """Export income data for specified year"""
        if year:
            employment_data = [
                asdict(income) for income in self.employment_income 
                if income.date.startswith(str(year))
            ]
            self_employment_data = [
                asdict(income) for income in self.self_employment_income 
                if income.date.startswith(str(year))
            ]
        else:
            employment_data = [asdict(income) for income in self.employment_income]
            self_employment_data = [asdict(income) for income in self.self_employment_income]
        
        return {
            "employment_income": employment_data,
            "self_employment_income": self_employment_data,
            "summary": {
                "total_employment": sum(item["amount"] for item in employment_data),
                "total_self_employment": sum(item["amount"] for item in self_employment_data),
                "total_income": sum(item["amount"] for item in employment_data + self_employment_data)
            }
        }
    
    def delete_income_entry(self, entry_id: str, income_type: str) -> bool:
        """Delete an income entry by ID"""
        try:
            if income_type == "employment":
                self.employment_income = [
                    income for income in self.employment_income 
                    if income.id != entry_id
                ]
                self._save_employment_income()
                return True
            elif income_type == "self_employment":
                self.self_employment_income = [
                    income for income in self.self_employment_income 
                    if income.id != entry_id
                ]
                self._save_self_employment_income()
                return True
            return False
        except Exception as e:
            print(f"Error deleting income entry: {e}")
            return False 