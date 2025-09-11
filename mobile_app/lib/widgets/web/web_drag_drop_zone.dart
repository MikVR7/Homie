import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;
import '../../services/web_drag_drop_service.dart';

/// Web-specific drag and drop zone widget
class WebDragDropZone extends StatefulWidget {
  final Widget child;
  final Function(List<DroppedFile>) onFilesDropped;
  final List<String>? allowedTypes;
  final String? dragOverMessage;
  final Color? dragOverColor;
  final bool enabled;

  const WebDragDropZone({
    Key? key,
    required this.child,
    required this.onFilesDropped,
    this.allowedTypes,
    this.dragOverMessage,
    this.dragOverColor,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<WebDragDropZone> createState() => _WebDragDropZoneState();
}

class _WebDragDropZoneState extends State<WebDragDropZone>
    with SingleTickerProviderStateMixin {
  bool _isDragging = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Initialize drag and drop for web
    if (kIsWeb && widget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeDragDrop();
      });
    }
  }

  void _initializeDragDrop() {
    if (!kIsWeb) return;

    // Find the HTML element for this widget
    final element = html.document.querySelector('[data-drag-drop-zone]');
    if (element != null) {
      WebDragDropService.initializeDragDrop(
        element,
        onFilesDropped: widget.onFilesDropped,
        onDragStateChanged: _onDragStateChanged,
        allowedTypes: widget.allowedTypes,
      );
    }
  }

  void _onDragStateChanged(bool isDragging) {
    if (_isDragging != isDragging) {
      setState(() {
        _isDragging = isDragging;
      });
      
      if (isDragging) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Stack(
            children: [
              // Main content
              Container(
                decoration: BoxDecoration(
                  border: _isDragging
                      ? Border.all(
                          color: widget.dragOverColor ?? colorScheme.primary,
                          width: 2,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: widget.child,
              ),
              
              // Drag overlay
              if (_isDragging)
                Positioned.fill(
                  child: AnimatedOpacity(
                    opacity: _opacityAnimation.value,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      decoration: BoxDecoration(
                        color: (widget.dragOverColor ?? colorScheme.primary)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: widget.dragOverColor ?? colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              size: 48,
                              color: widget.dragOverColor ?? colorScheme.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.dragOverMessage ?? 'Drop files here to organize',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: widget.dragOverColor ?? colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getSupportedTypesText(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: (widget.dragOverColor ?? colorScheme.primary)
                                    .withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              
              // Flutter content overlay for web
              if (kIsWeb)
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: _isDragging,
                    child: widget.child,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _getSupportedTypesText() {
    if (widget.allowedTypes == null || widget.allowedTypes!.isEmpty) {
      return 'All file types supported';
    }

    final types = <String>[];
    for (final type in widget.allowedTypes!) {
      if (type.startsWith('image/')) {
        types.add('Images');
      } else if (type.startsWith('application/pdf')) {
        types.add('PDFs');
      } else if (type.startsWith('application/') && type.contains('document')) {
        types.add('Documents');
      } else if (type.startsWith('video/')) {
        types.add('Videos');
      } else if (type.startsWith('audio/')) {
        types.add('Audio');
      }
    }

    return types.isEmpty 
        ? 'Supported file types'
        : 'Supported: ${types.join(', ')}';
  }
}

/// Web-specific file drop handler widget
class WebFileDropHandler extends StatelessWidget {
  final Function(List<DroppedFile>) onFilesDropped;
  final Widget child;
  final bool enabled;

  const WebFileDropHandler({
    Key? key,
    required this.onFilesDropped,
    required this.child,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || !enabled) {
      return child;
    }

    return WebDragDropZone(
      onFilesDropped: onFilesDropped,
      allowedTypes: WebDragDropService.allSupportedTypes,
      child: child,
    );
  }
}