import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Web-specific drag and drop service
class WebDragDropService {
  static const List<String> _supportedImageTypes = [
    'image/png',
    'image/jpeg',
    'image/jpg',
    'image/gif',
    'image/webp',
    'image/svg+xml',
  ];

  static const List<String> _supportedDocumentTypes = [
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'text/plain',
    'text/csv',
  ];

  static const List<String> _supportedArchiveTypes = [
    'application/zip',
    'application/x-rar-compressed',
    'application/x-7z-compressed',
  ];

  /// Initialize drag and drop for an element
  static void initializeDragDrop(
    html.Element element, {
    required Function(List<DroppedFile>) onFilesDropped,
    Function(bool)? onDragStateChanged,
    List<String>? allowedTypes,
  }) {
    // Prevent default drag behaviors
    element.onDragOver.listen((event) {
      event.preventDefault();
      event.stopPropagation();
      onDragStateChanged?.call(true);
    });

    element.onDragEnter.listen((event) {
      event.preventDefault();
      event.stopPropagation();
      onDragStateChanged?.call(true);
    });

    element.onDragLeave.listen((event) {
      event.preventDefault();
      event.stopPropagation();
      onDragStateChanged?.call(false);
    });

    // Handle file drop
    element.onDrop.listen((event) async {
      event.preventDefault();
      event.stopPropagation();
      onDragStateChanged?.call(false);

      final files = await _processDroppedFiles(
        event.dataTransfer!.files!,
        allowedTypes: allowedTypes,
      );

      if (files.isNotEmpty) {
        onFilesDropped(files);
      }
    });
  }

  /// Process dropped files and convert to DroppedFile objects
  static Future<List<DroppedFile>> _processDroppedFiles(
    html.FileList fileList, {
    List<String>? allowedTypes,
  }) async {
    final droppedFiles = <DroppedFile>[];

    for (int i = 0; i < fileList.length; i++) {
      final file = fileList[i];
      
      // Check if file type is allowed
      if (allowedTypes != null && !allowedTypes.contains(file.type)) {
        if (kDebugMode) {
          print('File type ${file.type} not allowed for ${file.name}');
        }
        continue;
      }

      try {
        final bytes = await _readFileAsBytes(file);
        final droppedFile = DroppedFile(
          name: file.name,
          type: file.type,
          size: file.size,
          lastModified: DateTime.fromMillisecondsSinceEpoch(file.lastModified!),
          bytes: bytes,
        );
        
        droppedFiles.add(droppedFile);
      } catch (e) {
        if (kDebugMode) {
          print('Error processing file ${file.name}: $e');
        }
      }
    }

    return droppedFiles;
  }

  /// Read file as bytes
  static Future<Uint8List> _readFileAsBytes(html.File file) async {
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    
    await reader.onLoad.first;
    
    final result = reader.result as ByteBuffer;
    return Uint8List.view(result);
  }

  /// Get file category based on MIME type
  static FileCategory getFileCategory(String mimeType) {
    if (_supportedImageTypes.contains(mimeType)) {
      return FileCategory.image;
    } else if (_supportedDocumentTypes.contains(mimeType)) {
      return FileCategory.document;
    } else if (_supportedArchiveTypes.contains(mimeType)) {
      return FileCategory.archive;
    } else if (mimeType.startsWith('video/')) {
      return FileCategory.video;
    } else if (mimeType.startsWith('audio/')) {
      return FileCategory.audio;
    } else {
      return FileCategory.other;
    }
  }

  /// Check if file type is supported for organization
  static bool isFileTypeSupported(String mimeType) {
    return _supportedImageTypes.contains(mimeType) ||
           _supportedDocumentTypes.contains(mimeType) ||
           _supportedArchiveTypes.contains(mimeType) ||
           mimeType.startsWith('video/') ||
           mimeType.startsWith('audio/');
  }

  /// Get all supported file types
  static List<String> get allSupportedTypes => [
    ..._supportedImageTypes,
    ..._supportedDocumentTypes,
    ..._supportedArchiveTypes,
    'video/*',
    'audio/*',
  ];

  /// Create drag and drop overlay widget data
  static Map<String, dynamic> createDragOverlayData({
    required bool isDragging,
    required String message,
    String? icon,
  }) {
    return {
      'isDragging': isDragging,
      'message': message,
      'icon': icon ?? '📁',
    };
  }
}

/// Represents a file dropped via drag and drop
class DroppedFile {
  final String name;
  final String type;
  final int size;
  final DateTime lastModified;
  final Uint8List bytes;

  const DroppedFile({
    required this.name,
    required this.type,
    required this.size,
    required this.lastModified,
    required this.bytes,
  });

  /// Get file extension
  String get extension {
    final lastDot = name.lastIndexOf('.');
    return lastDot != -1 ? name.substring(lastDot) : '';
  }

  /// Get file category
  FileCategory get category => WebDragDropService.getFileCategory(type);

  /// Get human-readable file size
  String get sizeString {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  @override
  String toString() => 'DroppedFile(name: $name, type: $type, size: $sizeString)';
}

/// File categories for organization
enum FileCategory {
  image,
  document,
  archive,
  video,
  audio,
  other,
}