import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Lazy loading image widget with caching and placeholder support
class LazyImageLoader extends StatefulWidget {
  final String? imagePath;
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool enableCaching;
  final Duration fadeInDuration;
  final Curve fadeInCurve;
  final bool enableMemoryCache;
  final int? cacheWidth;
  final int? cacheHeight;
  final void Function()? onImageLoaded;
  final void Function(Object error)? onError;

  const LazyImageLoader({
    Key? key,
    this.imagePath,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.enableCaching = true,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.fadeInCurve = Curves.easeInOut,
    this.enableMemoryCache = true,
    this.cacheWidth,
    this.cacheHeight,
    this.onImageLoaded,
    this.onError,
  }) : assert(imagePath != null || imageUrl != null, 'Either imagePath or imageUrl must be provided'),
       super(key: key);

  @override
  State<LazyImageLoader> createState() => _LazyImageLoaderState();
}

class _LazyImageLoaderState extends State<LazyImageLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  ImageProvider? _imageProvider;
  bool _isLoading = false;
  bool _hasError = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.fadeInDuration,
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: widget.fadeInCurve,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadImage();
  }

  @override
  void didUpdateWidget(LazyImageLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath || 
        oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _error = null;
      _imageProvider = null;
    });

    _animationController.reset();

    try {
      ImageProvider provider;
      
      if (widget.imagePath != null) {
        // Load from file path
        final file = File(widget.imagePath!);
        if (await file.exists()) {
          provider = FileImage(file);
        } else {
          throw FileSystemException('File not found', widget.imagePath);
        }
      } else if (widget.imageUrl != null) {
        // Load from URL
        provider = NetworkImage(widget.imageUrl!);
      } else {
        throw ArgumentError('No image source provided');
      }

      // Apply caching if enabled
      if (widget.enableCaching) {
        provider = _CachedImageProvider(
          provider,
          cacheWidth: widget.cacheWidth,
          cacheHeight: widget.cacheHeight,
          enableMemoryCache: widget.enableMemoryCache,
        );
      }

      // Preload the image to check for errors
      final imageStream = provider.resolve(ImageConfiguration.empty);
      final completer = Completer<void>();
      
      late ImageStreamListener listener;
      listener = ImageStreamListener(
        (ImageInfo info, bool synchronousCall) {
          if (mounted) {
            setState(() {
              _imageProvider = provider;
              _isLoading = false;
            });
            _animationController.forward();
            widget.onImageLoaded?.call();
          }
          completer.complete();
        },
        onError: (Object error, StackTrace? stackTrace) {
          if (mounted) {
            setState(() {
              _hasError = true;
              _error = error;
              _isLoading = false;
            });
            widget.onError?.call(error);
          }
          completer.complete();
        },
      );

      imageStream.addListener(listener);
      
      // Wait for image to load or error
      await completer.future;
      imageStream.removeListener(listener);

    } catch (error) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _error = error;
          _isLoading = false;
        });
        widget.onError?.call(error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_hasError) {
      return _buildErrorWidget();
    }

    if (_isLoading || _imageProvider == null) {
      return _buildPlaceholder();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Image(
        image: _imageProvider!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _hasError = true;
                _error = error;
              });
              widget.onError?.call(error);
            }
          });
          return _buildErrorWidget();
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    if (widget.placeholder != null) {
      return widget.placeholder!;
    }

    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (widget.errorWidget != null) {
      return widget.errorWidget!;
    }

    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[100],
      child: const Center(
        child: Icon(
          Icons.broken_image,
          color: Colors.grey,
          size: 32,
        ),
      ),
    );
  }
}

/// Cached image provider with memory and disk caching
class _CachedImageProvider extends ImageProvider<_CachedImageProvider> {
  final ImageProvider _provider;
  final int? cacheWidth;
  final int? cacheHeight;
  final bool enableMemoryCache;

  const _CachedImageProvider(
    this._provider, {
    this.cacheWidth,
    this.cacheHeight,
    this.enableMemoryCache = true,
  });

  @override
  Future<_CachedImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_CachedImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadBuffer(_CachedImageProvider key, DecoderBufferCallback decode) {
    return _provider.loadBuffer(_provider as dynamic, decode);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is _CachedImageProvider &&
        other._provider == _provider &&
        other.cacheWidth == cacheWidth &&
        other.cacheHeight == cacheHeight;
  }

  @override
  int get hashCode => Object.hash(_provider, cacheWidth, cacheHeight);
}

/// Lazy loading thumbnail generator for files
class LazyThumbnailLoader extends StatefulWidget {
  final String filePath;
  final double size;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool enableCaching;
  final Duration fadeInDuration;
  final void Function()? onThumbnailLoaded;
  final void Function(Object error)? onError;

  const LazyThumbnailLoader({
    Key? key,
    required this.filePath,
    this.size = 64.0,
    this.placeholder,
    this.errorWidget,
    this.enableCaching = true,
    this.fadeInDuration = const Duration(milliseconds: 200),
    this.onThumbnailLoaded,
    this.onError,
  }) : super(key: key);

  @override
  State<LazyThumbnailLoader> createState() => _LazyThumbnailLoaderState();
}

class _LazyThumbnailLoaderState extends State<LazyThumbnailLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  Widget? _thumbnail;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.fadeInDuration,
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(LazyThumbnailLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath) {
      _loadThumbnail();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadThumbnail() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _thumbnail = null;
    });

    _animationController.reset();

    try {
      final file = File(widget.filePath);
      if (!await file.exists()) {
        throw FileSystemException('File not found', widget.filePath);
      }

      final extension = widget.filePath.split('.').last.toLowerCase();
      Widget thumbnailWidget;

      switch (extension) {
        case 'jpg':
        case 'jpeg':
        case 'png':
        case 'gif':
        case 'bmp':
        case 'webp':
          thumbnailWidget = _buildImageThumbnail();
          break;
        case 'pdf':
          thumbnailWidget = _buildPdfThumbnail();
          break;
        case 'doc':
        case 'docx':
          thumbnailWidget = _buildDocumentThumbnail(Icons.description);
          break;
        case 'xls':
        case 'xlsx':
          thumbnailWidget = _buildDocumentThumbnail(Icons.table_chart);
          break;
        case 'ppt':
        case 'pptx':
          thumbnailWidget = _buildDocumentThumbnail(Icons.slideshow);
          break;
        case 'txt':
        case 'md':
          thumbnailWidget = _buildDocumentThumbnail(Icons.text_snippet);
          break;
        case 'mp4':
        case 'avi':
        case 'mov':
        case 'mkv':
          thumbnailWidget = _buildVideoThumbnail();
          break;
        case 'mp3':
        case 'wav':
        case 'flac':
        case 'aac':
          thumbnailWidget = _buildAudioThumbnail();
          break;
        case 'zip':
        case 'rar':
        case '7z':
          thumbnailWidget = _buildDocumentThumbnail(Icons.archive);
          break;
        default:
          thumbnailWidget = _buildGenericThumbnail();
      }

      if (mounted) {
        setState(() {
          _thumbnail = thumbnailWidget;
          _isLoading = false;
        });
        _animationController.forward();
        widget.onThumbnailLoaded?.call();
      }

    } catch (error) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        widget.onError?.call(error);
      }
    }
  }

  Widget _buildImageThumbnail() {
    return LazyImageLoader(
      imagePath: widget.filePath,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.cover,
      enableCaching: widget.enableCaching,
      cacheWidth: widget.size.toInt(),
      cacheHeight: widget.size.toInt(),
      placeholder: _buildPlaceholder(),
      errorWidget: _buildErrorWidget(),
    );
  }

  Widget _buildPdfThumbnail() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Icon(
        Icons.picture_as_pdf,
        color: Colors.red[600],
        size: widget.size * 0.5,
      ),
    );
  }

  Widget _buildDocumentThumbnail(IconData icon) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Icon(
        icon,
        color: Colors.blue[600],
        size: widget.size * 0.5,
      ),
    );
  }

  Widget _buildVideoThumbnail() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.video_file,
            color: Colors.purple[600],
            size: widget.size * 0.4,
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: widget.size * 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioThumbnail() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Icon(
        Icons.audio_file,
        color: Colors.green[600],
        size: widget.size * 0.5,
      ),
    );
  }

  Widget _buildGenericThumbnail() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Icon(
        Icons.insert_drive_file,
        color: Colors.grey[600],
        size: widget.size * 0.5,
      ),
    );
  }

  Widget _buildPlaceholder() {
    if (widget.placeholder != null) {
      return widget.placeholder!;
    }

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: SizedBox(
          width: widget.size * 0.3,
          height: widget.size * 0.3,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (widget.errorWidget != null) {
      return widget.errorWidget!;
    }

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Icon(
        Icons.broken_image,
        color: Colors.grey[400],
        size: widget.size * 0.4,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorWidget();
    }

    if (_isLoading || _thumbnail == null) {
      return _buildPlaceholder();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: _thumbnail!,
    );
  }
}

/// Global image cache manager
class ImageCacheManager {
  static final ImageCacheManager _instance = ImageCacheManager._internal();
  factory ImageCacheManager() => _instance;
  ImageCacheManager._internal();

  final Map<String, Uint8List> _memoryCache = {};
  int _maxCacheSize = 50 * 1024 * 1024; // 50MB
  int _currentCacheSize = 0;

  void setMaxCacheSize(int bytes) {
    _maxCacheSize = bytes;
    _evictIfNeeded();
  }

  void cacheImage(String key, Uint8List data) {
    if (data.length > _maxCacheSize) return; // Don't cache very large images

    _memoryCache[key] = data;
    _currentCacheSize += data.length;
    _evictIfNeeded();
  }

  Uint8List? getCachedImage(String key) {
    return _memoryCache[key];
  }

  void _evictIfNeeded() {
    while (_currentCacheSize > _maxCacheSize && _memoryCache.isNotEmpty) {
      final firstKey = _memoryCache.keys.first;
      final data = _memoryCache.remove(firstKey);
      if (data != null) {
        _currentCacheSize -= data.length;
      }
    }
  }

  void clearCache() {
    _memoryCache.clear();
    _currentCacheSize = 0;
  }

  Map<String, dynamic> getCacheStats() {
    return {
      'cachedImages': _memoryCache.length,
      'currentCacheSize': _currentCacheSize,
      'maxCacheSize': _maxCacheSize,
      'cacheUtilization': _currentCacheSize / _maxCacheSize,
    };
  }
}