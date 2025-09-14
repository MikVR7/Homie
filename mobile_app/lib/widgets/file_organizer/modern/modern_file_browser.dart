import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../animations/skeleton_loading.dart';
import '../../../animations/micro_interactions.dart';
import '../../../animations/material_motion.dart';
import '../../../providers/accessibility_provider.dart';
import '../../../widgets/accessibility/accessible_button.dart';
import '../../../widgets/accessibility/screen_reader_announcer.dart';

class ModernFileBrowser extends StatefulWidget {
  final String? initialPath;
  final Function(String) onPathSelected;
  final bool showHidden;
  final List<String> allowedExtensions;
  final bool isDirectoryMode;
  final String title;

  const ModernFileBrowser({
    Key? key,
    this.initialPath,
    required this.onPathSelected,
    this.showHidden = false,
    this.allowedExtensions = const [],
    this.isDirectoryMode = true,
    this.title = 'Select Folder',
  }) : super(key: key);

  @override
  State<ModernFileBrowser> createState() => _ModernFileBrowserState();
}

class _ModernFileBrowserState extends State<ModernFileBrowser>
    with TickerProviderStateMixin {
  late TextEditingController _pathController;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  String _currentPath = '';
  List<FileSystemEntity> _currentItems = [];
  List<RecentFolder> _recentPaths = [];
  List<BookmarkedFolder> _bookmarkedPaths = [];
  List<String> _breadcrumbs = [];
  List<String> _autocompleteSuggestions = [];
  bool _isLoading = false;
  bool _showAutocompletion = false;
  String? _errorMessage;
  Timer? _autoCompleteTimer;
  OverlayEntry? _autocompleteOverlay;
  final LayerLink _layerLink = LayerLink();
  
  // Keyboard navigation
  int _selectedIndex = -1;
  late FocusNode _browserFocusNode;
  late FocusNode _pathFocusNode;

  @override
  void initState() {
    super.initState();
    
    _pathController = TextEditingController();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));

    // Initialize focus nodes for keyboard navigation
    _browserFocusNode = FocusNode();
    _pathFocusNode = FocusNode();

    _initializeBrowser();
  }

  @override
  void dispose() {
    _pathController.dispose();
    _slideController.dispose();
    _autoCompleteTimer?.cancel();
    // Clean up overlay without setState during dispose
    _autocompleteOverlay?.remove();
    _autocompleteOverlay = null;
    _browserFocusNode.dispose();
    _pathFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeBrowser() async {
    String initialPath = widget.initialPath ?? _getDefaultPath();
    await _navigateToPath(initialPath);
    _loadRecentPaths();
    _loadBookmarks();
    _slideController.forward();
  }

  String _getDefaultPath() {
    if (Platform.isWindows) {
      return 'C:\\';
    } else if (Platform.isMacOS) {
      return '/Users/${Platform.environment['USER'] ?? 'user'}';
    } else {
      return '/home/${Platform.environment['USER'] ?? 'user'}';
    }
  }

  Future<void> _navigateToPath(String newPath) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final directory = Directory(newPath);
      if (!await directory.exists()) {
        throw FileSystemException('Directory does not exist', newPath);
      }

      final items = await directory.list().toList();
      final filteredItems = _filterItems(items);
      filteredItems.sort(_sortItems);

      setState(() {
        _currentPath = newPath;
        _currentItems = filteredItems;
        _pathController.text = newPath;
        _breadcrumbs = _generateBreadcrumbs(newPath);
        _isLoading = false;
      });

      _addToRecentPaths(newPath);
    } catch (e) {
      setState(() {
        _errorMessage = 'Cannot access folder: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<FileSystemEntity> _filterItems(List<FileSystemEntity> items) {
    return items.where((item) {
      final name = path.basename(item.path);
      
      // Filter hidden files if not showing hidden
      if (!widget.showHidden && name.startsWith('.')) return false;
      
      // Always show directories in directory mode
      if (item is Directory) return true;
      
      // In file mode, filter by extensions
      if (!widget.isDirectoryMode && widget.allowedExtensions.isNotEmpty) {
        final extension = path.extension(name).toLowerCase();
        return widget.allowedExtensions.contains(extension);
      }
      
      return !widget.isDirectoryMode; // Show files only in file mode
    }).toList();
  }

  int _sortItems(FileSystemEntity a, FileSystemEntity b) {
    // Directories first
    if (a is Directory && b is File) return -1;
    if (a is File && b is Directory) return 1;
    
    // Then alphabetically
    return path.basename(a.path).toLowerCase()
        .compareTo(path.basename(b.path).toLowerCase());
  }

  List<String> _generateBreadcrumbs(String fullPath) {
    final parts = fullPath.split(Platform.pathSeparator);
    final breadcrumbs = <String>[];
    
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        breadcrumbs.add(parts.sublist(0, i + 1).join(Platform.pathSeparator));
      }
    }
    
    return breadcrumbs;
  }

  Future<void> _addToRecentPaths(String folderPath) async {
    try {
      // Get folder metadata
      final directory = Directory(folderPath);
      if (!await directory.exists()) return;
      
      final items = await directory.list().toList();
      final fileCount = items.where((item) => item is File).length;
      final folderCount = items.where((item) => item is Directory).length;
      
      final recentFolder = RecentFolder(
        path: folderPath,
        displayName: path.basename(folderPath).isEmpty 
            ? folderPath 
            : path.basename(folderPath),
        lastAccessed: DateTime.now(),
        fileCount: fileCount,
        folderCount: folderCount,
        description: 'Accessed ${DateTime.now().toString().split(' ')[0]}',
      );

      setState(() {
        // Remove if already exists
        _recentPaths.removeWhere((item) => item.path == folderPath);
        // Add to front
        _recentPaths.insert(0, recentFolder);
        // Keep only 15 most recent
        if (_recentPaths.length > 15) {
          _recentPaths = _recentPaths.take(15).toList();
        }
      });

      await _saveRecentPaths();
    } catch (e) {
      debugPrint('Error adding to recent paths: $e');
    }
  }

  Future<void> _loadRecentPaths() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentJson = prefs.getStringList('file_browser_recent_paths') ?? [];
      
      setState(() {
        _recentPaths = recentJson
            .map((json) => RecentFolder.fromJson(
                Map<String, dynamic>.from(
                  Uri.decodeComponent(json).split('&').fold<Map<String, String>>({}, (map, pair) {
                    final parts = pair.split('=');
                    if (parts.length == 2) map[parts[0]] = parts[1];
                    return map;
                  })
                )
            ))
            .where((folder) => Directory(folder.path).existsSync())
            .toList();
      });

      // Add default paths if empty
      if (_recentPaths.isEmpty) {
        await _addDefaultRecentPaths();
      }
    } catch (e) {
      debugPrint('Error loading recent paths: $e');
      await _addDefaultRecentPaths();
    }
  }

  Future<void> _saveRecentPaths() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentJson = _recentPaths
          .map((folder) => Uri.encodeComponent(
              folder.toJson().entries
                  .map((e) => '${e.key}=${e.value}')
                  .join('&')
          ))
          .toList();
      await prefs.setStringList('file_browser_recent_paths', recentJson);
    } catch (e) {
      debugPrint('Error saving recent paths: $e');
    }
  }

  Future<void> _addDefaultRecentPaths() async {
    final defaultPaths = [
      _getDefaultPath(),
      if (Platform.isLinux || Platform.isMacOS) '/tmp',
      if (Platform.isWindows) 'C:\\Windows\\Temp',
    ];

    for (final path in defaultPaths) {
      await _addToRecentPaths(path);
    }
  }

  Future<void> _loadBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getStringList('file_browser_bookmarks') ?? [];
      
      setState(() {
        _bookmarkedPaths = bookmarksJson
            .map((json) => BookmarkedFolder.fromJson(
                Map<String, dynamic>.from(
                  Uri.decodeComponent(json).split('&').fold<Map<String, String>>({}, (map, pair) {
                    final parts = pair.split('=');
                    if (parts.length == 2) map[parts[0]] = parts[1];
                    return map;
                  })
                )
            ))
            .where((folder) => Directory(folder.path).existsSync())
            .toList();
      });

      // Add default bookmarks if empty
      if (_bookmarkedPaths.isEmpty) {
        await _addDefaultBookmarks();
      }
    } catch (e) {
      debugPrint('Error loading bookmarks: $e');
      await _addDefaultBookmarks();
    }
  }

  Future<void> _saveBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = _bookmarkedPaths
          .map((folder) => Uri.encodeComponent(
              folder.toJson().entries
                  .map((e) => '${e.key}=${e.value}')
                  .join('&')
          ))
          .toList();
      await prefs.setStringList('file_browser_bookmarks', bookmarksJson);
    } catch (e) {
      debugPrint('Error saving bookmarks: $e');
    }
  }

  Future<void> _addDefaultBookmarks() async {
    final defaultBookmarks = [
      if (Platform.isWindows) ...[
        ('C:\\Users\\${Platform.environment['USERNAME'] ?? 'user'}\\Desktop', 'Desktop', 'home'),
        ('C:\\Users\\${Platform.environment['USERNAME'] ?? 'user'}\\Documents', 'Documents', 'document'),
        ('C:\\Users\\${Platform.environment['USERNAME'] ?? 'user'}\\Downloads', 'Downloads', 'download'),
      ] else ...[
        ('/home/${Platform.environment['USER'] ?? 'user'}/Desktop', 'Desktop', 'home'),
        ('/home/${Platform.environment['USER'] ?? 'user'}/Documents', 'Documents', 'document'),
        ('/home/${Platform.environment['USER'] ?? 'user'}/Downloads', 'Downloads', 'download'),
      ],
    ];

    for (final (path, name, icon) in defaultBookmarks) {
      await _addBookmark(path, name: name, icon: icon);
    }
  }

  Future<void> _addBookmark(String folderPath, {String? name, String? icon, String? category}) async {
    try {
      final bookmark = BookmarkedFolder(
        path: folderPath,
        displayName: name ?? (path.basename(folderPath).isEmpty 
            ? folderPath 
            : path.basename(folderPath)),
        category: category ?? 'General',
        dateAdded: DateTime.now(),
        description: 'Bookmarked on ${DateTime.now().toString().split(' ')[0]}',
        icon: icon ?? 'folder',
      );

      setState(() {
        // Remove if already exists
        _bookmarkedPaths.removeWhere((item) => item.path == folderPath);
        // Add to list
        _bookmarkedPaths.add(bookmark);
      });

      await _saveBookmarks();
    } catch (e) {
      debugPrint('Error adding bookmark: $e');
    }
  }

  Future<void> _removeBookmark(String folderPath) async {
    setState(() {
      _bookmarkedPaths.removeWhere((item) => item.path == folderPath);
    });
    await _saveBookmarks();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccessibilityProvider>(
      builder: (context, accessibilityProvider, _) {
        return ScreenReaderAnnouncer(
          child: KeyboardListener(
            focusNode: _browserFocusNode,
            onKeyEvent: _handleKeyEvent,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool hasBoundedWidth = constraints.hasBoundedWidth;
                  final bool hasBoundedHeight = constraints.hasBoundedHeight;
                  const double fallbackWidth = 1000;
                  const double fallbackHeight = 700;

                  final Widget content = Column(
                    children: [
                      _buildHeader(),
                      _buildPathBar(),
                      if (_errorMessage != null) _buildErrorMessage(),
                      Expanded(
                        child: Row(
                          children: [
                            _buildSidebar(),
                            const VerticalDivider(width: 1),
                            Expanded(
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: _buildFileList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildActionBar(),
                    ],
                  );

                  if (hasBoundedWidth && hasBoundedHeight) {
                    return SizedBox.expand(child: content);
                  } else {
                    return SizedBox(
                      width: hasBoundedWidth ? constraints.maxWidth : fallbackWidth,
                      height: hasBoundedHeight ? constraints.maxHeight : fallbackHeight,
                      child: content,
                    );
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(
            widget.isDirectoryMode ? Icons.folder_open : Icons.file_open,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            widget.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildPathBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _currentPath.isNotEmpty && _breadcrumbs.length > 1
                    ? () => _navigateToPath(path.dirname(_currentPath))
                    : null,
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Go back',
              ),
              Expanded(
                child: CompositedTransformTarget(
                  link: _layerLink,
                  child: TextField(
                    controller: _pathController,
                    decoration: InputDecoration(
                      hintText: 'Enter folder path...',
                      prefixIcon: const Icon(Icons.folder),
                      suffixIcon: _pathController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _pathController.clear();
                                _hideAutocomplete();
                              },
                              icon: const Icon(Icons.clear),
                              tooltip: 'Clear',
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: _onPathChanged,
                    onSubmitted: _navigateToPath,
                    onTap: () {
                      if (_pathController.text.isNotEmpty) {
                        _onPathChanged(_pathController.text);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _navigateToPath(_pathController.text),
                icon: const Icon(Icons.navigate_next),
                tooltip: 'Navigate',
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_breadcrumbs.isNotEmpty) _buildBreadcrumbs(),
        ],
      ),
    );
  }

  void _onPathChanged(String text) {
    _autoCompleteTimer?.cancel();
    
    if (text.isEmpty) {
      _hideAutocomplete();
      return;
    }

    _autoCompleteTimer = Timer(const Duration(milliseconds: 300), () {
      _generateAutocompleteSuggestions(text);
    });
  }

  Future<void> _generateAutocompleteSuggestions(String partialPath) async {
    try {
      final suggestions = <String>[];
      
      // Get parent directory of the partial path
      String parentPath;
      String searchTerm;
      
      if (partialPath.contains(Platform.pathSeparator)) {
        parentPath = path.dirname(partialPath);
        searchTerm = path.basename(partialPath).toLowerCase();
      } else {
        parentPath = _currentPath.isNotEmpty ? _currentPath : _getDefaultPath();
        searchTerm = partialPath.toLowerCase();
      }

      // Check if parent directory exists
      final directory = Directory(parentPath);
      if (await directory.exists()) {
        final items = await directory.list().toList();
        
        for (final item in items) {
          if (item is Directory) {
            final itemName = path.basename(item.path);
            if (itemName.toLowerCase().startsWith(searchTerm)) {
              suggestions.add(item.path);
            }
          }
        }
      }

      // Add recent paths that match
      for (final recent in _recentPaths) {
        final itemName = path.basename(recent.path);
        if (itemName.toLowerCase().contains(searchTerm.toLowerCase()) && 
            !suggestions.contains(recent.path)) {
          suggestions.add(recent.path);
        }
      }

      // Add bookmarked paths that match
      for (final bookmark in _bookmarkedPaths) {
        final itemName = path.basename(bookmark.path);
        if (itemName.toLowerCase().contains(searchTerm.toLowerCase()) && 
            !suggestions.contains(bookmark.path)) {
          suggestions.add(bookmark.path);
        }
      }

      setState(() {
        _autocompleteSuggestions = suggestions.take(8).toList();
        _showAutocompletion = suggestions.isNotEmpty;
      });

      if (suggestions.isNotEmpty) {
        _showAutocompleteOverlay();
      } else {
        _hideAutocomplete();
      }
    } catch (e) {
      debugPrint('Error generating autocomplete suggestions: $e');
    }
  }

  void _showAutocompleteOverlay() {
    _hideAutocomplete(); // Remove existing overlay

    _autocompleteOverlay = OverlayEntry(
      builder: (context) => Positioned(
        width: 400,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 45),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _autocompleteSuggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _autocompleteSuggestions[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.folder,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      path.basename(suggestion).isEmpty 
                          ? suggestion 
                          : path.basename(suggestion),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    subtitle: Text(
                      suggestion,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      _pathController.text = suggestion;
                      _hideAutocomplete();
                      _navigateToPath(suggestion);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_autocompleteOverlay!);
  }

  Widget _buildBreadcrumbs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _breadcrumbs.asMap().entries.map((entry) {
          final index = entry.key;
          final breadcrumbPath = entry.value;
          final isLast = index == _breadcrumbs.length - 1;
          
          return Row(
            children: [
              InkWell(
                onTap: isLast ? null : () => _navigateToPath(breadcrumbPath),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    path.basename(breadcrumbPath).isEmpty 
                        ? breadcrumbPath 
                        : path.basename(breadcrumbPath),
                    style: TextStyle(
                      color: isLast 
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.primary,
                      fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
              if (!isLast) const Icon(Icons.chevron_right, size: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBookmarksSection(),
          const SizedBox(height: 16),
          _buildRecentSection(),
        ],
      ),
    );
  }

  Widget _buildBookmarksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bookmark, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Bookmarks',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._bookmarkedPaths.take(5).map((bookmark) => _buildBookmarkItem(bookmark)),
      ],
    );
  }

  Widget _buildRecentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Recent',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._recentPaths.take(5).map((recent) => _buildRecentItem(recent)),
      ],
    );
  }

  Widget _buildBookmarkItem(BookmarkedFolder bookmark) {
    return InkWell(
      onTap: () => _navigateToPath(bookmark.path),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(bookmark.iconData, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    bookmark.displayName,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _removeBookmark(bookmark.path),
                  child: const Icon(Icons.bookmark_remove, size: 14),
                ),
              ],
            ),
            if (bookmark.description.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                bookmark.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentItem(RecentFolder recent) {
    return InkWell(
      onTap: () => _navigateToPath(recent.path),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.folder, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recent.displayName,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _addBookmark(recent.path),
                  child: Icon(
                    _bookmarkedPaths.any((b) => b.path == recent.path)
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    size: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              recent.summary,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              _formatDate(recent.lastAccessed),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    if (_isLoading) {
      return _buildSkeletonLoader();
    }

    if (_currentItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'This folder is empty',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _currentItems.length,
      itemBuilder: (context, index) {
        final item = _currentItems[index];
        return _buildFileListItem(item);
      },
    );
  }

  Widget _buildSkeletonLoader() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: List.generate(8, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: SkeletonWidgets.fileBrowserItem(
              isLoading: true,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFileListItem(FileSystemEntity item) {
    final isDirectory = item is Directory;
    final name = path.basename(item.path);
    final icon = isDirectory ? Icons.folder : Icons.description;
    
    return MicroInteractions.animatedCard(
      onTap: () => _onItemTapped(item),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDirectory 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.secondary,
        ),
        title: Text(name),
        subtitle: FutureBuilder<FileStat>(
          future: item.stat(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final stat = snapshot.data!;
              final size = isDirectory ? '' : _formatFileSize(stat.size);
              final modified = _formatDate(stat.modified);
              return Text('$size • $modified');
            }
            return const Text('Loading...');
          },
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDirectory)
              MicroInteractions.animatedButton(
                onPressed: () => _addBookmark(item.path),
                child: Icon(
                  _bookmarkedPaths.any((b) => b.path == item.path)
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                ),
              ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(FileSystemEntity item) {
    final isDirectory = item is Directory;
    if (isDirectory) {
      _navigateToPath(item.path);
    } else if (!widget.isDirectoryMode) {
      widget.onPathSelected(item.path);
      Navigator.of(context).pop();
    }
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const Spacer(),
          if (widget.isDirectoryMode)
            ElevatedButton.icon(
              onPressed: _currentPath.isNotEmpty 
                  ? () {
                      widget.onPathSelected(_currentPath);
                      Navigator.of(context).pop();
                    }
                  : null,
              icon: const Icon(Icons.check),
              label: const Text('Select Folder'),
            ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      return '${date.year}';
    } else if (difference.inDays > 30) {
      return '${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return 'Just now';
    }
  }

  // Keyboard navigation methods
  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final accessibilityProvider = context.read<AccessibilityProvider>();
      if (!accessibilityProvider.keyboardNavigationEnabled) return;

      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowDown:
          _moveSelection(1);
          break;
        case LogicalKeyboardKey.arrowUp:
          _moveSelection(-1);
          break;
        case LogicalKeyboardKey.enter:
          _activateSelectedItem();
          break;
        case LogicalKeyboardKey.escape:
          _clearSelection();
          break;
        case LogicalKeyboardKey.f2:
          if (_selectedIndex >= 0 && _selectedIndex < _currentItems.length) {
            _showRenameDialog(_currentItems[_selectedIndex]);
          }
          break;
        case LogicalKeyboardKey.delete:
          if (_selectedIndex >= 0 && _selectedIndex < _currentItems.length) {
            _showDeleteConfirmation(_currentItems[_selectedIndex]);
          }
          break;
      }
    }
  }

  void _moveSelection(int direction) {
    if (_currentItems.isEmpty) return;

    setState(() {
      if (_selectedIndex == -1) {
        _selectedIndex = direction > 0 ? 0 : _currentItems.length - 1;
      } else {
        _selectedIndex = (_selectedIndex + direction).clamp(0, _currentItems.length - 1);
      }
    });

    _announceSelection();
    _ensureSelectionVisible();
  }

  void _activateSelectedItem() {
    if (_selectedIndex >= 0 && _selectedIndex < _currentItems.length) {
      final item = _currentItems[_selectedIndex];
      if (item is Directory) {
        _navigateToPath(item.path);
      } else if (!widget.isDirectoryMode) {
        widget.onPathSelected(item.path);
        Navigator.of(context).pop();
      }
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedIndex = -1;
    });
  }

  void _announceSelection() {
    if (_selectedIndex >= 0 && _selectedIndex < _currentItems.length) {
      final item = _currentItems[_selectedIndex];
      final name = path.basename(item.path);
      final type = item is Directory ? 'folder' : 'file';
      
      final accessibilityProvider = context.read<AccessibilityProvider>();
      if (accessibilityProvider.announceStateChanges) {
        String announcement = '$type $name selected';
        if (accessibilityProvider.verboseDescriptions && item is File) {
          try {
            final size = item.lengthSync();
            final formattedSize = _formatFileSize(size);
            announcement += ', size $formattedSize';
          } catch (e) {
            // File size not available
          }
        }
        SemanticsService.announce(announcement, TextDirection.ltr);
      }
    }
  }

  void _ensureSelectionVisible() {
    // This would scroll to ensure the selected item is visible
    // Implementation depends on the scroll controller being available
  }

  void _showRenameDialog(FileSystemEntity item) {
    final controller = TextEditingController(text: path.basename(item.path));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rename ${item is Directory ? 'Folder' : 'File'}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'New name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final newPath = path.join(path.dirname(item.path), controller.text);
                await item.rename(newPath);
                if (mounted) {
                  Navigator.of(context).pop();
                  _refreshCurrentPath();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to rename: $e')),
                  );
                }
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(FileSystemEntity item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${item is Directory ? 'Folder' : 'File'}'),
        content: Text('Are you sure you want to delete "${path.basename(item.path)}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await item.delete(recursive: item is Directory);
                if (mounted) {
                  Navigator.of(context).pop();
                  _refreshCurrentPath();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _refreshCurrentPath() {
    _navigateToPath(_currentPath);
  }

  void _hideAutocomplete() {
    if (mounted) {
      _autocompleteOverlay?.remove();
      _autocompleteOverlay = null;
      setState(() => _showAutocompletion = false);
    }
  }
}

/// Enhanced model for recent folders with metadata
class RecentFolder {
  final String path;
  final String displayName;
  final DateTime lastAccessed;
  final int fileCount;
  final int folderCount;
  final String description;

  const RecentFolder({
    required this.path,
    required this.displayName,
    required this.lastAccessed,
    this.fileCount = 0,
    this.folderCount = 0,
    this.description = '',
  });

  factory RecentFolder.fromJson(Map<String, dynamic> json) {
    return RecentFolder(
      path: json['path'] ?? '',
      displayName: json['displayName'] ?? '',
      lastAccessed: DateTime.tryParse(json['lastAccessed'] ?? '') ?? DateTime.now(),
      fileCount: json['fileCount'] ?? 0,
      folderCount: json['folderCount'] ?? 0,
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'displayName': displayName,
      'lastAccessed': lastAccessed.toIso8601String(),
      'fileCount': fileCount,
      'folderCount': folderCount,
      'description': description,
    };
  }

  String get summary {
    final items = <String>[];
    if (folderCount > 0) items.add('$folderCount folders');
    if (fileCount > 0) items.add('$fileCount files');
    return items.isEmpty ? 'Empty folder' : items.join(', ');
  }
}

/// Enhanced model for bookmarked folders with metadata
class BookmarkedFolder {
  final String path;
  final String displayName;
  final String category;
  final DateTime dateAdded;
  final String description;
  final String icon;

  const BookmarkedFolder({
    required this.path,
    required this.displayName,
    this.category = 'General',
    required this.dateAdded,
    this.description = '',
    this.icon = 'folder',
  });

  factory BookmarkedFolder.fromJson(Map<String, dynamic> json) {
    return BookmarkedFolder(
      path: json['path'] ?? '',
      displayName: json['displayName'] ?? '',
      category: json['category'] ?? 'General',
      dateAdded: DateTime.tryParse(json['dateAdded'] ?? '') ?? DateTime.now(),
      description: json['description'] ?? '',
      icon: json['icon'] ?? 'folder',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'displayName': displayName,
      'category': category,
      'dateAdded': dateAdded.toIso8601String(),
      'description': description,
      'icon': icon,
    };
  }

  IconData get iconData {
    switch (icon) {
      case 'home': return Icons.home;
      case 'work': return Icons.work;
      case 'download': return Icons.download;
      case 'document': return Icons.description;
      case 'image': return Icons.image;
      case 'music': return Icons.music_note;
      case 'video': return Icons.video_library;
      default: return Icons.folder;
    }
  }
}
