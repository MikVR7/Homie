import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../performance/virtual_list_view.dart';
import '../../performance/lazy_image_loader.dart';
import '../../performance/efficient_state_manager.dart';
import '../../../providers/file_organizer_provider.dart';
import '../../../utils/memory_manager.dart';
import '../../../models/file_info.dart';

/// Optimized file browser with performance enhancements
class OptimizedFileBrowser extends StatefulWidget {
  final String currentPath;
  final Function(String)? onPathChanged;
  final Function(FileInfo)? onFileSelected;
  final bool enableThumbnails;
  final bool enableVirtualScrolling;
  final double itemHeight;
  final int maxCachedThumbnails;

  const OptimizedFileBrowser({
    Key? key,
    required this.currentPath,
    this.onPathChanged,
    this.onFileSelected,
    this.enableThumbnails = true,
    this.enableVirtualScrolling = true,
    this.itemHeight = 72.0,
    this.maxCachedThumbnails = 100,
  }) : super(key: key);

  @override
  State<OptimizedFileBrowser> createState() => _OptimizedFileBrowserState();
}

class _OptimizedFileBrowserState extends State<OptimizedFileBrowser>
    with AutomaticKeepAliveStateMixin {
  late EfficientStateManager<FileBrowserState> _stateManager;
  late MemoryManager _memoryManager;
  final ScrollController _scrollController = ScrollController();
  
  List<FileInfo> _files = [];
  bool _isLoading = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeManagers();
    _loadFiles();
  }

  @override
  void didUpdateWidget(OptimizedFileBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPath != widget.currentPath) {
      _loadFiles();
    }
  }

  @override
  void dispose() {
    _stateManager.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeManagers() {
    _stateManager = EfficientStateManager<FileBrowserState>(
      FileBrowserState(
        files: [],
        isLoading: false,
        error: null,
        currentPath: widget.currentPath,
      ),
    );

    _memoryManager = MemoryManager();
    _memoryManager.initialize(
      maxMemoryUsage: 50 * 1024 * 1024, // 50MB for file browser
      enableAutoCleanup: true,
    );
  }

  Future<void> _loadFiles() async {
    if (_isLoading) return;

    _stateManager.setProperty('isLoading', true);
    _stateManager.setProperty('error', null);

    try {
      final directory = Directory(widget.currentPath);
      if (!await directory.exists()) {
        throw FileSystemException('Directory does not exist', widget.currentPath);
      }

      // Load files in chunks to prevent UI blocking
      final entities = await directory.list().toList();
      final files = <FileInfo>[];

      await _memoryManager.processLargeDataset<void>(
        entities,
        (entity) {
          if (entity is File || entity is Directory) {
            files.add(FileInfo.fromFileSystemEntity(entity));
          }
        },
        chunkSize: 100,
        onProgress: (processed, total) {
          _stateManager.setProperty('loadingProgress', processed / total);
        },
      );

      // Sort files efficiently
      final processor = DataProcessor<FileInfo>();
      final sortedFiles = await processor.sortInChunks(
        files,
        (a, b) {
          // Directories first, then files
          if (a.isDirectory && !b.isDirectory) return -1;
          if (!a.isDirectory && b.isDirectory) return 1;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        },
      );

      _stateManager.updateProperties({
        'files': sortedFiles,
        'isLoading': false,
        'loadingProgress': 1.0,
      });

      setState(() {
        _files = sortedFiles;
        _isLoading = false;
        _error = null;
      });

    } catch (e) {
      _stateManager.updateProperties({
        'isLoading': false,
        'error': e.toString(),
      });

      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Column(
      children: [
        _buildPathBar(),
        Expanded(
          child: _buildFileList(),
        ),
      ],
    );
  }

  Widget _buildPathBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _canGoUp() ? _goUp : null,
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Go up',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildBreadcrumbs(),
          ),
          IconButton(
            onPressed: _loadFiles,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs() {
    final pathParts = widget.currentPath.split(Platform.pathSeparator)
        .where((part) => part.isNotEmpty)
        .toList();
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildBreadcrumbItem('/', '/'),
          for (int i = 0; i < pathParts.length; i++)
            Row(
              children: [
                const Icon(Icons.chevron_right, size: 16),
                _buildBreadcrumbItem(
                  pathParts[i],
                  '/${pathParts.sublist(0, i + 1).join('/')}',
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbItem(String name, String path) {
    final isCurrentPath = path == widget.currentPath;
    
    return TextButton(
      onPressed: isCurrentPath ? null : () => _navigateToPath(path),
      style: TextButton.styleFrom(
        foregroundColor: isCurrentPath 
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontWeight: isCurrentPath ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildFileList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading files...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading files',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFiles,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_files.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('This folder is empty'),
          ],
        ),
      );
    }

    if (widget.enableVirtualScrolling && _files.length > 100) {
      return _buildVirtualizedList();
    } else {
      return _buildRegularList();
    }
  }

  Widget _buildVirtualizedList() {
    return OptimizedVirtualListView<FileInfo>(
      items: _files,
      itemHeightBuilder: (file, index) => widget.itemHeight,
      defaultItemHeight: widget.itemHeight,
      controller: _scrollController,
      enableCaching: true,
      maxCacheSize: widget.maxCachedThumbnails,
      enableMetrics: true,
      onMetricsUpdate: (metrics) {
        // Log performance metrics in debug mode
        debugPrint('Virtual list metrics: $metrics');
      },
      itemBuilder: (context, file, index) => _buildFileItem(file, index),
      emptyWidget: const Center(
        child: Text('No files found'),
      ),
    );
  }

  Widget _buildRegularList() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _files.length,
      itemBuilder: (context, index) => _buildFileItem(_files[index], index),
    );
  }

  Widget _buildFileItem(FileInfo file, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: _buildFileIcon(file),
        title: Text(
          file.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: _buildFileSubtitle(file),
        trailing: _buildFileTrailing(file),
        onTap: () => _handleFileTap(file),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildFileIcon(FileInfo file) {
    if (file.isDirectory) {
      return const Icon(Icons.folder, size: 40, color: Colors.blue);
    }

    if (widget.enableThumbnails && _isImageFile(file)) {
      return LazyThumbnailLoader(
        filePath: file.path,
        size: 40,
        enableCaching: true,
        placeholder: const Icon(Icons.image, size: 40, color: Colors.grey),
        errorWidget: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
      );
    }

    return Icon(
      _getFileIcon(file),
      size: 40,
      color: _getFileIconColor(file),
    );
  }

  Widget _buildFileSubtitle(FileInfo file) {
    final parts = <String>[];
    
    if (!file.isDirectory) {
      parts.add(_formatFileSize(file.size));
    }
    
    if (file.lastModified != null) {
      parts.add(_formatDate(file.lastModified!));
    }

    return Text(
      parts.join(' • '),
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  Widget? _buildFileTrailing(FileInfo file) {
    if (file.isDirectory) {
      return const Icon(Icons.chevron_right);
    }
    return null;
  }

  void _handleFileTap(FileInfo file) {
    if (file.isDirectory) {
      _navigateToPath(file.path);
    } else {
      widget.onFileSelected?.call(file);
    }
  }

  void _navigateToPath(String path) {
    widget.onPathChanged?.call(path);
  }

  bool _canGoUp() {
    return widget.currentPath != '/' && widget.currentPath.isNotEmpty;
  }

  void _goUp() {
    if (!_canGoUp()) return;
    
    final parentPath = Directory(widget.currentPath).parent.path;
    _navigateToPath(parentPath);
  }

  bool _isImageFile(FileInfo file) {
    final extension = file.extension.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  IconData _getFileIcon(FileInfo file) {
    final extension = file.extension.toLowerCase();
    
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
      case 'md':
        return Icons.text_snippet;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'mkv':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'aac':
        return Icons.audio_file;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileIconColor(FileInfo file) {
    final extension = file.extension.toLowerCase();
    
    switch (extension) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'txt':
      case 'md':
        return Colors.grey;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return Colors.purple;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'mkv':
        return Colors.indigo;
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'aac':
        return Colors.teal;
      case 'zip':
      case 'rar':
      case '7z':
        return Colors.brown;
      default:
        return Colors.grey;
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
    
    if (difference.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// State class for efficient state management
class FileBrowserState {
  final List<FileInfo> files;
  final bool isLoading;
  final String? error;
  final String currentPath;
  final double loadingProgress;

  const FileBrowserState({
    required this.files,
    required this.isLoading,
    required this.error,
    required this.currentPath,
    this.loadingProgress = 0.0,
  });

  FileBrowserState copyWith({
    List<FileInfo>? files,
    bool? isLoading,
    String? error,
    String? currentPath,
    double? loadingProgress,
  }) {
    return FileBrowserState(
      files: files ?? this.files,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentPath: currentPath ?? this.currentPath,
      loadingProgress: loadingProgress ?? this.loadingProgress,
    );
  }
}

/// Performance-optimized file info model
class FileInfo {
  final String name;
  final String path;
  final String extension;
  final bool isDirectory;
  final int size;
  final DateTime? lastModified;

  const FileInfo({
    required this.name,
    required this.path,
    required this.extension,
    required this.isDirectory,
    required this.size,
    this.lastModified,
  });

  factory FileInfo.fromFileSystemEntity(FileSystemEntity entity) {
    final stat = entity.statSync();
    final name = entity.path.split(Platform.pathSeparator).last;
    final extension = entity is File 
        ? name.contains('.') ? name.split('.').last : ''
        : '';

    return FileInfo(
      name: name,
      path: entity.path,
      extension: extension,
      isDirectory: entity is Directory,
      size: stat.size,
      lastModified: stat.modified,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileInfo &&
        other.path == path &&
        other.size == size &&
        other.lastModified == lastModified;
  }

  @override
  int get hashCode => Object.hash(path, size, lastModified);
}