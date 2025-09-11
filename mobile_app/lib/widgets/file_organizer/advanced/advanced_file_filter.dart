import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/file_organizer_models.dart';
import '../../../animations/micro_interactions.dart';

/// Advanced filtering and sorting widget for file lists
class AdvancedFileFilter extends StatefulWidget {
  final List<FileItem> allFiles;
  final Function(List<FileItem>) onFiltersChanged;
  final Function(Map<String, dynamic>) onFilterConfigChanged;
  final Map<String, dynamic> initialFilters;

  const AdvancedFileFilter({
    Key? key,
    required this.allFiles,
    required this.onFiltersChanged,
    required this.onFilterConfigChanged,
    this.initialFilters = const {},
  }) : super(key: key);

  @override
  State<AdvancedFileFilter> createState() => _AdvancedFileFilterState();
}

class _AdvancedFileFilterState extends State<AdvancedFileFilter>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _searchController;
  late TextEditingController _minSizeController;
  late TextEditingController _maxSizeController;
  
  // Filter state
  String _searchQuery = '';
  Set<String> _selectedFileTypes = <String>{};
  DateTime? _startDate;
  DateTime? _endDate;
  double _minSizeBytes = 0;
  double _maxSizeBytes = double.infinity;
  String _sizeUnit = 'MB';
  String _sortBy = 'name';
  bool _sortAscending = true;
  bool _showHiddenFiles = false;
  String _pathFilter = '';
  
  // Advanced filters
  Map<String, bool> _advancedFilters = {
    'hasSuggestedLocation': false,
    'isRecent': false,
    'isLarge': false,
    'isDuplicate': false,
    'needsOrganization': false,
  };

  final List<String> _availableFileTypes = [
    'image', 'video', 'audio', 'document', 'pdf', 'archive', 'other'
  ];

  final List<String> _sortOptions = [
    'name', 'size', 'date', 'type', 'path'
  ];

  final List<String> _sizeUnits = ['B', 'KB', 'MB', 'GB'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController = TextEditingController();
    _minSizeController = TextEditingController();
    _maxSizeController = TextEditingController();
    
    _loadInitialFilters();
    _applyFilters();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _minSizeController.dispose();
    _maxSizeController.dispose();
    super.dispose();
  }

  void _loadInitialFilters() {
    final filters = widget.initialFilters;
    
    setState(() {
      _searchQuery = filters['searchQuery'] ?? '';
      _selectedFileTypes = Set<String>.from(filters['fileTypes'] ?? []);
      _sortBy = filters['sortBy'] ?? 'name';
      _sortAscending = filters['sortAscending'] ?? true;
      _showHiddenFiles = filters['showHiddenFiles'] ?? false;
      _pathFilter = filters['pathFilter'] ?? '';
      _advancedFilters = Map<String, bool>.from(filters['advancedFilters'] ?? {});
      
      if (filters['startDate'] != null) {
        _startDate = DateTime.parse(filters['startDate']);
      }
      if (filters['endDate'] != null) {
        _endDate = DateTime.parse(filters['endDate']);
      }
      
      _minSizeBytes = filters['minSizeBytes']?.toDouble() ?? 0;
      _maxSizeBytes = filters['maxSizeBytes']?.toDouble() ?? double.infinity;
      _sizeUnit = filters['sizeUnit'] ?? 'MB';
    });

    _searchController.text = _searchQuery;
    _updateSizeControllers();
  }

  void _updateSizeControllers() {
    if (_minSizeBytes > 0) {
      _minSizeController.text = _convertFromBytes(_minSizeBytes, _sizeUnit).toString();
    }
    if (_maxSizeBytes != double.infinity) {
      _maxSizeController.text = _convertFromBytes(_maxSizeBytes, _sizeUnit).toString();
    }
  }

  double _convertToBytes(double value, String unit) {
    switch (unit) {
      case 'KB': return value * 1024;
      case 'MB': return value * 1024 * 1024;
      case 'GB': return value * 1024 * 1024 * 1024;
      default: return value;
    }
  }

  double _convertFromBytes(double bytes, String unit) {
    switch (unit) {
      case 'KB': return bytes / 1024;
      case 'MB': return bytes / (1024 * 1024);
      case 'GB': return bytes / (1024 * 1024 * 1024);
      default: return bytes;
    }
  }

  void _applyFilters() {
    var filteredFiles = widget.allFiles.where((file) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!file.name.toLowerCase().contains(query) &&
            !file.path.toLowerCase().contains(query)) {
          return false;
        }
      }

      // File type filter
      if (_selectedFileTypes.isNotEmpty) {
        if (!_selectedFileTypes.contains(file.type.toLowerCase())) {
          return false;
        }
      }

      // Date range filter
      if (_startDate != null || _endDate != null) {
        final fileDate = file.lastModified;
        if (_startDate != null && fileDate.isBefore(_startDate!)) return false;
        if (_endDate != null && fileDate.isAfter(_endDate!.add(const Duration(days: 1)))) return false;
      }

      // Size filter
      if (file.size < _minSizeBytes || file.size > _maxSizeBytes) {
        return false;
      }

      // Path filter
      if (_pathFilter.isNotEmpty) {
        if (!file.path.toLowerCase().contains(_pathFilter.toLowerCase())) {
          return false;
        }
      }

      // Hidden files filter
      if (!_showHiddenFiles && file.name.startsWith('.')) {
        return false;
      }

      // Advanced filters
      if (_advancedFilters['hasSuggestedLocation'] == true && file.suggestedLocation == null) {
        return false;
      }

      if (_advancedFilters['isRecent'] == true) {
        final daysSinceModified = DateTime.now().difference(file.lastModified).inDays;
        if (daysSinceModified > 7) return false;
      }

      if (_advancedFilters['isLarge'] == true) {
        if (file.size < 100 * 1024 * 1024) return false; // < 100MB
      }

      // TODO: Implement duplicate detection
      if (_advancedFilters['isDuplicate'] == true) {
        // Placeholder for duplicate detection logic
      }

      if (_advancedFilters['needsOrganization'] == true && file.suggestedLocation == null) {
        return false;
      }

      return true;
    }).toList();

    // Sort files
    filteredFiles.sort((a, b) {
      int comparison = 0;
      
      switch (_sortBy) {
        case 'name':
          comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case 'size':
          comparison = a.size.compareTo(b.size);
          break;
        case 'date':
          comparison = a.lastModified.compareTo(b.lastModified);
          break;
        case 'type':
          comparison = a.type.toLowerCase().compareTo(b.type.toLowerCase());
          break;
        case 'path':
          comparison = a.path.toLowerCase().compareTo(b.path.toLowerCase());
          break;
      }
      
      return _sortAscending ? comparison : -comparison;
    });

    widget.onFiltersChanged(filteredFiles);
    _notifyFilterConfigChanged();
  }

  void _notifyFilterConfigChanged() {
    final config = {
      'searchQuery': _searchQuery,
      'fileTypes': _selectedFileTypes.toList(),
      'startDate': _startDate?.toIso8601String(),
      'endDate': _endDate?.toIso8601String(),
      'minSizeBytes': _minSizeBytes,
      'maxSizeBytes': _maxSizeBytes == double.infinity ? null : _maxSizeBytes,
      'sizeUnit': _sizeUnit,
      'sortBy': _sortBy,
      'sortAscending': _sortAscending,
      'showHiddenFiles': _showHiddenFiles,
      'pathFilter': _pathFilter,
      'advancedFilters': _advancedFilters,
    };
    widget.onFilterConfigChanged(config);
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _selectedFileTypes.clear();
      _startDate = null;
      _endDate = null;
      _minSizeBytes = 0;
      _maxSizeBytes = double.infinity;
      _sizeUnit = 'MB';
      _sortBy = 'name';
      _sortAscending = true;
      _showHiddenFiles = false;
      _pathFilter = '';
      _advancedFilters = {
        'hasSuggestedLocation': false,
        'isRecent': false,
        'isLarge': false,
        'isDuplicate': false,
        'needsOrganization': false,
      };
    });

    _searchController.clear();
    _minSizeController.clear();
    _maxSizeController.clear();
    
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBasicFilters(),
                _buildAdvancedFilters(),
                _buildSortAndDisplay(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final activeFiltersCount = _getActiveFiltersCount();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_list,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Filter Files',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (activeFiltersCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$activeFiltersCount',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 8),
          MicroInteractions.animatedButton(
            onPressed: _resetFilters,
            child: Icon(
              Icons.clear_all,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(icon: Icon(Icons.search), text: 'Basic'),
        Tab(icon: Icon(Icons.tune), text: 'Advanced'),
        Tab(icon: Icon(Icons.sort), text: 'Sort'),
      ],
    );
  }

  Widget _buildBasicFilters() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search files and paths',
              hintText: 'Enter keywords...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                        _applyFilters();
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
              _applyFilters();
            },
          ),
          const SizedBox(height: 24),

          // File Types
          Text(
            'File Types',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableFileTypes.map((type) {
              final isSelected = _selectedFileTypes.contains(type);
              return FilterChip(
                label: Text(_capitalizeFirst(type)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedFileTypes.add(type);
                    } else {
                      _selectedFileTypes.remove(type);
                    }
                  });
                  _applyFilters();
                },
                avatar: Icon(
                  _getFileIcon(type),
                  size: 16,
                  color: isSelected 
                      ? Theme.of(context).colorScheme.onSecondaryContainer
                      : Theme.of(context).colorScheme.onSurface,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Date Range
          Text(
            'Date Range',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectDate(context, true),
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_startDate != null 
                      ? _formatDate(_startDate!)
                      : 'Start Date'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectDate(context, false),
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_endDate != null 
                      ? _formatDate(_endDate!)
                      : 'End Date'),
                ),
              ),
            ],
          ),
          if (_startDate != null || _endDate != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _startDate = null;
                  _endDate = null;
                });
                _applyFilters();
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear Date Range'),
            ),
          ],
          const SizedBox(height: 24),

          // Size Range
          Text(
            'File Size',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minSizeController,
                  decoration: const InputDecoration(
                    labelText: 'Min Size',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                  onChanged: (value) {
                    final size = double.tryParse(value) ?? 0;
                    setState(() {
                      _minSizeBytes = _convertToBytes(size, _sizeUnit);
                    });
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _maxSizeController,
                  decoration: const InputDecoration(
                    labelText: 'Max Size',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                  onChanged: (value) {
                    final size = double.tryParse(value);
                    setState(() {
                      _maxSizeBytes = size != null ? _convertToBytes(size, _sizeUnit) : double.infinity;
                    });
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _sizeUnit,
                items: _sizeUnits.map((unit) => DropdownMenuItem(
                  value: unit,
                  child: Text(unit),
                )).toList(),
                onChanged: (unit) {
                  setState(() => _sizeUnit = unit ?? 'MB');
                  _updateSizeControllers();
                  _applyFilters();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Path Filter
          TextField(
            decoration: const InputDecoration(
              labelText: 'Path Filter',
              hintText: 'Filter by path contains...',
              prefixIcon: Icon(Icons.folder),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() => _pathFilter = value);
              _applyFilters();
            },
          ),
          const SizedBox(height: 24),

          // Show Hidden Files
          SwitchListTile(
            title: const Text('Show Hidden Files'),
            subtitle: const Text('Include files starting with "."'),
            value: _showHiddenFiles,
            onChanged: (value) {
              setState(() => _showHiddenFiles = value);
              _applyFilters();
            },
          ),
          const SizedBox(height: 16),

          // Advanced Filter Options
          Text(
            'Advanced Filters',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          ..._advancedFilters.entries.map((entry) {
            return CheckboxListTile(
              title: Text(_getAdvancedFilterTitle(entry.key)),
              subtitle: Text(_getAdvancedFilterDescription(entry.key)),
              value: entry.value,
              onChanged: (value) {
                setState(() {
                  _advancedFilters[entry.key] = value ?? false;
                });
                _applyFilters();
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSortAndDisplay() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sort Options
          Text(
            'Sort By',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          ...(_sortOptions.map((option) {
            return RadioListTile<String>(
              title: Text(_capitalizeFirst(option)),
              subtitle: Text(_getSortDescription(option)),
              value: option,
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() => _sortBy = value ?? 'name');
                _applyFilters();
              },
            );
          })),
          
          const SizedBox(height: 16),
          
          // Sort Direction
          SwitchListTile(
            title: const Text('Sort Direction'),
            subtitle: Text(_sortAscending ? 'Ascending (A-Z, 0-9)' : 'Descending (Z-A, 9-0)'),
            value: _sortAscending,
            onChanged: (value) {
              setState(() => _sortAscending = value);
              _applyFilters();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final initialDate = isStartDate ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now());
    final firstDate = DateTime(2000);
    final lastDate = DateTime.now().add(const Duration(days: 365));
    
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    
    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
        } else {
          _endDate = pickedDate;
        }
      });
      _applyFilters();
    }
  }

  int _getActiveFiltersCount() {
    int count = 0;
    
    if (_searchQuery.isNotEmpty) count++;
    if (_selectedFileTypes.isNotEmpty) count++;
    if (_startDate != null || _endDate != null) count++;
    if (_minSizeBytes > 0 || _maxSizeBytes != double.infinity) count++;
    if (_pathFilter.isNotEmpty) count++;
    if (_showHiddenFiles) count++;
    if (_advancedFilters.values.any((filter) => filter)) count++;
    if (_sortBy != 'name' || !_sortAscending) count++;
    
    return count;
  }

  String _getAdvancedFilterTitle(String key) {
    switch (key) {
      case 'hasSuggestedLocation': return 'Has AI Suggestions';
      case 'isRecent': return 'Recently Modified';
      case 'isLarge': return 'Large Files';
      case 'isDuplicate': return 'Possible Duplicates';
      case 'needsOrganization': return 'Needs Organization';
      default: return key;
    }
  }

  String _getAdvancedFilterDescription(String key) {
    switch (key) {
      case 'hasSuggestedLocation': return 'Files with AI organization suggestions';
      case 'isRecent': return 'Modified within the last 7 days';
      case 'isLarge': return 'Files larger than 100 MB';
      case 'isDuplicate': return 'Potential duplicate files';
      case 'needsOrganization': return 'Files that may need organizing';
      default: return '';
    }
  }

  String _getSortDescription(String option) {
    switch (option) {
      case 'name': return 'Sort alphabetically by filename';
      case 'size': return 'Sort by file size';
      case 'date': return 'Sort by modification date';
      case 'type': return 'Sort by file type';
      case 'path': return 'Sort by file path';
      default: return '';
    }
  }

  IconData _getFileIcon(String type) {
    switch (type.toLowerCase()) {
      case 'image': return Icons.image_outlined;
      case 'video': return Icons.video_file_outlined;
      case 'audio': return Icons.audio_file_outlined;
      case 'document': return Icons.description_outlined;
      case 'pdf': return Icons.picture_as_pdf_outlined;
      case 'archive': return Icons.archive_outlined;
      default: return Icons.insert_drive_file_outlined;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
