import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:homie_app/services/api_service.dart';
import '../mocks/mock_http_client.dart';

void main() {
  late ApiService apiService;
  late MockHttpClient mockHttpClient;

  setUp(() {
    mockHttpClient = MockHttpClient();
    apiService = ApiService(client: mockHttpClient);
  });

  group('ApiService Enhanced Methods Tests - Mocked', () {
    group('Task 3.1: Enhanced API Service Methods', () {
      group('getRecentPaths', () {
        test('should return list of recent paths on success', () async {
          // Arrange
          final mockResponse = http.Response(
            jsonEncode(['/home/user/docs', '/home/user/downloads']),
            200,
          );
          when(mockHttpClient.get(any))
              .thenAnswer((_) async => mockResponse);

          // Act
          final result = await apiService.getRecentPaths(limit: 10);

          // Assert
          expect(result, isA<List<String>>());
          expect(result, contains('/home/user/docs'));
          expect(result, contains('/home/user/downloads'));
          verify(mockHttpClient.get(any)).called(1);
        });

        test('should handle error response gracefully', () async {
          // Arrange
          when(mockHttpClient.get(any))
              .thenAnswer((_) async => http.Response('{"error": "Not found"}', 404));

          // Act & Assert
          expect(
            () => apiService.getRecentPaths(limit: 10),
            throwsException,
          );
        });

        test('should handle network errors', () async {
          // Arrange
          when(mockHttpClient.get(any))
              .thenThrow(const SocketException('Network error'));

          // Act & Assert
          expect(
            () => apiService.getRecentPaths(limit: 10),
            throwsException,
          );
        });
      });

      group('getBookmarkedPaths', () {
        test('should return list of bookmarked paths on success', () async {
          // Arrange
          final mockResponse = http.Response(
            jsonEncode([
              {'path': '/home/user/docs', 'name': 'Documents'},
              {'path': '/home/user/projects', 'name': 'Projects'}
            ]),
            200,
          );
          when(mockHttpClient.get(any))
              .thenAnswer((_) async => mockResponse);

          // Act
          final result = await apiService.getBookmarkedPaths();

          // Assert
          expect(result, isA<List<Map<String, dynamic>>>());
          expect(result.length, equals(2));
          expect(result[0]['path'], equals('/home/user/docs'));
          verify(mockHttpClient.get(any)).called(1);
        });

        test('should handle empty bookmarks list', () async {
          // Arrange
          when(mockHttpClient.get(any))
              .thenAnswer((_) async => http.Response(jsonEncode([]), 200));

          // Act
          final result = await apiService.getBookmarkedPaths();

          // Assert
          expect(result, isEmpty);
        });
      });

      group('addBookmark', () {
        test('should add bookmark successfully', () async {
          // Arrange
          when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
              .thenAnswer((_) async => http.Response('{"success": true}', 200));

          // Act
          final result = await apiService.addBookmark(path: '/test/path', name: 'Test Bookmark');

          // Assert
          expect(result, isTrue);
          verify(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body'))).called(1);
        });

        test('should handle duplicate bookmark error', () async {
          // Arrange
          when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
              .thenAnswer((_) async => http.Response('{"error": "Bookmark already exists"}', 409));

          // Act & Assert
          expect(
            () => apiService.addBookmark(path: '/test/path', name: 'Test Bookmark'),
            throwsException,
          );
        });
      });

      group('removeBookmark', () {
        test('should remove bookmark successfully', () async {
          // Arrange
          when(mockHttpClient.delete(any, headers: anyNamed('headers')))
              .thenAnswer((_) async => http.Response('{"success": true}', 200));

          // Act
          final result = await apiService.removeBookmark('/test/path');

          // Assert
          expect(result, isTrue);
          verify(mockHttpClient.delete(any, headers: anyNamed('headers'))).called(1);
        });

        test('should handle non-existent bookmark', () async {
          // Arrange
          when(mockHttpClient.delete(any, headers: anyNamed('headers')))
              .thenAnswer((_) async => http.Response('{"error": "Bookmark not found"}', 404));

          // Act & Assert
          expect(
            () => apiService.removeBookmark('/test/path'),
            throwsException,
          );
        });
      });

      group('browsePath', () {
        test('should browse path with metadata successfully', () async {
          // Arrange
          final mockResponse = http.Response(
            jsonEncode({
              'path': '/test/path',
              'files': [
                {'name': 'file1.txt', 'size': 1024, 'type': 'file'},
                {'name': 'folder1', 'type': 'directory'}
              ]
            }),
            200,
          );
          when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
              .thenAnswer((_) async => mockResponse);

          // Act
          final result = await apiService.browsePath('/test/path');

          // Assert
          expect(result, isA<Map<String, dynamic>>());
          expect(result['path'], equals('/test/path'));
          expect(result['files'], isA<List>());
        });

        test('should handle permission denied error', () async {
          // Arrange
          when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
              .thenAnswer((_) async => http.Response('{"error": "Permission denied"}', 403));

          // Act & Assert
          expect(
            () => apiService.browsePath('/test/path'),
            throwsException,
          );
        });

        test('should handle non-existent path', () async {
          // Arrange
          when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
              .thenAnswer((_) async => http.Response('{"error": "Path not found"}', 404));

          // Act & Assert
          expect(
            () => apiService.browsePath('/test/path'),
            throwsException,
          );
        });
      });

      group('analyzeWithPreview', () {
        test('should analyze folder with preview successfully', () async {
          // Arrange
          final mockResponse = http.Response(
            jsonEncode({
              'path': '/test/folder',
              'analysis': {
                'total_files': 50,
                'categories': {'documents': 25, 'images': 15, 'other': 10}
              },
              'preview': ['file1.txt', 'file2.jpg', 'file3.pdf']
            }),
            200,
          );
          when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
              .thenAnswer((_) async => mockResponse);

          // Act
          final result = await apiService.analyzeWithPreview(
            '/test/folder',
            includeHidden: false,
            previewLimit: 5,
          );

          // Assert
          expect(result, isA<Map<String, dynamic>>());
          expect(result['analysis'], isA<Map<String, dynamic>>());
          expect(result['preview'], isA<List>());
        });

        test('should handle large folder analysis', () async {
          // Arrange
          final mockResponse = http.Response(
            jsonEncode({
              'path': '/large/folder',
              'analysis': {
                'total_files': 10000,
                'categories': {'documents': 5000, 'images': 3000, 'other': 2000}
              },
              'preview': ['sample1.txt', 'sample2.jpg'],
              'warning': 'Large folder - analysis may take time'
            }),
            200,
          );
          when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
              .thenAnswer((_) async => mockResponse);

          // Act
          final result = await apiService.analyzeWithPreview(
            '/large/folder',
            includeHidden: false,
            previewLimit: 2,
          );

          // Assert
          expect(result, isA<Map<String, dynamic>>());
          expect(result['warning'], contains('Large folder'));
        });
      });

      group('User Preferences', () {
        test('recordUserPreference should record preference successfully', () async {
          // Arrange
          when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
              .thenAnswer((_) async => http.Response('{"success": true}', 200));

          // Act
          final result = await apiService.recordUserPreference(
            context: 'file_organization',
            action: 'move',
            data: {'source': '/test/file.txt', 'destination': '/organized/file.txt'},
          );

          // Assert
          expect(result, isTrue);
        });

        test('recordUserPreference should handle invalid preference data', () async {
          // Arrange
          when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
              .thenAnswer((_) async => http.Response('{"error": "Invalid data"}', 400));

          // Act & Assert
          expect(
            () => apiService.recordUserPreference(
              context: 'invalid',
              action: 'test',
              data: {},
            ),
            throwsException,
          );
        });

        test('getUserPreferences should get user preferences successfully', () async {
          // Arrange
          final mockResponse = http.Response(
            jsonEncode({
              'preferences': [
                {'context': 'file_organization', 'action': 'move', 'frequency': 10}
              ]
            }),
            200,
          );
          when(mockHttpClient.get(any))
              .thenAnswer((_) async => mockResponse);

          // Act
          final result = await apiService.getUserPreferences(context: 'file_organization');

          // Assert
          expect(result, isA<Map<String, dynamic>>());
          expect(result['preferences'], isA<List>());
        });

        test('getUserPreferences should get all preferences when no context specified', () async {
          // Arrange
          final mockResponse = http.Response(
            jsonEncode({
              'preferences': [
                {'context': 'file_organization', 'action': 'move', 'frequency': 10},
                {'context': 'ui', 'action': 'theme_change', 'frequency': 5}
              ]
            }),
            200,
          );
          when(mockHttpClient.get(any))
              .thenAnswer((_) async => mockResponse);

          // Act
          final result = await apiService.getUserPreferences();

          // Assert
          expect(result, isA<Map<String, dynamic>>());
          expect(result['preferences'], hasLength(2));
        });
      });

      group('Operation Control Methods', () {
        test('cancelOperation should work correctly', () async {
          // Arrange
          when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
              .thenAnswer((_) async => http.Response('{"success": true}', 200));

          // Act
          final result = await apiService.cancelOperation('test-operation-id');

          // Assert
          expect(result, isTrue);
        });

        test('pauseOperation should work correctly', () async {
          // Arrange
          when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
              .thenAnswer((_) async => http.Response('{"success": true}', 200));

          // Act
          final result = await apiService.pauseOperation('test-operation-id');

          // Assert
          expect(result, isTrue);
        });

        test('resumeOperation should work correctly', () async {
          // Arrange
          when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
              .thenAnswer((_) async => http.Response('{"success": true}', 200));

          // Act
          final result = await apiService.resumeOperation('test-operation-id');

          // Assert
          expect(result, isTrue);
        });
      });
    });

    group('Method Signatures and Types', () {
      test('getRecentPaths returns Future<List<String>>', () {
        // Arrange
        when(mockHttpClient.get(any))
            .thenAnswer((_) async => http.Response('[]', 200));

        // Act
        final result = apiService.getRecentPaths();

        // Assert
        expect(result, isA<Future<List<String>>>());
      });

      test('getBookmarkedPaths returns Future<List<Map<String, dynamic>>>', () {
        // Arrange
        when(mockHttpClient.get(any))
            .thenAnswer((_) async => http.Response('[]', 200));

        // Act
        final result = apiService.getBookmarkedPaths();

        // Assert
        expect(result, isA<Future<List<Map<String, dynamic>>>>());
      });

      test('addBookmark returns Future<bool>', () {
        // Arrange
        when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response('{"success": true}', 200));

        // Act
        final result = apiService.addBookmark(path: '/test', name: 'Test');

        // Assert
        expect(result, isA<Future<bool>>());
      });

      test('removeBookmark returns Future<bool>', () {
        // Arrange
        when(mockHttpClient.delete(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response('{"success": true}', 200));

        // Act
        final result = apiService.removeBookmark('/test');

        // Assert
        expect(result, isA<Future<bool>>());
      });

      test('browsePath returns Future<Map<String, dynamic>>', () {
        // Arrange
        when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response('{}', 200));

        // Act
        final result = apiService.browsePath('/test');

        // Assert
        expect(result, isA<Future<Map<String, dynamic>>>());
      });

      test('analyzeWithPreview returns Future<Map<String, dynamic>>', () {
        // Arrange
        when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response('{}', 200));

        // Act
        final result = apiService.analyzeWithPreview('/test');

        // Assert
        expect(result, isA<Future<Map<String, dynamic>>>());
      });

      test('recordUserPreference returns Future<bool>', () {
        // Arrange
        when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response('{"success": true}', 200));

        // Act
        final result = apiService.recordUserPreference(
          context: 'test',
          action: 'test',
          data: {},
        );

        // Assert
        expect(result, isA<Future<bool>>());
      });

      test('getUserPreferences returns Future<Map<String, dynamic>>', () {
        // Arrange
        when(mockHttpClient.get(any))
            .thenAnswer((_) async => http.Response('{}', 200));

        // Act
        final result = apiService.getUserPreferences();

        // Assert
        expect(result, isA<Future<Map<String, dynamic>>>());
      });

      test('operation control methods return Future<bool>', () {
        // Arrange
        when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response('{"success": true}', 200));

        // Act & Assert
        expect(apiService.cancelOperation('test'), isA<Future<bool>>());
        expect(apiService.pauseOperation('test'), isA<Future<bool>>());
        expect(apiService.resumeOperation('test'), isA<Future<bool>>());
      });
    });
  });
}

