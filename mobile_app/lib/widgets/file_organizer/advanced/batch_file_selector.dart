import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../models/file_organizer_models.dart';
import '../../../providers/accessibility_provider.dart';
import '../../../widgets/accessibility/accessible_button.dart';
import '../../../animations/micro_interactions.dart';

/// Advanced file selector with batch selection, filtering, and multi-select functionality
class BatchFileSelector extends StatefulWidget {
  final List<FileItem> files;
  final List<FileItem> selectedFiles;
  final Function(List<FileItem>) onSelectionChanged;
  final Function(FileItem) onFileAction;
  final bool enableSearch;
  final bool enableFiltering;
  final VoidCallback? onSelectAll;
  final VoidCallback? onSelectNone;
  final VoidCallback? onInvertSelection;

  const BatchFileSelector({
    Key? key,
    required this.files,
    required this.selectedFiles,
    required this.onSelectionChanged,
    required this.onFileAction,
    this.enableSearch = true,
    this.enableFiltering = true,
    this.onSelectAll,
    this.onSelectNone,
    this.onInvertSelection,
  }) : super(key: key);

  @override
  State<BatchFileSelector> createState() => _BatchFileSelectorState();
}

class _BatchFileSelectorState extends State<BatchFileSelector>
    with TickerProviderStateMixin {
  late TextEditingController _searchController;
  late AnimationController _selectionAnimationController;
  late Animation<double> _selectionAnimation;
  
  String _searchQuery = '';
  String _selectedFileType = 'all';
  String _selectedDateRange = 'all';
  String _sortBy = 'name';
  bool _sortAscending = true;
  bool _isSelectionMode = false;
  Set<String> _selectedFileIds = <String>{};

  final List<String> _fileTypes = [
    'all',
    'image',
    'video',
    'audio',
    'document',
    'pdf',
    'archive',
    'other'
  ];

  final List<String> _dateRanges = [
    'all',
    'today',
    'week',
    'month',
    'year',
    'older'
  ];

  final List<String> _sortOptions = [
    'name',
    'size',
    'date',
    'type'
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _selectionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _selectionAnimationController,
      curve: Curves.easeInOut,
    ));

    // Initialize selection from widget
    _selectedFileIds = widget.selectedFiles.map((f) => f.id).toSet();
    _isSelectionMode = _selectedFileIds.isNotEmpty;
    
    if (_isSelectionMode) {
      _selectionAnimationController.forward();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _selectionAnimationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(BatchFileSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update selection if changed externally
    final newSelectedIds = widget.selectedFiles.map((f) => f.id).toSet();
    if (!_selectedFileIds.difference(newSelectedIds).isEmpty ||
        !newSelectedIds.difference(_selectedFileIds).isEmpty) {
      setState(() {
        _selectedFileIds = newSelectedIds;
        _isSelectionMode = _selectedFileIds.isNotEmpty;
      });
      
      if (_isSelectionMode) {
        _selectionAnimationController.forward();
      } else {
        _selectionAnimationController.reverse();
      }
    }
  }

  List<FileItem> get _filteredFiles {
    var filtered = widget.files.where((file) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!file.name.toLowerCase().contains(query) &&
            !file.path.toLowerCase().contains(query)) {
          return false;
        }
      }

      // File type filter
      if (_selectedFileType != 'all') {
        if (file.type.toLowerCase() != _selectedFileType) {
          return false;
        }
      }

      // Date range filter
      if (_selectedDateRange != 'all') {
        final now = DateTime.now();
        final fileDate = file.lastModified;
        
        switch (_selectedDateRange) {
          case 'today':
            if (!_isSameDay(fileDate, now)) return false;
            break;
          case 'week':
            if (now.difference(fileDate).inDays > 7) return false;
            break;
          case 'month':
            if (now.difference(fileDate).inDays > 30) return false;
            break;
          case 'year':
            if (now.difference(fileDate).inDays > 365) return false;
            break;
          case 'older':
            if (now.difference(fileDate).inDays <= 365) return false;
            break;
        }
      }

      return true;
    }).toList();

    // Sort files
    filtered.sort((a, b) {
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
      }
      
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedFileIds.clear();
        _notifySelectionChanged();
      }
    });

    if (_isSelectionMode) {
      _selectionAnimationController.forward();
    } else {
      _selectionAnimationController.reverse();
    }
  }

  void _toggleFileSelection(FileItem file) {
    setState(() {
      if (_selectedFileIds.contains(file.id)) {
        _selectedFileIds.remove(file.id);
      } else {
        _selectedFileIds.add(file.id);
        if (!_isSelectionMode) {
          _isSelectionMode = true;
          _selectionAnimationController.forward();
        }
      }
    });
    
    _notifySelectionChanged();
    
    // Provide haptic feedback
    HapticFeedback.selectionClick();
  }

  void _selectAll() {
    setState(() {
      _selectedFileIds = _filteredFiles.map((f) => f.id).toSet();
      _isSelectionMode = _selectedFileIds.isNotEmpty;
    });
    
    if (_isSelectionMode) {
      _selectionAnimationController.forward();
    }
    
    _notifySelectionChanged();
    widget.onSelectAll?.call();
  }

  void _selectNone() {
    setState(() {
      _selectedFileIds.clear();
      _isSelectionMode = false;
    });
    
    _selectionAnimationController.reverse();
    _notifySelectionChanged();
    widget.onSelectNone?.call();
  }

  void _invertSelection() {
    setState(() {
      final allIds = _filteredFiles.map((f) => f.id).toSet();
      final newSelection = allIds.difference(_selectedFileIds);
      _selectedFileIds = newSelection;
      _isSelectionMode = _selectedFileIds.isNotEmpty;
    });
    
    if (_isSelectionMode) {
      _selectionAnimationController.forward();
    } else {
      _selectionAnimationController.reverse();
    }
    
    _notifySelectionChanged();
    widget.onInvertSelection?.call();
  }

  void _notifySelectionChanged() {
    final selectedFiles = widget.files
        .where((file) => _selectedFileIds.contains(file.id))
        .toList();
    widget.onSelectionChanged(selectedFiles);
  }

  @override
  Widget build(BuildContext context) {
    final filteredFiles = _filteredFiles;
    
    return Consumer<AccessibilityProvider>(
      builder: (context, accessibilityProvider, _) {
        return Column(
          children: [
            if (widget.enableSearch || widget.enableFiltering)
              _buildFilterBar(),
            if (_isSelectionMode) _buildSelectionToolbar(),
            Expanded(
              child: filteredFiles.isEmpty 
                  ? _buildEmptyState() 
                  : _buildFileGrid(filteredFiles),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (widget.enableSearch) ...[
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search files...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
            const SizedBox(height: 12),
          ],
          if (widget.enableFiltering) _buildFilterChips(),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Column(
      children: [
        // File type filter
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const Text('Type: ', style: TextStyle(fontWeight: FontWeight.w500)),
              ..._fileTypes.map((type) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(_capitalizeFirst(type)),
                  selected: _selectedFileType == type,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFileType = selected ? type : 'all';
                    });
                  },
                ),
              )),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Date range and sort options
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedDateRange,
                decoration: const InputDecoration(
                  labelText: 'Date Range',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _dateRanges.map((range) => DropdownMenuItem(
                  value: range,
                  child: Text(_capitalizeFirst(range)),
                )).toList(),
                onChanged: (value) {
                  setState(() => _selectedDateRange = value ?? 'all');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _sortBy,
                decoration: const InputDecoration(
                  labelText: 'Sort By',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _sortOptions.map((option) => DropdownMenuItem(
                  value: option,
                  child: Text(_capitalizeFirst(option)),
                )).toList(),
                onChanged: (value) {
                  setState(() => _sortBy = value ?? 'name');
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                setState(() => _sortAscending = !_sortAscending);
              },
              icon: Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              ),
              tooltip: _sortAscending ? 'Sort Ascending' : 'Sort Descending',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectionToolbar() {
    return AnimatedBuilder(
      animation: _selectionAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(_selectionAnimation),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Text(
                  '${_selectedFileIds.length} selected',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const Spacer(),
                AccessibleButton(
                  onPressed: _selectAll,
                  semanticLabel: 'Select all files',
                  child: const Icon(Icons.select_all),
                ),
                const SizedBox(width: 8),
                AccessibleButton(
                  onPressed: _invertSelection,
                  semanticLabel: 'Invert selection',
                  child: const Icon(Icons.flip_to_back),
                ),
                const SizedBox(width: 8),
                AccessibleButton(
                  onPressed: _selectNone,
                  semanticLabel: 'Clear selection',
                  child: const Icon(Icons.clear_all),
                ),
                const SizedBox(width: 8),
                AccessibleButton(
                  onPressed: _toggleSelectionMode,
                  semanticLabel: 'Exit selection mode',
                  child: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty ? Icons.search_off : Icons.folder_open,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty 
                ? 'No files match your search'
                : 'No files found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFileGrid(List<FileItem> files) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithAdaptiveColumnWidth(
        minColumnWidth: 300,
        columnSpacing: 12,
        rowSpacing: 12,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        final isSelected = _selectedFileIds.contains(file.id);
        
        return MicroInteractions.animatedCard(
          onTap: () {
            if (_isSelectionMode) {
              _toggleFileSelection(file);
            } else {
              widget.onFileAction(file);
            }
          },
          onLongPress: () => _toggleFileSelection(file),
          child: Container(
            decoration: BoxDecoration(
              border: isSelected 
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Card(
              elevation: isSelected ? 8 : 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (_isSelectionMode)
                          Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleFileSelection(file),
                          ),
                        Icon(
                          _getFileIcon(file.type),
                          size: 32,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const Spacer(),
                        PopupMenuButton<String>(
                          onSelected: (action) => _handleFileAction(action, file),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'info',
                              child: ListTile(
                                leading: Icon(Icons.info_outline),
                                title: Text('File Info'),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'location',
                              child: ListTile(
                                leading: Icon(Icons.folder_open),
                                title: Text('Open Location'),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'organize',
                              child: ListTile(
                                leading: Icon(Icons.auto_fix_high),
                                title: Text('Organize'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      file.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatFileSize(file.size),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    Text(
                      _formatDate(file.lastModified),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    if (file.suggestedLocation != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.tertiary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Suggested: ${file.suggestedLocation}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleFileAction(String action, FileItem file) {
    switch (action) {
      case 'info':
        _showFileInfo(file);
        break;
      case 'location':
        _openFileLocation(file);
        break;
      case 'organize':
        widget.onFileAction(file);
        break;
    }
  }

  void _showFileInfo(FileItem file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Name', file.name),
            _buildInfoRow('Type', file.type),
            _buildInfoRow('Size', _formatFileSize(file.size)),
            _buildInfoRow('Modified', _formatDate(file.lastModified)),
            _buildInfoRow('Path', file.path),
            if (file.suggestedLocation != null)
              _buildInfoRow('Suggested Location', file.suggestedLocation!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  void _openFileLocation(FileItem file) {
    // TODO: Implement platform-specific file location opening
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Open location: ${file.path}'),
        action: SnackBarAction(
          label: 'Copy Path',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: file.path));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Path copied to clipboard')),
            );
          },
        ),
      ),
    );
  }

  IconData _getFileIcon(String type) {
    switch (type.toLowerCase()) {
      case 'image':
        return Icons.image_outlined;
      case 'video':
        return Icons.video_file_outlined;
      case 'audio':
        return Icons.audio_file_outlined;
      case 'document':
        return Icons.description_outlined;
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'archive':
        return Icons.archive_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 30) {
      return '${date.day}/${date.month}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return 'Just now';
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

/// Custom grid delegate for adaptive column width
class SliverGridDelegateWithAdaptiveColumnWidth extends SliverGridDelegate {
  final double minColumnWidth;
  final double columnSpacing;
  final double rowSpacing;

  const SliverGridDelegateWithAdaptiveColumnWidth({
    required this.minColumnWidth,
    this.columnSpacing = 0,
    this.rowSpacing = 0,
  });

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final double availableWidth = constraints.crossAxisExtent;
    final int columnCount = (availableWidth / (minColumnWidth + columnSpacing)).floor();
    final double columnWidth = (availableWidth - (columnCount - 1) * columnSpacing) / columnCount;
    
    return SliverGridRegularTileLayout(
      crossAxisCount: columnCount,
      mainAxisStride: 200 + rowSpacing, // Fixed row height + spacing
      crossAxisStride: columnWidth + columnSpacing,
      childMainAxisExtent: 200, // Fixed row height
      childCrossAxisExtent: columnWidth,
      reverseCrossAxis: false,
    );
  }

  @override
  bool shouldRelayout(SliverGridDelegateWithAdaptiveColumnWidth oldDelegate) {
    return minColumnWidth != oldDelegate.minColumnWidth ||
           columnSpacing != oldDelegate.columnSpacing ||
           rowSpacing != oldDelegate.rowSpacing;
  }
}
