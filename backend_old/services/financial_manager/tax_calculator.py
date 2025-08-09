"""
Austrian Tax Calculator
Handles Austrian income tax, social security, and SVA calculations for 2024
"""

from typing import Dict, List, Tuple
from dataclasses import dataclass
import math

@dataclass
class TaxBreakdown:
    """Tax calculation breakdown"""
    gross_income: float
    employment_income: float
    self_employment_income: float
    income_tax: float
    social_security_employee: float
    social_security_self_employed: float
    total_tax_burden: float
    net_income: float
    effective_tax_rate: float

class AustrianTaxCalculator:
    """
    Austrian Tax Calculator for 2024
    Handles income tax brackets, social security, and SVA contributions
    """
    
    def __init__(self, tax_config: Dict):
        self.tax_brackets = tax_config['income_tax_brackets']
        self.social_security_rate = tax_config['social_security_rate']
        self.social_security_max = tax_config['social_security_max']
        self.self_employment_tax_rate = tax_config['self_employment_tax_rate']
    
    def calculate_income_tax(self, taxable_income: float) -> float:
        """Calculate Austrian income tax using progressive brackets"""
        if taxable_income <= 0:
            return 0
        
        total_tax = 0
        remaining_income = taxable_income
        
        for bracket in self.tax_brackets:
            bracket_min = bracket['min']
            bracket_max = bracket['max']
            bracket_rate = bracket['rate']
            
            if remaining_income <= 0:
                break
            
            # Calculate taxable amount in this bracket
            if taxable_income <= bracket_min:
                continue
                
            bracket_income = min(remaining_income, bracket_max - bracket_min)
            if taxable_income > bracket_max:
                bracket_income = bracket_max - bracket_min
            else:
                bracket_income = taxable_income - bracket_min
            
            bracket_tax = bracket_income * bracket_rate
            total_tax += bracket_tax
            
            remaining_income -= bracket_income
            
            if taxable_income <= bracket_max:
                break
        
        return round(total_tax, 2)
    
    def calculate_social_security_employee(self, employment_income: float) -> float:
        """Calculate employee social security contributions"""
        if employment_income <= 0:
            return 0
        
        # Monthly calculation (then multiply by 12)
        monthly_income = employment_income / 12
        
        # Apply maximum
        taxable_monthly = min(monthly_income, self.social_security_max)
        
        # Calculate annual contribution
        annual_contribution = taxable_monthly * self.social_security_rate * 12
        
        return round(annual_contribution, 2)
    
    def calculate_social_security_self_employed(self, self_employment_income: float) -> float:
        """Calculate SVA (self-employment) social security contributions"""
        if self_employment_income <= 0:
            return 0
        
        # SVA has different calculation - simplified version
        # Minimum base: €537.78/month (2024)
        # Maximum base: €6,120/month (2024)
        
        monthly_income = self_employment_income / 12
        
        # Apply SVA minimum and maximum
        sva_min_monthly = 537.78
        sva_max_monthly = 6120.00
        
        taxable_monthly = max(sva_min_monthly, min(monthly_income, sva_max_monthly))
        
        # Calculate annual SVA contribution
        annual_sva = taxable_monthly * self.self_employment_tax_rate * 12
        
        return round(annual_sva, 2)
    
    def calculate_annual_tax(self, employment_income: float, self_employment_income: float) -> float:
        """Calculate total annual tax burden"""
        # Total taxable income
        total_income = employment_income + self_employment_income
        
        # Income tax
        income_tax = self.calculate_income_tax(total_income)
        
        # Social security contributions
        ss_employee = self.calculate_social_security_employee(employment_income)
        ss_self_employed = self.calculate_social_security_self_employed(self_employment_income)
        
        # Total tax burden
        total_tax = income_tax + ss_employee + ss_self_employed
        
        return round(total_tax, 2)
    
    def get_tax_breakdown(self, employment_income: float, self_employment_income: float) -> TaxBreakdown:
        """Get detailed tax breakdown"""
        total_income = employment_income + self_employment_income
        
        # Calculate each component
        income_tax = self.calculate_income_tax(total_income)
        ss_employee = self.calculate_social_security_employee(employment_income)
        ss_self_employed = self.calculate_social_security_self_employed(self_employment_income)
        
        total_tax_burden = income_tax + ss_employee + ss_self_employed
        net_income = total_income - total_tax_burden
        
        # Effective tax rate
        effective_rate = (total_tax_burden / total_income * 100) if total_income > 0 else 0
        
        return TaxBreakdown(
            gross_income=round(total_income, 2),
            employment_income=round(employment_income, 2),
            self_employment_income=round(self_employment_income, 2),
            income_tax=round(income_tax, 2),
            social_security_employee=round(ss_employee, 2),
            social_security_self_employed=round(ss_self_employed, 2),
            total_tax_burden=round(total_tax_burden, 2),
            net_income=round(net_income, 2),
            effective_tax_rate=round(effective_rate, 2)
        )
    
    def calculate_monthly_withholding(self, monthly_employment_income: float) -> Dict[str, float]:
        """Calculate monthly tax withholding for employment income"""
        annual_income = monthly_employment_income * 12
        
        # Estimate annual tax
        annual_income_tax = self.calculate_income_tax(annual_income)
        annual_ss = self.calculate_social_security_employee(annual_income)
        
        # Monthly withholding
        monthly_income_tax = annual_income_tax / 12
        monthly_ss = annual_ss / 12
        
        return {
            "monthly_gross": round(monthly_employment_income, 2),
            "monthly_income_tax": round(monthly_income_tax, 2),
            "monthly_social_security": round(monthly_ss, 2),
            "monthly_total_deductions": round(monthly_income_tax + monthly_ss, 2),
            "monthly_net": round(monthly_employment_income - monthly_income_tax - monthly_ss, 2)
        }
    
    def calculate_quarterly_sva(self, quarterly_self_employment_income: float) -> Dict[str, float]:
        """Calculate quarterly SVA payments for self-employment"""
        annual_income = quarterly_self_employment_income * 4
        annual_sva = self.calculate_social_security_self_employed(annual_income)
        quarterly_sva = annual_sva / 4
        
        return {
            "quarterly_income": round(quarterly_self_employment_income, 2),
            "quarterly_sva": round(quarterly_sva, 2),
            "annual_sva_estimate": round(annual_sva, 2)
        }
    
    def generate_tax_report(self, employment_income: float, self_employment_income: float, year: int) -> Dict:
        """Generate comprehensive Austrian tax report"""
        breakdown = self.get_tax_breakdown(employment_income, self_employment_income)
        
        # Calculate bracket breakdown
        bracket_breakdown = []
        total_income = employment_income + self_employment_income
        remaining_income = total_income
        
        for bracket in self.tax_brackets:
            if remaining_income <= 0:
                break
                
            bracket_min = bracket['min']
            bracket_max = bracket['max']
            bracket_rate = bracket['rate']
            
            if total_income <= bracket_min:
                continue
            
            if total_income > bracket_max:
                bracket_income = bracket_max - bracket_min
            else:
                bracket_income = total_income - bracket_min
                
            bracket_tax = bracket_income * bracket_rate
            
            bracket_breakdown.append({
                "bracket": f"€{bracket_min:,.0f} - €{bracket_max:,.0f}" if bracket_max != float('inf') else f"€{bracket_min:,.0f}+",
                "rate": f"{bracket_rate * 100:.0f}%",
                "taxable_income": round(bracket_income, 2),
                "tax_amount": round(bracket_tax, 2)
            })
            
            remaining_income -= bracket_income
            
            if total_income <= bracket_max:
                break
        
        # Austrian specific info
        austrian_info = {
            "tax_year": year,
            "filing_deadline": f"April 30, {year + 1}",
            "currency": "EUR",
            "tax_system": "Progressive Income Tax",
            "social_security_info": {
                "employee_rate": f"{self.social_security_rate * 100:.2f}%",
                "employee_max_monthly": f"€{self.social_security_max:,.0f}",
                "sva_rate": f"{self.self_employment_tax_rate * 100:.2f}%"
            }
        }
        
        return {
            "tax_summary": breakdown.__dict__,
            "bracket_breakdown": bracket_breakdown,
            "austrian_tax_info": austrian_info,
            "recommendations": self._generate_tax_recommendations(breakdown)
        }
    
    def _generate_tax_recommendations(self, breakdown: TaxBreakdown) -> List[str]:
        """Generate tax optimization recommendations"""
        recommendations = []
        
        # High tax burden
        if breakdown.effective_tax_rate > 40:
            recommendations.append("Consider maximizing deductible business expenses to reduce tax burden")
            recommendations.append("Look into pension contributions for tax deductions")
        
        # Self-employment income
        if breakdown.self_employment_income > 0:
            recommendations.append("Keep detailed records of all business expenses for tax deductions")
            recommendations.append("Consider quarterly tax payments to avoid penalties")
            
        # High income
        if breakdown.gross_income > 60000:
            recommendations.append("Consider consulting a tax advisor for advanced tax planning")
            recommendations.append("Explore investment options with tax benefits")
        
        # General recommendations
        recommendations.append("Maintain organized records of all income and expenses")
        recommendations.append("Consider using tax software or professional help for complex situations")
        
        return recommendations 