import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../models/file_organizer_models.dart';
import '../../../animations/micro_interactions.dart';
import '../../../animations/skeleton_loading.dart';

/// Advanced search functionality with intelligent filtering and suggestions
class AdvancedSearch extends StatefulWidget {
  final List<FileItem> allFiles;
  final List<FileOperation> allOperations;
  final Function(List<FileItem>) onFilesFound;
  final Function(List<FileOperation>) onOperationsFound;
  final Function(String) onSaveSearch;
  final List<String> savedSearches;

  const AdvancedSearch({
    Key? key,
    required this.allFiles,
    required this.allOperations,
    required this.onFilesFound,
    required this.onOperationsFound,
    required this.onSaveSearch,
    this.savedSearches = const [],
  }) : super(key: key);

  @override
  State<AdvancedSearch> createState() => _AdvancedSearchState();
}

class _AdvancedSearchState extends State<AdvancedSearch>
    with TickerProviderStateMixin {
  late TextEditingController _searchController;
  late AnimationController _searchAnimationController;
  late Animation<double> _searchAnimation;
  
  String _searchQuery = '';
  bool _isSearching = false;
  List<FileItem> _foundFiles = [];
  List<FileOperation> _foundOperations = [];
  List<String> _searchSuggestions = [];
  List<String> _searchHistory = [];
  Timer? _searchDebounceTimer;
  String _selectedSearchType = 'all';
  bool _caseSensitive = false;
  bool _useRegex = false;
  bool _searchInContent = false;
  OverlayEntry? _suggestionOverlay;
  final LayerLink _layerLink = LayerLink();
  
  final List<String> _searchTypes = [
    'all', 'files', 'operations', 'folders', 'content'
  ];

  final List<String> _quickSearchTerms = [
    'today', 'this week', 'images', 'videos', 'documents', 
    'large files', 'recent', 'duplicates', 'organized', 'unorganized'
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _searchAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _loadSearchHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchAnimationController.dispose();
    _searchDebounceTimer?.cancel();
    _suggestionOverlay?.remove();
    super.dispose();
  }

  void _loadSearchHistory() {
    // TODO: Load from shared preferences
    setState(() {
      _searchHistory = [
        'vacation photos',
        'work documents',
        'music files',
        'project files',
      ];
    });
  }

  void _saveSearchToHistory(String query) {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _searchHistory.remove(query);
      _searchHistory.insert(0, query);
      if (_searchHistory.length > 10) {
        _searchHistory = _searchHistory.take(10).toList();
      }
    });
    
    // TODO: Save to shared preferences
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _foundFiles = [];
        _foundOperations = [];
        _isSearching = false;
      });
      widget.onFilesFound([]);
      widget.onOperationsFound([]);
      return;
    }

    setState(() => _isSearching = true);
    _searchAnimationController.forward();

    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _executeSearch(query);
    });
  }

  void _executeSearch(String query) async {
    try {
      final searchTerms = _parseSearchQuery(query);
      final foundFiles = <FileItem>[];
      final foundOperations = <FileOperation>[];

      // Search files
      if (_selectedSearchType == 'all' || _selectedSearchType == 'files') {
        for (final file in widget.allFiles) {
          if (_matchesSearchCriteria(file, searchTerms)) {
            foundFiles.add(file);
          }
        }
      }

      // Search operations
      if (_selectedSearchType == 'all' || _selectedSearchType == 'operations') {
        for (final operation in widget.allOperations) {
          if (_matchesOperationCriteria(operation, searchTerms)) {
            foundOperations.add(operation);
          }
        }
      }

      // Search folder content
      if (_selectedSearchType == 'folders' || _selectedSearchType == 'all') {
        final folderResults = await _searchInFolders(searchTerms);
        foundFiles.addAll(folderResults);
      }

      // Content search (if enabled)
      if (_searchInContent && (_selectedSearchType == 'content' || _selectedSearchType == 'all')) {
        final contentResults = await _searchInFileContent(searchTerms);
        foundFiles.addAll(contentResults);
      }

      // Remove duplicates
      final uniqueFiles = foundFiles.toSet().toList();
      final uniqueOperations = foundOperations.toSet().toList();

      setState(() {
        _foundFiles = uniqueFiles;
        _foundOperations = uniqueOperations;
        _isSearching = false;
      });

      widget.onFilesFound(uniqueFiles);
      widget.onOperationsFound(uniqueOperations);
      
      _saveSearchToHistory(query);
      
    } catch (e) {
      setState(() => _isSearching = false);
      _showSearchError('Search failed: $e');
    }
  }

  List<String> _parseSearchQuery(String query) {
    if (_useRegex) {
      return [query]; // Use the query as-is for regex
    }
    
    // Parse quoted phrases and individual terms
    final terms = <String>[];
    final regex = RegExp(r'"([^"]*)"|\S+');
    final matches = regex.allMatches(query);
    
    for (final match in matches) {
      final term = match.group(1) ?? match.group(0)!;
      terms.add(_caseSensitive ? term : term.toLowerCase());
    }
    
    return terms;
  }

  bool _matchesSearchCriteria(FileItem file, List<String> searchTerms) {
    final fileName = _caseSensitive ? file.name : file.name.toLowerCase();
    final filePath = _caseSensitive ? file.path : file.path.toLowerCase();
    final fileType = _caseSensitive ? file.type : file.type.toLowerCase();
    
    if (_useRegex && searchTerms.isNotEmpty) {
      try {
        final pattern = RegExp(searchTerms.first, caseSensitive: _caseSensitive);
        return pattern.hasMatch(fileName) || 
               pattern.hasMatch(filePath) || 
               pattern.hasMatch(fileType);
      } catch (e) {
        return false; // Invalid regex
      }
    }
    
    // Check if all terms match
    for (final term in searchTerms) {
      bool termMatches = false;
      
      // Special search terms
      if (term == 'today') {
        final today = DateTime.now();
        termMatches = _isSameDay(file.lastModified, today);
      } else if (term == 'this week') {
        final weekAgo = DateTime.now().subtract(const Duration(days: 7));
        termMatches = file.lastModified.isAfter(weekAgo);
      } else if (term == 'large files') {
        termMatches = file.size > 100 * 1024 * 1024; // > 100MB
      } else if (term == 'recent') {
        final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
        termMatches = file.lastModified.isAfter(threeDaysAgo);
      } else if (term == 'organized') {
        termMatches = file.suggestedLocation != null;
      } else if (term == 'unorganized') {
        termMatches = file.suggestedLocation == null;
      } else {
        // Regular text search
        termMatches = fileName.contains(term) ||
                     filePath.contains(term) ||
                     fileType.contains(term);
      }
      
      if (!termMatches) return false;
    }
    
    return true;
  }

  bool _matchesOperationCriteria(FileOperation operation, List<String> searchTerms) {
    final operationType = _caseSensitive ? operation.type : operation.type.toLowerCase();
    final sourcePath = _caseSensitive ? operation.sourcePath : operation.sourcePath.toLowerCase();
    final destinationPath = _caseSensitive ? (operation.destinationPath ?? '') : (operation.destinationPath ?? '').toLowerCase();
    final reasoning = _caseSensitive ? (operation.reasoning ?? '') : (operation.reasoning ?? '').toLowerCase();
    
    if (_useRegex && searchTerms.isNotEmpty) {
      try {
        final pattern = RegExp(searchTerms.first, caseSensitive: _caseSensitive);
        return pattern.hasMatch(operationType) ||
               pattern.hasMatch(sourcePath) ||
               pattern.hasMatch(destinationPath) ||
               pattern.hasMatch(reasoning);
      } catch (e) {
        return false;
      }
    }
    
    for (final term in searchTerms) {
      bool termMatches = operationType.contains(term) ||
                        sourcePath.contains(term) ||
                        destinationPath.contains(term) ||
                        reasoning.contains(term);
      
      if (!termMatches) return false;
    }
    
    return true;
  }

  Future<List<FileItem>> _searchInFolders(List<String> searchTerms) async {
    // TODO: Implement folder content search
    // This would involve scanning directories for files matching the criteria
    return [];
  }

  Future<List<FileItem>> _searchInFileContent(List<String> searchTerms) async {
    // TODO: Implement content search for text files, PDFs, documents
    // This would involve reading file contents and searching within them
    return [];
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  void _generateSuggestions(String query) {
    if (query.isEmpty) {
      _hideSuggestions();
      return;
    }

    final suggestions = <String>[];
    
    // Add search history matches
    for (final historyItem in _searchHistory) {
      if (historyItem.toLowerCase().contains(query.toLowerCase())) {
        suggestions.add(historyItem);
      }
    }
    
    // Add quick search terms
    for (final term in _quickSearchTerms) {
      if (term.toLowerCase().contains(query.toLowerCase()) && !suggestions.contains(term)) {
        suggestions.add(term);
      }
    }
    
    // Add file type suggestions
    final uniqueTypes = widget.allFiles.map((f) => f.type).toSet();
    for (final type in uniqueTypes) {
      if (type.toLowerCase().contains(query.toLowerCase()) && !suggestions.contains(type)) {
        suggestions.add(type);
      }
    }
    
    setState(() {
      _searchSuggestions = suggestions.take(8).toList();
    });
    
    if (suggestions.isNotEmpty) {
      _showSuggestionOverlay();
    } else {
      _hideSuggestions();
    }
  }

  void _showSuggestionOverlay() {
    _hideSuggestions();
    
    _suggestionOverlay = OverlayEntry(
      builder: (context) => Positioned(
        width: 400,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 50),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _searchSuggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _searchSuggestions[index];
                  final isFromHistory = _searchHistory.contains(suggestion);
                  
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      isFromHistory ? Icons.history : Icons.search,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      suggestion,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    trailing: isFromHistory 
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () => _removeFromHistory(suggestion),
                          )
                        : null,
                    onTap: () {
                      _searchController.text = suggestion;
                      _searchQuery = suggestion;
                      _hideSuggestions();
                      _performSearch(suggestion);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    
    Overlay.of(context).insert(_suggestionOverlay!);
  }

  void _hideSuggestions() {
    _suggestionOverlay?.remove();
    _suggestionOverlay = null;
  }

  void _removeFromHistory(String item) {
    setState(() {
      _searchHistory.remove(item);
      _searchSuggestions.remove(item);
    });
    
    if (_searchSuggestions.isEmpty) {
      _hideSuggestions();
    }
  }

  void _showSearchError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        _buildSearchOptions(),
        if (_isSearching) _buildSearchProgress(),
        Expanded(child: _buildSearchResults()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: CompositedTransformTarget(
        link: _layerLink,
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search files, operations, and content...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                      _performSearch('');
                      _hideSuggestions();
                    },
                    icon: const Icon(Icons.clear),
                  ),
                IconButton(
                  onPressed: _showAdvancedOptions,
                  icon: const Icon(Icons.tune),
                  tooltip: 'Advanced Search Options',
                ),
              ],
            ),
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
            _performSearch(value);
            _generateSuggestions(value);
          },
          onSubmitted: (value) {
            _hideSuggestions();
            _performSearch(value);
          },
          onTap: () {
            if (_searchController.text.isNotEmpty) {
              _generateSuggestions(_searchController.text);
            }
          },
        ),
      ),
    );
  }

  Widget _buildSearchOptions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            DropdownButton<String>(
              value: _selectedSearchType,
              items: _searchTypes.map((type) => DropdownMenuItem(
                value: type,
                child: Text(_capitalizeFirst(type)),
              )).toList(),
              onChanged: (value) {
                setState(() => _selectedSearchType = value ?? 'all');
                if (_searchQuery.isNotEmpty) {
                  _performSearch(_searchQuery);
                }
              },
            ),
            const SizedBox(width: 16),
            ..._quickSearchTerms.take(3).map((term) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(term),
                onPressed: () {
                  _searchController.text = term;
                  _searchQuery = term;
                  _performSearch(term);
                },
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchProgress() {
    return AnimatedBuilder(
      animation: _searchAnimation,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              'Searching...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      builder: (context, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(_searchAnimation),
          child: child,
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (_searchQuery.isEmpty) {
      return _buildSearchHelp();
    }

    if (_isSearching) {
      return _buildSearchSkeleton();
    }

    if (_foundFiles.isEmpty && _foundOperations.isEmpty) {
      return _buildNoResults();
    }

    return _buildResultsList();
  }

  Widget _buildSearchHelp() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Advanced Search',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search through files, operations, and content',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickSearchTerms.map((term) => ActionChip(
              label: Text(term),
              onPressed: () {
                _searchController.text = term;
                _searchQuery = term;
                _performSearch(term);
              },
            )).toList(),
          ),
          if (_searchHistory.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Recent Searches',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...(_searchHistory.take(5).map((search) => ListTile(
              leading: const Icon(Icons.history),
              title: Text(search),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => _removeFromHistory(search),
              ),
              onTap: () {
                _searchController.text = search;
                _searchQuery = search;
                _performSearch(search);
              },
            ))),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(5, (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SkeletonWidgets.listItem(isLoading: true),
        )),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search terms or filters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
              _performSearch('');
            },
            icon: const Icon(Icons.clear),
            label: const Text('Clear Search'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_foundFiles.isNotEmpty) ...[
          Text(
            'Files (${_foundFiles.length})',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ..._foundFiles.map((file) => _buildFileResultItem(file)),
          const SizedBox(height: 24),
        ],
        if (_foundOperations.isNotEmpty) ...[
          Text(
            'Operations (${_foundOperations.length})',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ..._foundOperations.map((operation) => _buildOperationResultItem(operation)),
        ],
      ],
    );
  }

  Widget _buildFileResultItem(FileItem file) {
    return MicroInteractions.animatedCard(
      onTap: () => _showFileDetails(file),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Icon(
            _getFileIcon(file.type),
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            file.name,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                file.path,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${_formatFileSize(file.size)} • ${_formatDate(file.lastModified)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showFileOptions(file),
          ),
        ),
      ),
    );
  }

  Widget _buildOperationResultItem(FileOperation operation) {
    return MicroInteractions.animatedCard(
      onTap: () => _showOperationDetails(operation),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Icon(
            _getOperationIcon(operation.type),
            color: Theme.of(context).colorScheme.secondary,
          ),
          title: Text(
            operation.type.toUpperCase(),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'From: ${operation.sourcePath}',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (operation.destinationPath != null)
                Text(
                  'To: ${operation.destinationPath}',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          trailing: Chip(
            label: Text('${(operation.confidence * 100).toInt()}%'),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          ),
        ),
      ),
    );
  }

  void _showFileDetails(FileItem file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(file.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Type', file.type),
            _buildDetailRow('Size', _formatFileSize(file.size)),
            _buildDetailRow('Modified', _formatDate(file.lastModified)),
            _buildDetailRow('Path', file.path),
            if (file.suggestedLocation != null)
              _buildDetailRow('Suggested Location', file.suggestedLocation!),
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

  void _showOperationDetails(FileOperation operation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${operation.type.toUpperCase()} Operation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Source', operation.sourcePath),
            if (operation.destinationPath != null)
              _buildDetailRow('Destination', operation.destinationPath!),
            _buildDetailRow('Confidence', '${(operation.confidence * 100).toInt()}%'),
            if (operation.reasoning != null)
              _buildDetailRow('Reasoning', operation.reasoning!),
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

  Widget _buildDetailRow(String label, String value) {
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

  void _showFileOptions(FileItem file) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('Open Location'),
              onTap: () {
                Navigator.pop(context);
                _openFileLocation(file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_fix_high),
              title: const Text('Organize'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Trigger file organization
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openFileLocation(FileItem file) {
    Clipboard.setData(ClipboardData(text: file.path));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File path copied to clipboard')),
    );
  }

  void _showAdvancedOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Advanced Search Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Case Sensitive'),
              value: _caseSensitive,
              onChanged: (value) {
                setState(() => _caseSensitive = value);
                if (_searchQuery.isNotEmpty) {
                  _performSearch(_searchQuery);
                }
              },
            ),
            SwitchListTile(
              title: const Text('Use Regular Expressions'),
              value: _useRegex,
              onChanged: (value) {
                setState(() => _useRegex = value);
                if (_searchQuery.isNotEmpty) {
                  _performSearch(_searchQuery);
                }
              },
            ),
            SwitchListTile(
              title: const Text('Search in File Content'),
              subtitle: const Text('May be slower for large files'),
              value: _searchInContent,
              onChanged: (value) {
                setState(() => _searchInContent = value);
                if (_searchQuery.isNotEmpty) {
                  _performSearch(_searchQuery);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (_searchQuery.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onSaveSearch(_searchQuery);
              },
              child: const Text('Save Search'),
            ),
        ],
      ),
    );
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

  IconData _getOperationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'move': return Icons.drive_file_move;
      case 'copy': return Icons.copy;
      case 'delete': return Icons.delete;
      case 'rename': return Icons.drive_file_rename_outline;
      default: return Icons.settings;
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
