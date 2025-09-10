# 📊 CSV Import Guide - Simple Bank Transaction Import

## 🎉 **SALT EDGE IS GONE!** 
We've replaced the complex Salt Edge integration with a **much simpler** CSV import solution that works immediately with Austrian banks.

## 🚀 How to Use CSV Import

### Step 1: Export CSV from Your Bank
Most Austrian banks allow you to export transactions as CSV:
- **Erste Bank**: Online Banking → Transactions → Export CSV
- **Raiffeisen**: Online Banking → Account → Export → CSV
- **Bank Austria**: Online Banking → Transactions → Download CSV
- **ING**: Online Banking → Transactions → Export

### Step 2: Upload CSV to Homie
```bash
curl -X POST -F "file=@your_transactions.csv" http://localhost:8000/api/financial/import-csv
```

Or use any HTTP client / frontend to upload the CSV file.

### Step 3: Done! 
Your transactions are automatically:
- ✅ **Imported** into your financial manager
- ✅ **Categorized** using AI (Austrian construction stores detected)
- ✅ **Sorted** into Income, Expenses, and Construction costs

## 📋 Supported CSV Formats

The import is **very flexible** and supports various column names:

### Date Fields
- `date`, `Date`, `DATE`
- `transaction_date`, `booking_date`
- `Datum` (German)

### Amount Fields  
- `amount`, `Amount`, `AMOUNT`
- `value`, `Value`
- `Betrag` (German)

### Description Fields
- `description`, `Description`, `DESCRIPTION`
- `reference`, `Reference`
- `Verwendungszweck` (German)
- `text`

## 🎯 Smart Categorization

The system automatically detects:

### 🏗️ Construction Expenses
- **Bauhaus**, **Hornbach**, **OBI**, **Baumax**
- Any description containing "bau"

### 🍽️ Food & Dining  
- **Restaurants**, **Supermarkets**
- Keywords: grocery, food, restaurant

### 🚗 Transportation
- **Gas stations**, **Fuel**
- Keywords: gas, fuel, petrol, diesel

### ⚡ Utilities
- **Electricity**, **Water**, **Gas**
- Keywords: utility, electricity, water

## 📊 Example CSV

```csv
Date,Amount,Description
2024-01-15,-45.99,BAUHAUS WIEN - Schrauben und Werkzeug
2024-01-16,-23.50,BILLA SUPERMARKT - Lebensmittel  
2024-01-17,2500.00,GEHALT - Monatsgehalt Januar
2024-01-18,-89.90,HORNBACH SALZBURG - Holz und Farbe
```

## 🔧 API Response

```json
{
  "success": true,
  "message": "CSV import completed",
  "processed_count": 10,
  "skipped_count": 0,
  "processed_transactions": [
    {
      "amount": -45.99,
      "category": "Construction", 
      "date": "2024-01-15",
      "description": "BAUHAUS WIEN - Schrauben und Werkzeug"
    }
  ],
  "total_rows": 10
}
```

## 🎉 Why This is Better Than Salt Edge

- ✅ **No API approval needed** - works immediately
- ✅ **No complex setup** - just upload CSV
- ✅ **Works with any bank** - as long as they export CSV
- ✅ **Privacy friendly** - your data stays local
- ✅ **Austrian optimized** - detects Austrian stores and keywords
- ✅ **Flexible** - handles different CSV formats
- ✅ **Free** - no API costs or limits

## 🏦 Austrian Bank CSV Export Instructions

### Erste Bank / Sparkasse
1. Login to online banking
2. Go to "Umsätze" (Transactions)
3. Select date range
4. Click "Export" → "CSV"

### Raiffeisen
1. Login to online banking  
2. Select account
3. Go to "Umsätze"
4. Click "Export" → "CSV-Datei"

### Bank Austria
1. Login to online banking
2. Select account
3. Go to "Umsätze"
4. Click "Exportieren" → "CSV"

### ING Austria
1. Login to online banking
2. Go to "Kontoauszug"
3. Select period
4. Click "Herunterladen" → "CSV"

---

**🎯 Result: 15 minutes to implement, works immediately, no approvals needed!** 