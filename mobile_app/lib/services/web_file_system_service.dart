import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Web-specific file system service using File System Access API
class WebFileSystemService {
  static const String _unsupportedMessage = 
      'File System Access API is not supported in this browser. '
      'Please use Chrome 86+ or Edge 86+ for full functionality.';

  /// Check if File System Access API is supported
  static bool get isSupported {
    return js.context.hasProperty('showDirectoryPicker') &&
           js.context.hasProperty('showOpenFilePicker') &&
           js.context.hasProperty('showSaveFilePicker');
  }

  /// Show directory picker and return directory handle
  static Future<html.FileSystemDirectoryHandle?> pickDirectory({
    String? startIn,
    String? id,
  }) async {
    if (!isSupported) {
      if (kDebugMode) print(_unsupportedMessage);
      return null;
    }

    try {
      final options = <String, dynamic>{};
      if (startIn != null) options['startIn'] = startIn;
      if (id != null) options['id'] = id;

      final handle = await js_util.promiseToFuture(
        js_util.callMethod(html.window, 'showDirectoryPicker', [
          js_util.jsify(options),
        ]),
      );

      return handle as html.FileSystemDirectoryHandle?;
    } catch (e) {
      if (kDebugMode) print('Error picking directory: $e');
      return null;
    }
  }

  /// Show file picker and return file handles
  static Future<List<html.FileSystemFileHandle>> pickFiles({
    bool multiple = false,
    List<Map<String, dynamic>>? types,
    String? startIn,
    String? id,
  }) async {
    if (!isSupported) {
      if (kDebugMode) print(_unsupportedMessage);
      return [];
    }

    try {
      final options = <String, dynamic>{
        'multiple': multiple,
      };
      if (types != null) options['types'] = types;
      if (startIn != null) options['startIn'] = startIn;
      if (id != null) options['id'] = id;

      final handles = await js_util.promiseToFuture(
        js_util.callMethod(html.window, 'showOpenFilePicker', [
          js_util.jsify(options),
        ]),
      );

      return List<html.FileSystemFileHandle>.from(handles);
    } catch (e) {
      if (kDebugMode) print('Error picking files: $e');
      return [];
    }
  }

  /// Show save file picker and return file handle
  static Future<html.FileSystemFileHandle?> saveFile({
    String? suggestedName,
    List<Map<String, dynamic>>? types,
    String? startIn,
    String? id,
  }) async {
    if (!isSupported) {
      if (kDebugMode) print(_unsupportedMessage);
      return null;
    }

    try {
      final options = <String, dynamic>{};
      if (suggestedName != null) options['suggestedName'] = suggestedName;
      if (types != null) options['types'] = types;
      if (startIn != null) options['startIn'] = startIn;
      if (id != null) options['id'] = id;

      final handle = await js_util.promiseToFuture(
        js_util.callMethod(html.window, 'showSaveFilePicker', [
          js_util.jsify(options),
        ]),
      );

      return handle as html.FileSystemFileHandle?;
    } catch (e) {
      if (kDebugMode) print('Error saving file: $e');
      return null;
    }
  }

  /// Read directory contents
  static Future<List<html.FileSystemHandle>> readDirectory(
    html.FileSystemDirectoryHandle directoryHandle,
  ) async {
    try {
      final entries = <html.FileSystemHandle>[];
      final iterator = js_util.callMethod(directoryHandle, 'entries', []);
      
      while (true) {
        final result = await js_util.promiseToFuture(
          js_util.callMethod(iterator, 'next', []),
        );
        
        final done = js_util.getProperty(result, 'done') as bool;
        if (done) break;
        
        final value = js_util.getProperty(result, 'value');
        final entry = (value as List)[1] as html.FileSystemHandle;
        entries.add(entry);
      }
      
      return entries;
    } catch (e) {
      if (kDebugMode) print('Error reading directory: $e');
      return [];
    }
  }

  /// Read file content as bytes
  static Future<Uint8List?> readFileAsBytes(
    html.FileSystemFileHandle fileHandle,
  ) async {
    try {
      final file = await js_util.promiseToFuture(
        js_util.callMethod(fileHandle, 'getFile', []),
      ) as html.File;
      
      final arrayBuffer = await js_util.promiseToFuture(
        js_util.callMethod(file, 'arrayBuffer', []),
      );
      
      return Uint8List.view(arrayBuffer);
    } catch (e) {
      if (kDebugMode) print('Error reading file: $e');
      return null;
    }
  }

  /// Read file content as text
  static Future<String?> readFileAsText(
    html.FileSystemFileHandle fileHandle,
  ) async {
    try {
      final file = await js_util.promiseToFuture(
        js_util.callMethod(fileHandle, 'getFile', []),
      ) as html.File;
      
      final text = await js_util.promiseToFuture(
        js_util.callMethod(file, 'text', []),
      ) as String;
      
      return text;
    } catch (e) {
      if (kDebugMode) print('Error reading file as text: $e');
      return null;
    }
  }

  /// Write content to file
  static Future<bool> writeFile(
    html.FileSystemFileHandle fileHandle,
    dynamic content,
  ) async {
    try {
      final writable = await js_util.promiseToFuture(
        js_util.callMethod(fileHandle, 'createWritable', []),
      );
      
      await js_util.promiseToFuture(
        js_util.callMethod(writable, 'write', [content]),
      );
      
      await js_util.promiseToFuture(
        js_util.callMethod(writable, 'close', []),
      );
      
      return true;
    } catch (e) {
      if (kDebugMode) print('Error writing file: $e');
      return false;
    }
  }

  /// Check if we have permission to access a handle
  static Future<bool> checkPermission(
    html.FileSystemHandle handle, {
    String mode = 'read',
  }) async {
    try {
      final permission = await js_util.promiseToFuture(
        js_util.callMethod(handle, 'queryPermission', [
          js_util.jsify({'mode': mode}),
        ]),
      ) as String;
      
      return permission == 'granted';
    } catch (e) {
      if (kDebugMode) print('Error checking permission: $e');
      return false;
    }
  }

  /// Request permission to access a handle
  static Future<bool> requestPermission(
    html.FileSystemHandle handle, {
    String mode = 'read',
  }) async {
    try {
      final permission = await js_util.promiseToFuture(
        js_util.callMethod(handle, 'requestPermission', [
          js_util.jsify({'mode': mode}),
        ]),
      ) as String;
      
      return permission == 'granted';
    } catch (e) {
      if (kDebugMode) print('Error requesting permission: $e');
      return false;
    }
  }

  /// Get file/directory info
  static Map<String, dynamic> getHandleInfo(html.FileSystemHandle handle) {
    return {
      'name': handle.name,
      'kind': handle.kind,
    };
  }

  /// Common file type filters for file picker
  static const Map<String, List<Map<String, dynamic>>> fileTypes = {
    'images': [
      {
        'description': 'Image files',
        'accept': {
          'image/*': ['.png', '.jpg', '.jpeg', '.gif', '.webp', '.svg']
        }
      }
    ],
    'documents': [
      {
        'description': 'Document files',
        'accept': {
          'application/pdf': ['.pdf'],
          'application/msword': ['.doc'],
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document': ['.docx'],
          'text/plain': ['.txt'],
        }
      }
    ],
    'archives': [
      {
        'description': 'Archive files',
        'accept': {
          'application/zip': ['.zip'],
          'application/x-rar-compressed': ['.rar'],
          'application/x-7z-compressed': ['.7z'],
        }
      }
    ],
    'all': [
      {
        'description': 'All files',
        'accept': {
          '*/*': []
        }
      }
    ],
  };
}