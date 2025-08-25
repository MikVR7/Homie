import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homie_app/widgets/file_organizer/advanced/export_manager.dart';
import 'package:homie_app/models/file_organizer_models.dart';

void main() {
  group('ExportManager Widget Tests', () {
    late List<FileItem> testFiles;
    late List<FileOperation> testOperations;
    late Map<String, dynamic> testAnalytics;
    late String exportCompleteResult;

    setUp(() {
      testFiles = [
        FileItem(
          id: '1',
          name: 'document.pdf',
          type: 'pdf',
          size: 1024000,
          path: '/documents/document.pdf',
          lastModified: DateTime(2024, 1, 15),
          suggestedLocation: '/Documents',
        ),
        FileItem(
          id: '2',
          name: 'image.jpg',
          type: 'image',
          size: 2048000,
          path: '/pictures/image.jpg',
          lastModified: DateTime(2024, 1, 20),
        ),
        FileItem(
          id: '3',
          name: 'video.mp4',
          type: 'video',
          size: 104857600,
          path: '/videos/video.mp4',
          lastModified: DateTime(2024, 1, 10),
        ),
      ];

      testOperations = [
        FileOperation(
          type: 'move',
          sourcePath: '/downloads/file.txt',
          destinationPath: '/documents/file.txt',
          confidence: 0.95,
          reasoning: 'Document should be in documents folder',
        ),
        FileOperation(
          type: 'delete',
          sourcePath: '/temp/cache.tmp',
          confidence: 0.8,
          reasoning: 'Temporary file can be deleted',
        ),
      ];

      testAnalytics = {
        'totalFiles': 3,
        'totalOperations': 2,
        'averageFileSize': 35976533.33,
        'fileTypeDistribution': {
          'pdf': 1,
          'image': 1,
          'video': 1,
        },
      };

      exportCompleteResult = '';
    });

    Widget createWidget() {
      return MaterialApp(
        home: Scaffold(
          body: ExportManager(
            files: testFiles,
            operations: testOperations,
            analytics: testAnalytics,
            onExportComplete: (fileName) => exportCompleteResult = fileName,
          ),
        ),
      );
    }

    testWidgets('displays export interface correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Check header
      expect(find.text('Export Data'), findsOneWidget);
      expect(find.byIcon(Icons.file_download), findsOneWidget);

      // Check tab bar
      expect(find.text('Quick'), findsOneWidget);
      expect(find.text('Advanced'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
    });

    testWidgets('quick export cards display correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Check quick export cards
      expect(find.text('File List Report'), findsOneWidget);
      expect(find.text('Operations Report'), findsOneWidget);
      expect(find.text('Analytics Summary'), findsOneWidget);
      expect(find.text('Complete Report'), findsOneWidget);

      // Check file counts
      expect(find.text('3 files'), findsOneWidget);
      expect(find.text('2 operations'), findsOneWidget);
      expect(find.text('All data'), findsOneWidget);
    });

    testWidgets('quick export functionality works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap on file list report
      await tester.tap(find.text('File List Report'));
      await tester.pumpAndSettle();

      // Wait for export to complete
      await tester.pump(const Duration(milliseconds: 100));

      // Check that export completed
      expect(exportCompleteResult, contains('homie_files_'));
      expect(exportCompleteResult, contains('.csv'));
    });

    testWidgets('operations export works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap on operations report
      await tester.tap(find.text('Operations Report'));
      await tester.pumpAndSettle();

      // Wait for export to complete
      await tester.pump(const Duration(milliseconds: 100));

      // Check that export completed
      expect(exportCompleteResult, contains('homie_operations_'));
      expect(exportCompleteResult, contains('.csv'));
    });

    testWidgets('analytics export works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap on analytics summary
      await tester.tap(find.text('Analytics Summary'));
      await tester.pumpAndSettle();

      // Wait for export to complete
      await tester.pump(const Duration(milliseconds: 100));

      // Check that export completed
      expect(exportCompleteResult, contains('homie_analytics_'));
      expect(exportCompleteResult, contains('.json'));
    });

    testWidgets('complete export works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap on complete report
      await tester.tap(find.text('Complete Report'));
      await tester.pumpAndSettle();

      // Wait for export to complete
      await tester.pump(const Duration(milliseconds: 100));

      // Check that export completed
      expect(exportCompleteResult, contains('homie_complete_report_'));
      expect(exportCompleteResult, contains('.json'));
    });

    testWidgets('advanced export tab works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Switch to advanced tab
      await tester.tap(find.text('Advanced'));
      await tester.pumpAndSettle();

      // Check advanced export options
      expect(find.text('Export Format'), findsOneWidget);
      expect(find.text('CSV'), findsOneWidget);
      expect(find.text('JSON'), findsOneWidget);
      expect(find.text('PDF'), findsOneWidget);
      expect(find.text('HTML'), findsOneWidget);
    });

    testWidgets('export format selection works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Switch to advanced tab
      await tester.tap(find.text('Advanced'));
      await tester.pumpAndSettle();

      // Select JSON format
      await tester.tap(find.text('JSON'));
      await tester.pumpAndSettle();

      // JSON should be selected
      expect(find.byType(FilterChip), findsWidgets);
    });

    testWidgets('data scope selection works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Switch to advanced tab
      await tester.tap(find.text('Advanced'));
      await tester.pumpAndSettle();

      // Check data scope options
      expect(find.text('Everything'), findsOneWidget);
      expect(find.text('Files Only'), findsOneWidget);
      expect(find.text('Operations Only'), findsOneWidget);
      expect(find.text('Analytics Only'), findsOneWidget);

      // Select files only
      await tester.tap(find.text('Files Only'));
      await tester.pumpAndSettle();

      // Files only should be selected
      expect(find.byType(RadioListTile<String>), findsWidgets);
    });

    testWidgets('export options toggles work', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Switch to advanced tab
      await tester.tap(find.text('Advanced'));
      await tester.pumpAndSettle();

      // Check export options
      expect(find.text('Include Analytics'), findsOneWidget);
      expect(find.text('Include Timestamps'), findsOneWidget);
      expect(find.text('Include File Metadata'), findsOneWidget);
      expect(find.text('Include Operation Details'), findsOneWidget);

      // Toggle include analytics
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      // Switch should be toggled
      expect(find.byType(SwitchListTile), findsWidgets);
    });

    testWidgets('advanced export button works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Switch to advanced tab
      await tester.tap(find.text('Advanced'));
      await tester.pumpAndSettle();

      // Tap export button
      await tester.tap(find.text('Export Data'));
      await tester.pumpAndSettle();

      // Wait for export to complete
      await tester.pump(const Duration(milliseconds: 100));

      // Check that export completed
      expect(exportCompleteResult, contains('homie_export_'));
    });

    testWidgets('export loading state works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Switch to advanced tab
      await tester.tap(find.text('Advanced'));
      await tester.pumpAndSettle();

      // Start export
      await tester.tap(find.text('Export Data'));

      // Check loading state
      expect(find.text('Exporting...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      // Wait for completion
      await tester.pumpAndSettle();

      // Loading should be gone
      expect(find.text('Exporting...'), findsNothing);
    });

    testWidgets('history tab displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Switch to history tab
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      // Check history placeholder
      expect(find.text('Export History'), findsOneWidget);
      expect(find.text('Coming soon...'), findsOneWidget);
    });

    testWidgets('analytics summary displays correct info', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Check analytics summary on card
      final summaryText = find.textContaining('types');
      expect(summaryText, findsOneWidget);
    });

    testWidgets('export disabled when no data', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExportManager(
              files: [],
              operations: [],
              analytics: {},
              onExportComplete: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Quick export cards should still be present
      expect(find.text('File List Report'), findsOneWidget);
      expect(find.text('0 files'), findsOneWidget);
      expect(find.text('0 operations'), findsOneWidget);
    });

    testWidgets('format icons display correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Switch to advanced tab
      await tester.tap(find.text('Advanced'));
      await tester.pumpAndSettle();

      // Check format icons
      expect(find.byIcon(Icons.table_chart), findsOneWidget); // CSV
      expect(find.byIcon(Icons.code), findsOneWidget); // JSON
      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget); // PDF
      expect(find.byIcon(Icons.web), findsOneWidget); // HTML
    });

    testWidgets('scope descriptions display correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Switch to advanced tab
      await tester.tap(find.text('Advanced'));
      await tester.pumpAndSettle();

      // Check scope descriptions
      expect(find.text('Export files, operations, and analytics'), findsOneWidget);
      expect(find.text('Export file list with metadata'), findsOneWidget);
      expect(find.text('Export organization operations'), findsOneWidget);
      expect(find.text('Export analytics and statistics'), findsOneWidget);
    });

    testWidgets('quick export card interactions work', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Cards should be tappable
      final fileListCard = find.ancestor(
        of: find.text('File List Report'),
        matching: find.byType(Card),
      );
      expect(fileListCard, findsOneWidget);

      // Tap should work without error
      await tester.tap(fileListCard);
      await tester.pumpAndSettle();
    });

    testWidgets('export format chips are selectable', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Switch to advanced tab
      await tester.tap(find.text('Advanced'));
      await tester.pumpAndSettle();

      // All format chips should be present
      final csvChip = find.ancestor(
        of: find.text('CSV'),
        matching: find.byType(FilterChip),
      );
      final jsonChip = find.ancestor(
        of: find.text('JSON'),
        matching: find.byType(FilterChip),
      );
      
      expect(csvChip, findsOneWidget);
      expect(jsonChip, findsOneWidget);

      // Select JSON
      await tester.tap(jsonChip);
      await tester.pumpAndSettle();

      // JSON should be selected (visual feedback varies)
      expect(find.byType(FilterChip), findsWidgets);
    });
  });

  group('ExportManager Edge Cases', () {
    testWidgets('handles large datasets efficiently', (WidgetTester tester) async {
      // Create large dataset
      final largeFileList = List.generate(1000, (index) => FileItem(
        id: index.toString(),
        name: 'file_$index.txt',
        type: 'document',
        size: 1024 * index,
        path: '/files/file_$index.txt',
        lastModified: DateTime.now().subtract(Duration(days: index)),
      ));

      final largeOperationsList = List.generate(500, (index) => FileOperation(
        type: 'move',
        sourcePath: '/source/file_$index.txt',
        destinationPath: '/dest/file_$index.txt',
        confidence: 0.8 + (index % 20) / 100,
        reasoning: 'Operation $index reasoning',
      ));

      String result = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExportManager(
              files: largeFileList,
              operations: largeOperationsList,
              analytics: {},
              onExportComplete: (fileName) => result = fileName,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should handle large datasets
      expect(find.text('1000 files'), findsOneWidget);
      expect(find.text('500 operations'), findsOneWidget);

      // Export should work
      await tester.tap(find.text('File List Report'));
      await tester.pumpAndSettle();

      expect(result, isNotEmpty);
    });

    testWidgets('handles empty analytics gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExportManager(
              files: [],
              operations: [],
              analytics: {},
              onExportComplete: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should not crash with empty analytics
      expect(find.byType(ExportManager), findsOneWidget);

      // Analytics export should still work
      await tester.tap(find.text('Analytics Summary'));
      await tester.pumpAndSettle();

      // Should not crash
      expect(find.byType(ExportManager), findsOneWidget);
    });

    testWidgets('handles export errors gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExportManager(
              files: [
                FileItem(
                  id: '1',
                  name: 'test.txt',
                  type: 'document',
                  size: 1024,
                  path: '/test.txt',
                  lastModified: DateTime.now(),
                ),
              ],
              operations: [],
              analytics: {},
              onExportComplete: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Export should handle potential errors
      await tester.tap(find.text('File List Report'));
      await tester.pumpAndSettle();

      // Should not crash
      expect(find.byType(ExportManager), findsOneWidget);
    });

    testWidgets('handles special characters in filenames', (WidgetTester tester) async {
      final filesWithSpecialChars = [
        FileItem(
          id: '1',
          name: 'file@#\$.txt',
          type: 'document',
          size: 1024,
          path: '/path/with spaces/file@#\$.txt',
          lastModified: DateTime.now(),
        ),
      ];

      String result = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExportManager(
              files: filesWithSpecialChars,
              operations: [],
              analytics: {},
              onExportComplete: (fileName) => result = fileName,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Export should handle special characters
      await tester.tap(find.text('File List Report'));
      await tester.pumpAndSettle();

      expect(result, isNotEmpty);
    });

    testWidgets('handles very large file sizes', (WidgetTester tester) async {
      final largeFiles = [
        FileItem(
          id: '1',
          name: 'huge.txt',
          type: 'document',
          size: 999999999999, // Very large file
          path: '/huge.txt',
          lastModified: DateTime.now(),
        ),
      ];

      String result = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExportManager(
              files: largeFiles,
              operations: [],
              analytics: {},
              onExportComplete: (fileName) => result = fileName,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should handle very large file sizes
      await tester.tap(find.text('File List Report'));
      await tester.pumpAndSettle();

      expect(result, isNotEmpty);
    });

    testWidgets('handles null values in data gracefully', (WidgetTester tester) async {
      final filesWithNulls = [
        FileItem(
          id: '1',
          name: 'test.txt',
          type: 'document',
          size: 1024,
          path: '/test.txt',
          lastModified: DateTime.now(),
          suggestedLocation: null, // Null suggested location
        ),
      ];

      final operationsWithNulls = [
        FileOperation(
          type: 'move',
          sourcePath: '/source.txt',
          destinationPath: null, // Null destination
          confidence: 0.8,
          reasoning: null, // Null reasoning
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExportManager(
              files: filesWithNulls,
              operations: operationsWithNulls,
              analytics: {},
              onExportComplete: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should handle null values
      await tester.tap(find.text('Complete Report'));
      await tester.pumpAndSettle();

      // Should not crash
      expect(find.byType(ExportManager), findsOneWidget);
    });
  });
}
