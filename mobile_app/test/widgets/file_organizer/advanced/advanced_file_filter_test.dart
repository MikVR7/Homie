import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homie_app/widgets/file_organizer/advanced/advanced_file_filter.dart';
import 'package:homie_app/models/file_organizer_models.dart';

void main() {
  group('AdvancedFileFilter Widget Tests', () {
    late List<FileItem> testFiles;
    late List<FileItem> filteredResult;
    late Map<String, dynamic> filterConfigResult;

    setUp(() {
      testFiles = [
        FileItem(
          id: '1',
          name: 'document.pdf',
          type: 'pdf',
          size: 1024000, // 1MB
          path: '/documents/document.pdf',
          lastModified: DateTime(2024, 1, 15),
          suggestedLocation: '/Documents',
        ),
        FileItem(
          id: '2',
          name: 'image.jpg',
          type: 'image',
          size: 2048000, // 2MB
          path: '/pictures/image.jpg',
          lastModified: DateTime(2024, 1, 20),
        ),
        FileItem(
          id: '3',
          name: 'video.mp4',
          type: 'video',
          size: 104857600, // 100MB
          path: '/videos/video.mp4',
          lastModified: DateTime(2024, 1, 10),
          suggestedLocation: '/Videos',
        ),
        FileItem(
          id: '4',
          name: '.hiddenfile',
          type: 'other',
          size: 512,
          path: '/hidden/.hiddenfile',
          lastModified: DateTime(2024, 1, 25),
        ),
      ];
      filteredResult = [];
      filterConfigResult = {};
    });

    Widget createWidget({Map<String, dynamic>? initialFilters}) {
      return MaterialApp(
        home: Scaffold(
          body: AdvancedFileFilter(
            allFiles: testFiles,
            onFiltersChanged: (files) => filteredResult = files,
            onFilterConfigChanged: (config) => filterConfigResult = config,
            initialFilters: initialFilters ?? {},
          ),
        ),
      );
    }

    testWidgets('displays filter interface correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Check header
      expect(find.text('Filter Files'), findsOneWidget);
      expect(find.byIcon(Icons.filter_list), findsOneWidget);

      // Check tab bar
      expect(find.text('Basic'), findsOneWidget);
      expect(find.text('Advanced'), findsOneWidget);
      expect(find.text('Sort'), findsOneWidget);
    });

    testWidgets('basic search functionality works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Enter search text
      await tester.enterText(find.byType(TextField), 'document');
      await tester.pumpAndSettle();

      // Wait for debounce
      await tester.pump(const Duration(milliseconds: 600));

      // Should filter files containing 'document'
      expect(filteredResult.length, equals(1));
      expect(filteredResult.first.name, equals('document.pdf'));
    });

    testWidgets('file type filter works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap on image filter chip
      await tester.tap(find.text('Image'));
      await tester.pumpAndSettle();

      // Should only show image files
      expect(filteredResult.length, equals(1));
      expect(filteredResult.first.type, equals('image'));
    });

    testWidgets('multiple file type filters work', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Select image and video filters
      await tester.tap(find.text('Image'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Video'));
      await tester.pumpAndSettle();

      // Should show both image and video files
      expect(filteredResult.length, equals(2));
      expect(filteredResult.any((f) => f.type == 'image'), isTrue);
      expect(filteredResult.any((f) => f.type == 'video'), isTrue);
    });

    testWidgets('date range filter works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Open start date picker
      await tester.tap(find.text('Start Date'));
      await tester.pumpAndSettle();

      // Select a date in the date picker
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Files should be filtered by date
      expect(filteredResult.isNotEmpty, isTrue);
    });

    testWidgets('size filter works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Enter minimum size
      await tester.enterText(
        find.widgetWithText(TextField, 'Min Size'), 
        '50',
      );
      await tester.pumpAndSettle();

      // Should filter out small files
      expect(filteredResult.any((f) => f.size >= 50 * 1024 * 1024), isTrue);
    });

    testWidgets('size unit conversion works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Change size unit to KB
      await tester.tap(find.text('MB'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('KB'));
      await tester.pumpAndSettle();

      // Unit should be changed
      expect(find.text('KB'), findsOneWidget);
    });

    testWidgets('advanced filters tab works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Switch to advanced tab
      await tester.tap(find.text('Advanced'));
      await tester.pumpAndSettle();

      // Check advanced filter options
      expect(find.text('Path Filter'), findsOneWidget);
      expect(find.text('Show Hidden Files'), findsOneWidget);
      expect(find.text('Advanced Filters'), findsOneWidget);
    });

    testWidgets('path filter works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Switch to advanced tab
      await tester.tap(find.text('Advanced'));
      await tester.pumpAndSettle();

      // Enter path filter
      await tester.enterText(
        find.widgetWithText(TextField, 'Filter by path contains...'), 
        'documents',
      );
      await tester.pumpAndSettle();

      // Should filter files by path
      expect(filteredResult.any((f) => f.path.toLowerCase().contains('documents')), isTrue);
    });

    testWidgets('show hidden files toggle works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Switch to advanced tab
      await tester.tap(find.text('Advanced'));
      await tester.pumpAndSettle();

      // Initially hidden files should not be shown
      expect(filteredResult.any((f) => f.name.startsWith('.')), isFalse);

      // Toggle show hidden files
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Hidden files should now be shown
      expect(filteredResult.any((f) => f.name.startsWith('.')), isTrue);
    });

    testWidgets('advanced filter options work', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Switch to advanced tab
      await tester.tap(find.text('Advanced'));
      await tester.pumpAndSettle();

      // Toggle "Has AI Suggestions" filter
      await tester.tap(find.text('Has AI Suggestions'));
      await tester.pumpAndSettle();

      // Should only show files with suggested locations
      expect(filteredResult.every((f) => f.suggestedLocation != null), isTrue);
    });

    testWidgets('sort tab works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Switch to sort tab
      await tester.tap(find.text('Sort'));
      await tester.pumpAndSettle();

      // Check sort options
      expect(find.text('Sort By'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Size'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Type'), findsOneWidget);
    });

    testWidgets('sort by size works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Switch to sort tab
      await tester.tap(find.text('Sort'));
      await tester.pumpAndSettle();

      // Select sort by size
      await tester.tap(find.text('Size'));
      await tester.pumpAndSettle();

      // Files should be sorted by size
      for (int i = 0; i < filteredResult.length - 1; i++) {
        expect(filteredResult[i].size <= filteredResult[i + 1].size, isTrue);
      }
    });

    testWidgets('sort direction toggle works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Switch to sort tab
      await tester.tap(find.text('Sort'));
      await tester.pumpAndSettle();

      // Toggle sort direction
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Sort direction should be changed
      expect(find.text('Descending (Z-A, 9-0)'), findsOneWidget);
    });

    testWidgets('reset filters button works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Apply some filters
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Image'));
      await tester.pumpAndSettle();

      // Reset filters
      await tester.tap(find.byIcon(Icons.clear_all));
      await tester.pumpAndSettle();

      // All filters should be reset
      expect(find.text('test'), findsNothing);
      expect(filteredResult.length, equals(testFiles.length));
    });

    testWidgets('active filters count updates correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Initially no active filters
      expect(find.text('0'), findsNothing);

      // Apply a search filter
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pumpAndSettle();

      // Active filter count should appear
      expect(find.text('1'), findsOneWidget);

      // Apply file type filter
      await tester.tap(find.text('Image'));
      await tester.pumpAndSettle();

      // Count should increase
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('filter config callback works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Apply filters
      await tester.enterText(find.byType(TextField), 'document');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pdf'));
      await tester.pumpAndSettle();

      // Filter config should be updated
      expect(filterConfigResult['searchQuery'], equals('document'));
      expect(filterConfigResult['fileTypes'], contains('pdf'));
    });

    testWidgets('loads initial filters correctly', (WidgetTester tester) async {
      final initialFilters = {
        'searchQuery': 'test',
        'fileTypes': ['image', 'video'],
        'sortBy': 'size',
        'sortAscending': false,
      };

      await tester.pumpWidget(createWidget(initialFilters: initialFilters));
      await tester.pumpAndSettle();

      // Initial filters should be applied
      expect(find.text('test'), findsOneWidget);
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

      // Search should be cleared
      expect(find.text('test'), findsNothing);
    });

    testWidgets('clear date range button works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Set start date
      await tester.tap(find.text('Start Date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Clear date range should appear
      expect(find.text('Clear Date Range'), findsOneWidget);

      // Clear date range
      await tester.tap(find.text('Clear Date Range'));
      await tester.pumpAndSettle();

      // Date range should be cleared
      expect(find.text('Clear Date Range'), findsNothing);
    });
  });

  group('AdvancedFileFilter Edge Cases', () {
    testWidgets('handles empty file list', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdvancedFileFilter(
              allFiles: [],
              onFiltersChanged: (_) {},
              onFilterConfigChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should not crash with empty file list
      expect(find.byType(AdvancedFileFilter), findsOneWidget);
    });

    testWidgets('handles invalid size input gracefully', (WidgetTester tester) async {
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
            body: AdvancedFileFilter(
              allFiles: files,
              onFiltersChanged: (_) {},
              onFilterConfigChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter invalid size
      await tester.enterText(
        find.widgetWithText(TextField, 'Min Size'), 
        'invalid',
      );
      await tester.pumpAndSettle();

      // Should not crash
      expect(find.byType(AdvancedFileFilter), findsOneWidget);
    });

    testWidgets('handles very large file sizes', (WidgetTester tester) async {
      final files = [
        FileItem(
          id: '1',
          name: 'large.txt',
          type: 'document',
          size: 999999999999, // Very large file
          path: '/large.txt',
          lastModified: DateTime.now(),
        ),
      ];

      List<FileItem> result = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdvancedFileFilter(
              allFiles: files,
              onFiltersChanged: (filtered) => result = filtered,
              onFilterConfigChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should handle large files correctly
      expect(result.length, equals(1));
      expect(result.first.size, equals(999999999999));
    });

    testWidgets('handles date edge cases', (WidgetTester tester) async {
      final files = [
        FileItem(
          id: '1',
          name: 'old.txt',
          type: 'document',
          size: 1024,
          path: '/old.txt',
          lastModified: DateTime(1990, 1, 1), // Very old file
        ),
        FileItem(
          id: '2',
          name: 'future.txt',
          type: 'document',
          size: 1024,
          path: '/future.txt',
          lastModified: DateTime(2030, 1, 1), // Future date
        ),
      ];

      List<FileItem> result = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdvancedFileFilter(
              allFiles: files,
              onFiltersChanged: (filtered) => result = filtered,
              onFilterConfigChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should handle edge case dates
      expect(result.length, equals(2));
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
            body: AdvancedFileFilter(
              allFiles: files,
              onFiltersChanged: (filtered) => result = filtered,
              onFilterConfigChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Search for special characters
      await tester.enterText(find.byType(TextField), '@#\$');
      await tester.pumpAndSettle();

      // Wait for debounce
      await tester.pump(const Duration(milliseconds: 600));

      // Should find file with special characters
      expect(result.length, equals(1));
    });
  });
}
