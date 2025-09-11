import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/construction_models.dart';
import '../../services/construction_service.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class AddConstructionExpenseForm extends StatefulWidget {
  final String phaseId;
  final VoidCallback onExpenseAdded;

  const AddConstructionExpenseForm({
    Key? key,
    required this.phaseId,
    required this.onExpenseAdded,
  }) : super(key: key);

  @override
  State<AddConstructionExpenseForm> createState() => _AddConstructionExpenseFormState();
}

class _AddConstructionExpenseFormState extends State<AddConstructionExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _constructionService = ConstructionService();
  final _uuid = const Uuid();
  
  // Form controllers
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  final _notesController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  
  // Form state
  String _selectedCategory = 'foundation';
  String _selectedSubcategory = 'excavation';
  DateTime _selectedDate = DateTime.now();
  String _paymentStatus = 'pending';
  DateTime? _paymentDate;
  bool _isVatIncluded = true;
  String? _selectedSupplierId;
  String _supplierName = '';
  String _measurementUnit = '';
  
  List<Supplier> _suppliers = [];
  bool _isLoading = false;
  bool _isLoadingSuppliers = true;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
    _updateSubcategories();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _invoiceNumberController.dispose();
    _notesController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    try {
      final suppliers = await _constructionService.getSuppliers();
      setState(() {
        _suppliers = suppliers;
        _isLoadingSuppliers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSuppliers = false;
      });
    }
  }

  void _updateSubcategories() {
    final subcategories = ConstructionCategories.getSubcategories(_selectedCategory);
    if (subcategories.isNotEmpty && !subcategories.contains(_selectedSubcategory)) {
      setState(() {
        _selectedSubcategory = subcategories.first;
      });
    }
  }

  void _calculateVAT() {
    if (_amountController.text.isNotEmpty) {
      final amount = double.tryParse(_amountController.text) ?? 0;
      // Austrian VAT calculation logic can be added here
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectPaymentDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _paymentDate = picked;
        if (_paymentStatus == 'pending') {
          _paymentStatus = 'paid';
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text);
      final vatAmount = _isVatIncluded ? amount * 0.20 : 0.0; // Austrian VAT 20%
      
      final expense = ConstructionExpense(
        id: _uuid.v4(),
        phaseId: widget.phaseId,
        category: _selectedCategory,
        subcategory: _selectedSubcategory,
        amount: amount,
        description: _descriptionController.text,
        date: _selectedDate,
        supplierId: _selectedSupplierId,
        supplierName: _supplierName,
        invoiceNumber: _invoiceNumberController.text.isNotEmpty 
            ? _invoiceNumberController.text 
            : null,
        paymentStatus: _paymentStatus,
        paymentDate: _paymentDate,
        isVatIncluded: _isVatIncluded,
        vatAmount: vatAmount,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        measurementUnit: _measurementUnit.isNotEmpty ? _measurementUnit : null,
        quantity: _quantityController.text.isNotEmpty 
            ? double.tryParse(_quantityController.text) 
            : null,
        unitPrice: _unitPriceController.text.isNotEmpty 
            ? double.tryParse(_unitPriceController.text) 
            : null,
      );

      await _constructionService.addExpense(expense);
      
      if (mounted) {
        widget.onExpenseAdded();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Construction expense added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding expense: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Construction Expense'),
        backgroundColor: Colors.orange,
      ),
      body: _isLoadingSuppliers
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Category Selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Category',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Construction Category',
                              border: OutlineInputBorder(),
                            ),
                            items: ConstructionCategories.getAllCategories()
                                .map((category) => DropdownMenuItem(
                                      value: category,
                                      child: Text(ConstructionCategories.getCategoryDisplayName(category)),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value!;
                                _updateSubcategories();
                              });
                            },
                            validator: (value) => value == null ? 'Please select a category' : null,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedSubcategory,
                            decoration: const InputDecoration(
                              labelText: 'Subcategory',
                              border: OutlineInputBorder(),
                            ),
                            items: ConstructionCategories.getSubcategories(_selectedCategory)
                                .map((subcategory) => DropdownMenuItem(
                                      value: subcategory,
                                      child: Text(subcategory.replaceAll('_', ' ').toUpperCase()),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedSubcategory = value!;
                              });
                            },
                            validator: (value) => value == null ? 'Please select a subcategory' : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Basic Information
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Basic Information',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              border: OutlineInputBorder(),
                              hintText: 'e.g., Foundation concrete C25/30',
                            ),
                            validator: (value) => value?.isEmpty ?? true ? 'Please enter a description' : null,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _amountController,
                                  decoration: const InputDecoration(
                                    labelText: 'Amount (€)',
                                    border: OutlineInputBorder(),
                                    prefixText: '€ ',
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                  ],
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) return 'Please enter an amount';
                                    if (double.tryParse(value!) == null) return 'Please enter a valid amount';
                                    return null;
                                  },
                                  onChanged: (value) => _calculateVAT(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ListTile(
                                  title: Text('Date: ${DateFormat('dd.MM.yyyy').format(_selectedDate)}'),
                                  subtitle: const Text('Expense Date'),
                                  trailing: const Icon(Icons.calendar_today),
                                  onTap: _selectDate,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Supplier Information
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Supplier Information',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedSupplierId,
                            decoration: const InputDecoration(
                              labelText: 'Supplier',
                              border: OutlineInputBorder(),
                            ),
                            hint: const Text('Select or add new supplier'),
                            items: [
                              ..._suppliers.map((supplier) => DropdownMenuItem(
                                    value: supplier.id,
                                    child: Text(supplier.name),
                                  )),
                              const DropdownMenuItem(
                                value: 'new',
                                child: Text('+ Add New Supplier'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedSupplierId = value == 'new' ? null : value;
                                if (value != 'new' && value != null) {
                                  final supplier = _suppliers.firstWhere((s) => s.id == value);
                                  _supplierName = supplier.name;
                                }
                              });
                            },
                          ),
                          if (_selectedSupplierId == null) ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Supplier Name',
                                border: OutlineInputBorder(),
                                hintText: 'Enter supplier name',
                              ),
                              onChanged: (value) => _supplierName = value,
                              validator: (value) => value?.isEmpty ?? true ? 'Please enter supplier name' : null,
                            ),
                          ],
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _invoiceNumberController,
                            decoration: const InputDecoration(
                              labelText: 'Invoice Number (Optional)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Quantity & Pricing
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quantity & Pricing (Optional)',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _quantityController,
                                  decoration: const InputDecoration(
                                    labelText: 'Quantity',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Unit',
                                    border: OutlineInputBorder(),
                                    hintText: 'm³, tons, pieces',
                                  ),
                                  onChanged: (value) => _measurementUnit = value,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _unitPriceController,
                                  decoration: const InputDecoration(
                                    labelText: 'Unit Price (€)',
                                    border: OutlineInputBorder(),
                                    prefixText: '€ ',
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Payment Information
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payment Information',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _paymentStatus,
                            decoration: const InputDecoration(
                              labelText: 'Payment Status',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'pending', child: Text('Pending')),
                              DropdownMenuItem(value: 'paid', child: Text('Paid')),
                              DropdownMenuItem(value: 'overdue', child: Text('Overdue')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _paymentStatus = value!;
                                if (value == 'pending') {
                                  _paymentDate = null;
                                }
                              });
                            },
                          ),
                          if (_paymentStatus == 'paid') ...[
                            const SizedBox(height: 12),
                            ListTile(
                              title: Text(_paymentDate != null 
                                  ? 'Payment Date: ${DateFormat('dd.MM.yyyy').format(_paymentDate!)}'
                                  : 'Select Payment Date'),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: _selectPaymentDate,
                            ),
                          ],
                          const SizedBox(height: 12),
                          SwitchListTile(
                            title: const Text('VAT Included (20%)'),
                            subtitle: Text(_isVatIncluded 
                                ? 'Amount includes Austrian VAT' 
                                : 'VAT will be calculated separately'),
                            value: _isVatIncluded,
                            onChanged: (value) {
                              setState(() {
                                _isVatIncluded = value;
                                _calculateVAT();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Notes
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Additional Notes',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _notesController,
                            decoration: const InputDecoration(
                              labelText: 'Notes (Optional)',
                              border: OutlineInputBorder(),
                              hintText: 'Additional information about this expense',
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Add Construction Expense',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 