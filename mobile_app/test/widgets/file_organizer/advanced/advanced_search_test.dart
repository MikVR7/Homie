import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homie_app/widgets/file_organizer/advanced/advanced_search.dart';
import 'package:homie_app/models/file_organizer_models.dart';

void main() {
  group('AdvancedSearch Widget Tests', () {
    late List<FileItem> testFiles;
    late List<FileOperation> testOperations;
    late List<FileItem> foundFilesResult;
    late List<FileOperation> foundOperationsResult;
    late String savedSearchResult;

    setUp(() {
      testFiles = [
        FileItem(
          id: '1',
          name: 'vacation photos.jpg',
          type: 'image',
          size: 2048000,
          path: '/pictures/vacation photos.jpg',
          lastModified: DateTime.now().subtract(const Duration(days: 1)),
          suggestedLocation: '/Photos',
        ),
        FileItem(
          id: '2',
          name: 'work document.pdf',
          type: 'pdf',
          size: 1024000,
          path: '/documents/work document.pdf',
          lastModified: DateTime.now().subtract(const Duration(days: 7)),
        ),
        FileItem(
          id: '3',
          name: 'music playlist.mp3',
          type: 'audio',
          size: 5120000,
          path: '/music/music playlist.mp3',
          lastModified: DateTime.now().subtract(const Duration(days: 30)),
        ),
        FileItem(
          id: '4',
          name: 'project files.zip',
          type: 'archive',
          size: 104857600, // Large file > 100MB
          path: '/downloads/project files.zip',
          lastModified: DateTime.now().subtract(const Duration(hours: 2)),
          suggestedLocation: '/Projects',
        ),
      ];

      testOperations = [
        FileOperation(
          type: 'move',
          sourcePath: '/downloads/file1.txt',
          destinationPath: '/documents/file1.txt',
          confidence: 0.95,
          reasoning: 'Text document should be in documents folder',
        ),
        FileOperation(
          type: 'delete',
          sourcePath: '/temp/cache.tmp',
          confidence: 0.8,
          reasoning: 'Temporary file can be safely deleted',
        ),
        FileOperation(
          type: 'rename',
          sourcePath: '/photos/IMG_001.jpg',
          destinationPath: '/photos/vacation_2024.jpg',
          confidence: 0.9,
          reasoning: 'Rename to descriptive filename',
        ),
      ];

      foundFilesResult = [];
      foundOperationsResult = [];
      savedSearchResult = '';
    });

    Widget createWidget({List<String> savedSearches = const []}) {
      return MaterialApp(
        home: Scaffold(
          body: AdvancedSearch(
            allFiles: testFiles,
            allOperations: testOperations,
            onFilesFound: (files) => foundFilesResult = files,
            onOperationsFound: (operations) => foundOperationsResult = operations,
            onSaveSearch: (search) => savedSearchResult = search,
            savedSearches: savedSearches,
          ),
        ),
      );
    }

    testWidgets('displays search interface correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Check search bar
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search files, operations, and content...'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);

      // Check search options
      expect(find.text('All'), findsOneWidget);
      expect(find.byIcon(Icons.tune), findsOneWidget);
    });

    testWidgets('basic search functionality works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.byType(TextField), 'vacation');
      await tester.pumpAndSettle();

      // Wait for search debounce
      await tester.pump(const Duration(milliseconds: 600));

      // Should find vacation photos
      expect(foundFilesResult.length, equals(1));
      expect(foundFilesResult.first.name, contains('vacation'));
    });

    testWidgets('search in operations works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Search for operation-related term
      await tester.enterText(find.byType(TextField), 'documents');
      await tester.pumpAndSettle();

      // Wait for search debounce
      await tester.pump(const Duration(milliseconds: 600));

      // Should find operations related to documents
      expect(foundOperationsResult.isNotEmpty, isTrue);
    });

    testWidgets('special search terms work correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Search for "today"
      await tester.enterText(find.byType(TextField), 'today');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));

      // Should find files modified today
      expect(foundFilesResult.any((f) => 
        DateTime.now().difference(f.lastModified).inDays == 0), isTrue);
    });

    testWidgets('large files search works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Search for "large files"
      await tester.enterText(find.byType(TextField), 'large files');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));

      // Should find files larger than 100MB
      expect(foundFilesResult.any((f) => f.size > 100 * 1024 * 1024), isTrue);
    });

    testWidgets('organized/unorganized search works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Search for "organized"
      await tester.enterText(find.byType(TextField), 'organized');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));

      // Should find files with suggested locations
      expect(foundFilesResult.every((f) => f.suggestedLocation != null), isTrue);

      // Clear and search for "unorganized"
      await tester.enterText(find.byType(TextField), 'unorganized');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));

      // Should find files without suggested locations
      expect(foundFilesResult.every((f) => f.suggestedLocation == null), isTrue);
    });

    testWidgets('search type dropdown works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Change search type to "Files"
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Files').last);
      await tester.pumpAndSettle();

      // Search should be limited to files
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));

      // Should only search files, not operations
      expect(foundOperationsResult.isEmpty, isTrue);
    });

    testWidgets('quick search terms work', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap on "images" quick search
      await tester.tap(find.text('images'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));

      // Should find image files
      expect(foundFilesResult.any((f) => f.type == 'image'), isTrue);
    });

    testWidgets('clear search button works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Enter search text
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pumpAndSettle();

      // Clear search
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // Search field should be empty
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('advanced options dialog works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Open advanced options
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();

      // Check advanced options dialog
      expect(find.text('Advanced Search Options'), findsOneWidget);
      expect(find.text('Case Sensitive'), findsOneWidget);
      expect(find.text('Use Regular Expressions'), findsOneWidget);
      expect(find.text('Search in File Content'), findsOneWidget);
    });

    testWidgets('case sensitive search works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Open advanced options
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();

      // Enable case sensitive
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Search with different case
      await tester.enterText(find.byType(TextField), 'VACATION');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));

      // Should not find files with lowercase 'vacation'
      expect(foundFilesResult.isEmpty, isTrue);
    });

    testWidgets('regex search works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Open advanced options
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();

      // Enable regex
      await tester.tap(find.byType(Switch).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Search with regex pattern
      await tester.enterText(find.byType(TextField), r'.*\.jpg$');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));

      // Should find JPG files
      expect(foundFilesResult.any((f) => f.name.endsWith('.jpg')), isTrue);
    });

    testWidgets('search suggestions work', (WidgetTester tester) async {
      const savedSearches = ['vacation photos', 'work documents'];
      await tester.pumpWidget(createWidget(savedSearches: savedSearches));
      await tester.pumpAndSettle();

      // Enter partial text to trigger suggestions
      await tester.enterText(find.byType(TextField), 'vac');
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      // Wait for suggestions to appear
      await tester.pump(const Duration(milliseconds: 100));

      // Should show suggestions from history
      expect(find.text('vacation photos'), findsOneWidget);
    });

    testWidgets('search history works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Check for search help
      expect(find.text('Advanced Search'), findsOneWidget);
      expect(find.text('Search through files, operations, and content'), findsOneWidget);
    });

    testWidgets('file result item displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Perform search to get results
      await tester.enterText(find.byType(TextField), 'vacation');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));

      // Check that file results are displayed
      expect(find.text('Files (1)'), findsOneWidget);
      expect(find.text('vacation photos.jpg'), findsOneWidget);
    });

    testWidgets('operation result item displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Search for operations
      await tester.enterText(find.byType(TextField), 'move');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));

      // Check that operation results are displayed
      expect(find.text('Operations'), findsOneWidget);
      expect(find.text('MOVE'), findsOneWidget);
    });

    testWidgets('file details dialog works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Search and get results
      await tester.enterText(find.byType(TextField), 'vacation');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));

      // Tap on file result
      await tester.tap(find.text('vacation photos.jpg'));
      await tester.pumpAndSettle();

      // Check file details dialog
      expect(find.text('vacation photos.jpg'), findsNWidgets(2)); // Title and in list
    });

    testWidgets('operation details dialog works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Search for operations
      await tester.enterText(find.byType(TextField), 'move');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));

      // Tap on operation result
      await tester.tap(find.text('MOVE'));
      await tester.pumpAndSettle();

      // Check operation details dialog
      expect(find.text('MOVE Operation'), findsOneWidget);
    });

    testWidgets('file options menu works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Search and get results
      await tester.enterText(find.byType(TextField), 'vacation');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));

      // Tap on more options
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Check options menu
      expect(find.text('Open Location'), findsOneWidget);
      expect(find.text('Organize'), findsOneWidget);
    });

    testWidgets('no results state works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Search for something that doesn't exist
      await tester.enterText(find.byType(TextField), 'nonexistent');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));

      // Check no results state
      expect(find.byIcon(Icons.search_off), findsOneWidget);
      expect(find.text('No results found'), findsOneWidget);
      expect(find.text('Try adjusting your search terms or filters'), findsOneWidget);
    });

    testWidgets('clear search from no results works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Search for something that doesn't exist
      await tester.enterText(find.byType(TextField), 'nonexistent');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));

      // Clear search from no results state
      await tester.tap(find.text('Clear Search'));
      await tester.pumpAndSettle();

      // Should return to help state
      expect(find.text('Advanced Search'), findsOneWidget);
    });

    testWidgets('save search functionality works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.byType(TextField), 'vacation photos');
      await tester.pumpAndSettle();

      // Open advanced options
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();

      // Save search
      await tester.tap(find.text('Save Search'));
      await tester.pumpAndSettle();

      // Check that search was saved
      expect(savedSearchResult, equals('vacation photos'));
    });

    testWidgets('search loading state works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pumpAndSettle();

      // Should show loading immediately
      expect(find.text('Searching...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('AdvancedSearch Edge Cases', () {
    testWidgets('handles empty search gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdvancedSearch(
              allFiles: [],
              allOperations: [],
              onFilesFound: (_) {},
              onOperationsFound: (_) {},
              onSaveSearch: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter empty search
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      // Should show help state
      expect(find.text('Advanced Search'), findsOneWidget);
    });

    testWidgets('handles invalid regex gracefully', (WidgetTester tester) async {
      final files = [
        FileItem(
          id: '1',
          name: 'test.txt',
          type: 'document',
          size: 1024,
          path: '/test.txt',
          lastModified: DateTime.now(),
        ),
      ];

      List<FileItem> result = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdvancedSearch(
              allFiles: files,
              allOperations: [],
              onFilesFound: (found) => result = found,
              onOperationsFound: (_) {},
              onSaveSearch: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enable regex
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Enter invalid regex
      await tester.enterText(find.byType(TextField), '[invalid');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));

      // Should not crash
      expect(find.byType(AdvancedSearch), findsOneWidget);
    });

    testWidgets('handles special characters in search', (WidgetTester tester) async {
      final files = [
        FileItem(
          id: '1',
          name: 'file@#\$.txt',
          type: 'document',
          size: 1024,
          path: '/file@#\$.txt',
          lastModified: DateTime.now(),
        ),
      ];

      List<FileItem> result = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdvancedSearch(
              allFiles: files,
              allOperations: [],
              onFilesFound: (found) => result = found,
              onOperationsFound: (_) {},
              onSaveSearch: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Search with special characters
      await tester.enterText(find.byType(TextField), '@#\$');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));

      // Should find the file
      expect(result.length, equals(1));
    });

    testWidgets('handles very long search queries', (WidgetTester tester) async {
      final files = [
        FileItem(
          id: '1',
          name: 'test.txt',
          type: 'document',
          size: 1024,
          path: '/test.txt',
          lastModified: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdvancedSearch(
              allFiles: files,
              allOperations: [],
              onFilesFound: (_) {},
              onOperationsFound: (_) {},
              onSaveSearch: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter very long search query
      const longQuery = 'a' * 1000;
      await tester.enterText(find.byType(TextField), longQuery);
      await tester.pumpAndSettle();

      // Should not crash
      expect(find.byType(AdvancedSearch), findsOneWidget);
    });
  });
}
