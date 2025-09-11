import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/construction_models.dart';
import '../../services/construction_service.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class AddPlannedExpenseForm extends StatefulWidget {
  final String phaseId;
  final VoidCallback onPlannedExpenseAdded;

  const AddPlannedExpenseForm({
    Key? key,
    required this.phaseId,
    required this.onPlannedExpenseAdded,
  }) : super(key: key);

  @override
  State<AddPlannedExpenseForm> createState() => _AddPlannedExpenseFormState();
}

class _AddPlannedExpenseFormState extends State<AddPlannedExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _constructionService = ConstructionService();
  final _uuid = const Uuid();
  
  // Form controllers
  final _descriptionController = TextEditingController();
  final _estimatedCostController = TextEditingController();
  final _minCostController = TextEditingController();
  final _maxCostController = TextEditingController();
  final _notesController = TextEditingController();
  final _estimatedQuantityController = TextEditingController();
  final _estimatedUnitPriceController = TextEditingController();
  
  // Form state
  String _selectedCategory = 'foundation';
  String _selectedSubcategory = 'excavation';
  DateTime? _plannedDate;
  DateTime? _deadlineDate;
  String _priority = 'medium';
  String? _selectedSupplierId;
  String _supplierName = '';
  String _measurementUnit = '';
  bool _isApproved = false;
  List<String> _dependencies = [];
  
  List<Supplier> _suppliers = [];
  List<PlannedExpense> _existingPlannedExpenses = [];
  bool _isLoading = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _updateSubcategories();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _estimatedCostController.dispose();
    _minCostController.dispose();
    _maxCostController.dispose();
    _notesController.dispose();
    _estimatedQuantityController.dispose();
    _estimatedUnitPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final suppliers = await _constructionService.getSuppliers();
      final plannedExpenses = await _constructionService.getPlannedExpenses(widget.phaseId);
      
      setState(() {
        _suppliers = suppliers;
        _existingPlannedExpenses = plannedExpenses;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingData = false;
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

  void _calculateEstimatedCost() {
    final quantity = double.tryParse(_estimatedQuantityController.text) ?? 0;
    final unitPrice = double.tryParse(_estimatedUnitPriceController.text) ?? 0;
    
    if (quantity > 0 && unitPrice > 0) {
      final estimatedCost = quantity * unitPrice;
      _estimatedCostController.text = estimatedCost.toStringAsFixed(2);
    }
  }

  Future<void> _selectPlannedDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _plannedDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)), // 2 years
    );
    if (picked != null) {
      setState(() {
        _plannedDate = picked;
      });
    }
  }

  Future<void> _selectDeadlineDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deadlineDate ?? DateTime.now().add(const Duration(days: 60)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 1095)), // 3 years
    );
    if (picked != null) {
      setState(() {
        _deadlineDate = picked;
      });
    }
  }

  void _showDependencySelector() async {
    final availableExpenses = _existingPlannedExpenses
        .where((expense) => expense.id != 'current') // Exclude current expense
        .toList();

    if (availableExpenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No other planned expenses available for dependencies'),
        ),
      );
      return;
    }

    final selectedDependencies = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        List<String> tempDependencies = List.from(_dependencies);
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Dependencies'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableExpenses.length,
                  itemBuilder: (context, index) {
                    final expense = availableExpenses[index];
                    final isSelected = tempDependencies.contains(expense.id);
                    
                    return CheckboxListTile(
                      title: Text(expense.description),
                      subtitle: Text('${expense.category} - €${expense.estimatedCost.toStringAsFixed(0)}'),
                      value: isSelected,
                      onChanged: (value) {
                        setDialogState(() {
                          if (value == true) {
                            tempDependencies.add(expense.id);
                          } else {
                            tempDependencies.remove(expense.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(tempDependencies),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selectedDependencies != null) {
      setState(() {
        _dependencies = selectedDependencies;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final estimatedCost = double.parse(_estimatedCostController.text);
      final minCost = _minCostController.text.isNotEmpty 
          ? double.tryParse(_minCostController.text) 
          : null;
      final maxCost = _maxCostController.text.isNotEmpty 
          ? double.tryParse(_maxCostController.text) 
          : null;
      
      final plannedExpense = PlannedExpense(
        id: _uuid.v4(),
        phaseId: widget.phaseId,
        category: _selectedCategory,
        subcategory: _selectedSubcategory,
        description: _descriptionController.text,
        estimatedCost: estimatedCost,
        minCost: minCost,
        maxCost: maxCost,
        plannedDate: _plannedDate,
        deadlineDate: _deadlineDate,
        priority: _priority,
        supplierId: _selectedSupplierId,
        supplierName: _supplierName,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        isApproved: _isApproved,
        measurementUnit: _measurementUnit.isNotEmpty ? _measurementUnit : null,
        estimatedQuantity: _estimatedQuantityController.text.isNotEmpty 
            ? double.tryParse(_estimatedQuantityController.text) 
            : null,
        estimatedUnitPrice: _estimatedUnitPriceController.text.isNotEmpty 
            ? double.tryParse(_estimatedUnitPriceController.text) 
            : null,
        dependencies: _dependencies,
      );

      await _constructionService.addPlannedExpense(plannedExpense);
      
      if (mounted) {
        widget.onPlannedExpenseAdded();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Future expense planned successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding planned expense: $e'),
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
        title: const Text('Plan Future Expense'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoadingData
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
                              hintText: 'e.g., Heat pump installation',
                            ),
                            validator: (value) => value?.isEmpty ?? true ? 'Please enter a description' : null,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _priority,
                            decoration: const InputDecoration(
                              labelText: 'Priority',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'low', child: Text('Low Priority')),
                              DropdownMenuItem(value: 'medium', child: Text('Medium Priority')),
                              DropdownMenuItem(value: 'high', child: Text('High Priority')),
                              DropdownMenuItem(value: 'critical', child: Text('Critical')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _priority = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Cost Estimation
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cost Estimation',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _estimatedCostController,
                            decoration: const InputDecoration(
                              labelText: 'Estimated Cost (€)',
                              border: OutlineInputBorder(),
                              prefixText: '€ ',
                              hintText: 'Best estimate',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Please enter an estimated cost';
                              if (double.tryParse(value!) == null) return 'Please enter a valid amount';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _minCostController,
                                  decoration: const InputDecoration(
                                    labelText: 'Min Cost (€)',
                                    border: OutlineInputBorder(),
                                    prefixText: '€ ',
                                    hintText: 'Optimistic',
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _maxCostController,
                                  decoration: const InputDecoration(
                                    labelText: 'Max Cost (€)',
                                    border: OutlineInputBorder(),
                                    prefixText: '€ ',
                                    hintText: 'Worst case',
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Quantity & Pricing Calculator
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quantity Calculator (Optional)',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _estimatedQuantityController,
                                  decoration: const InputDecoration(
                                    labelText: 'Quantity',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (value) => _calculateEstimatedCost(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Unit',
                                    border: OutlineInputBorder(),
                                    hintText: 'm², pieces, hours',
                                  ),
                                  onChanged: (value) => _measurementUnit = value,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _estimatedUnitPriceController,
                                  decoration: const InputDecoration(
                                    labelText: 'Unit Price (€)',
                                    border: OutlineInputBorder(),
                                    prefixText: '€ ',
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (value) => _calculateEstimatedCost(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Timeline
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Timeline',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          ListTile(
                            title: Text(_plannedDate != null 
                                ? 'Planned Date: ${DateFormat('dd.MM.yyyy').format(_plannedDate!)}'
                                : 'Select Planned Date'),
                            subtitle: const Text('When do you plan to incur this expense?'),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: _selectPlannedDate,
                          ),
                          const Divider(),
                          ListTile(
                            title: Text(_deadlineDate != null 
                                ? 'Deadline: ${DateFormat('dd.MM.yyyy').format(_deadlineDate!)}'
                                : 'Select Deadline (Optional)'),
                            subtitle: const Text('Latest acceptable date'),
                            trailing: const Icon(Icons.schedule),
                            onTap: _selectDeadlineDate,
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
                              labelText: 'Preferred Supplier (Optional)',
                              border: OutlineInputBorder(),
                            ),
                            hint: const Text('Select supplier if known'),
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
                                hintText: 'Enter supplier name if known',
                              ),
                              onChanged: (value) => _supplierName = value,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Dependencies
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Dependencies',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              TextButton.icon(
                                onPressed: _showDependencySelector,
                                icon: const Icon(Icons.add),
                                label: const Text('Add'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_dependencies.isEmpty)
                            const Text(
                              'No dependencies selected. This expense can be planned independently.',
                              style: TextStyle(color: Colors.grey),
                            )
                          else
                            ...(_dependencies.map((depId) {
                              final dep = _existingPlannedExpenses.firstWhere(
                                (e) => e.id == depId,
                                orElse: () => PlannedExpense(
                                  id: depId,
                                  phaseId: '',
                                  category: '',
                                  subcategory: '',
                                  description: 'Unknown dependency',
                                  estimatedCost: 0,
                                  priority: 'medium',
                                  isApproved: false,
                                  dependencies: [],
                                ),
                              );
                              return Chip(
                                label: Text(dep.description),
                                deleteIcon: const Icon(Icons.close),
                                onDeleted: () {
                                  setState(() {
                                    _dependencies.remove(depId);
                                  });
                                },
                              );
                            })),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Notes & Approval
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Additional Information',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _notesController,
                            decoration: const InputDecoration(
                              labelText: 'Notes (Optional)',
                              border: OutlineInputBorder(),
                              hintText: 'Additional details about this planned expense',
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            title: const Text('Pre-approve this expense'),
                            subtitle: const Text('Mark as approved to skip approval step'),
                            value: _isApproved,
                            onChanged: (value) {
                              setState(() {
                                _isApproved = value;
                              });
                            },
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
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Plan Future Expense',
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