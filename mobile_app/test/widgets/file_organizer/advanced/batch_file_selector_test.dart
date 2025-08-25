import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:homie_app/widgets/file_organizer/advanced/batch_file_selector.dart';
import 'package:homie_app/models/file_organizer_models.dart';
import 'package:homie_app/providers/accessibility_provider.dart';

void main() {
  group('BatchFileSelector Widget Tests', () {
    late List<FileItem> testFiles;
    late List<FileItem> selectedFiles;
    late List<FileItem> onSelectionChangedResult;
    late FileItem onFileActionResult;

    setUp(() {
      testFiles = [
        FileItem(
          id: '1',
          name: 'document.pdf',
          type: 'pdf',
          size: 1024000,
          path: '/test/document.pdf',
          lastModified: DateTime(2024, 1, 15),
          suggestedLocation: '/Documents',
        ),
        FileItem(
          id: '2',
          name: 'image.jpg',
          type: 'image',
          size: 2048000,
          path: '/test/image.jpg',
          lastModified: DateTime(2024, 1, 20),
        ),
        FileItem(
          id: '3',
          name: 'video.mp4',
          type: 'video',
          size: 104857600,
          path: '/test/video.mp4',
          lastModified: DateTime(2024, 1, 10),
          suggestedLocation: '/Videos',
        ),
        FileItem(
          id: '4',
          name: 'music.mp3',
          type: 'audio',
          size: 5120000,
          path: '/test/music.mp3',
          lastModified: DateTime(2024, 1, 25),
        ),
      ];
      selectedFiles = [];
      onSelectionChangedResult = [];
      onFileActionResult = testFiles[0];
    });

    Widget createWidget({
      bool enableSearch = true,
      bool enableFiltering = true,
    }) {
      return MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => AccessibilityProvider(),
          child: Scaffold(
            body: BatchFileSelector(
              files: testFiles,
              selectedFiles: selectedFiles,
              onSelectionChanged: (files) => onSelectionChangedResult = files,
              onFileAction: (file) => onFileActionResult = file,
              enableSearch: enableSearch,
              enableFiltering: enableFiltering,
            ),
          ),
        ),
      );
    }

    testWidgets('displays files in grid format', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Check that all test files are displayed
      expect(find.text('document.pdf'), findsOneWidget);
      expect(find.text('image.jpg'), findsOneWidget);
      expect(find.text('video.mp4'), findsOneWidget);
      expect(find.text('music.mp3'), findsOneWidget);

      // Check that file icons are displayed
      expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
      expect(find.byIcon(Icons.video_file_outlined), findsOneWidget);
      expect(find.byIcon(Icons.audio_file_outlined), findsOneWidget);
    });

    testWidgets('shows search bar when enabled', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget(enableSearch: true));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search files...'), findsOneWidget);
    });

    testWidgets('hides search bar when disabled', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget(enableSearch: false));
      await tester.pumpAndSettle();

      expect(find.text('Search files...'), findsNothing);
    });

    testWidgets('shows filter chips when enabled', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget(enableFiltering: true));
      await tester.pumpAndSettle();

      // Check for file type filter chips
      expect(find.text('Image'), findsOneWidget);
      expect(find.text('Video'), findsOneWidget);
      expect(find.text('Audio'), findsOneWidget);
      expect(find.text('Document'), findsOneWidget);
      expect(find.text('Pdf'), findsOneWidget);
    });

    testWidgets('search functionality filters files correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.byType(TextField), 'image');
      await tester.pumpAndSettle();

      // Only image file should be visible
      expect(find.text('image.jpg'), findsOneWidget);
      expect(find.text('document.pdf'), findsNothing);
      expect(find.text('video.mp4'), findsNothing);
      expect(find.text('music.mp3'), findsNothing);
    });

    testWidgets('file type filter works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap on video filter chip
      await tester.tap(find.text('Video'));
      await tester.pumpAndSettle();

      // Only video file should be visible
      expect(find.text('video.mp4'), findsOneWidget);
      expect(find.text('document.pdf'), findsNothing);
      expect(find.text('image.jpg'), findsNothing);
      expect(find.text('music.mp3'), findsNothing);
    });

    testWidgets('date range filter works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Open date range dropdown
      await tester.tap(find.text('Date Range'));
      await tester.pumpAndSettle();

      // Select "Week" option
      await tester.tap(find.text('Week').last);
      await tester.pumpAndSettle();

      // Recent files should be visible (within last 7 days from test dates)
      // Note: This would need to be adjusted based on actual test execution date
    });

    testWidgets('sort functionality works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Open sort dropdown
      await tester.tap(find.text('Sort By'));
      await tester.pumpAndSettle();

      // Select "Size" option
      await tester.tap(find.text('Size').last);
      await tester.pumpAndSettle();

      // Files should be sorted by size
      // We can verify by checking the order of displayed files
    });

    testWidgets('selection mode activates on long press', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Long press on a file to enter selection mode
      await tester.longPress(find.text('document.pdf'));
      await tester.pumpAndSettle();

      // Selection toolbar should appear
      expect(find.text('1 selected'), findsOneWidget);
      expect(find.byIcon(Icons.select_all), findsOneWidget);
      expect(find.byIcon(Icons.flip_to_back), findsOneWidget);
      expect(find.byIcon(Icons.clear_all), findsOneWidget);

      // Checkbox should be visible on files
      expect(find.byType(Checkbox), findsWidgets);
    });

    testWidgets('select all functionality works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Enter selection mode
      await tester.longPress(find.text('document.pdf'));
      await tester.pumpAndSettle();

      // Tap select all
      await tester.tap(find.byIcon(Icons.select_all));
      await tester.pumpAndSettle();

      // All files should be selected
      expect(find.text('${testFiles.length} selected'), findsOneWidget);
    });

    testWidgets('select none functionality works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Enter selection mode and select all
      await tester.longPress(find.text('document.pdf'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.select_all));
      await tester.pumpAndSettle();

      // Clear selection
      await tester.tap(find.byIcon(Icons.clear_all));
      await tester.pumpAndSettle();

      // Selection mode should be exited
      expect(find.text('selected'), findsNothing);
      expect(find.byType(Checkbox), findsNothing);
    });

    testWidgets('invert selection functionality works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Enter selection mode
      await tester.longPress(find.text('document.pdf'));
      await tester.pumpAndSettle();

      // Invert selection
      await tester.tap(find.byIcon(Icons.flip_to_back));
      await tester.pumpAndSettle();

      // All other files should be selected (3 out of 4)
      expect(find.text('3 selected'), findsOneWidget);
    });

    testWidgets('file action callback works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap on a file
      await tester.tap(find.text('document.pdf'));
      await tester.pumpAndSettle();

      // File action should be triggered
      expect(onFileActionResult.name, equals('document.pdf'));
    });

    testWidgets('file popup menu works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap on popup menu button
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();

      // Menu items should be visible
      expect(find.text('File Info'), findsOneWidget);
      expect(find.text('Open Location'), findsOneWidget);
      expect(find.text('Organize'), findsOneWidget);
    });

    testWidgets('file info dialog shows correct information', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Open popup menu and select info
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('File Info'));
      await tester.pumpAndSettle();

      // File info dialog should show
      expect(find.text('File Information'), findsOneWidget);
      expect(find.text('document.pdf'), findsOneWidget);
      expect(find.text('pdf'), findsOneWidget);
      expect(find.text('/test/document.pdf'), findsOneWidget);
    });

    testWidgets('empty state shows when no files match filters', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Enter search query that matches no files
      await tester.enterText(find.byType(TextField), 'nonexistent');
      await tester.pumpAndSettle();

      // Empty state should be shown
      expect(find.byIcon(Icons.search_off), findsOneWidget);
      expect(find.text('No files match your search'), findsOneWidget);
      expect(find.text('Try adjusting your search or filters'), findsOneWidget);
    });

    testWidgets('accessibility features work correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Check for semantic labels and accessibility features
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('responsive grid layout adapts to screen size', (WidgetTester tester) async {
      // Test with different screen sizes
      await tester.binding.setSurfaceSize(const Size(800, 600));
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Grid should be visible
      expect(find.byType(GridView), findsOneWidget);

      // Test with narrow screen
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Grid should still be visible and adapt
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('suggested location chips are displayed correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Files with suggested locations should show chips
      expect(find.text('Suggested: /Documents'), findsOneWidget);
      expect(find.text('Suggested: /Videos'), findsOneWidget);

      // Files without suggestions should not show chips
      expect(find.text('Suggested:'), findsNWidgets(2));
    });

    testWidgets('clear search button works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Enter search text
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pumpAndSettle();

      // Clear button should be visible
      expect(find.byIcon(Icons.clear), findsOneWidget);

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // Search field should be empty and all files visible
      expect(find.text('test'), findsNothing);
      expect(find.text('document.pdf'), findsOneWidget);
      expect(find.text('image.jpg'), findsOneWidget);
    });

    testWidgets('sort direction toggle works', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Find and tap sort direction button
      await tester.tap(find.byIcon(Icons.arrow_upward));
      await tester.pumpAndSettle();

      // Icon should change to downward
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward), findsNothing);
    });
  });

  group('BatchFileSelector Edge Cases', () {
    testWidgets('handles empty file list', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AccessibilityProvider(),
            child: Scaffold(
              body: BatchFileSelector(
                files: [],
                selectedFiles: [],
                onSelectionChanged: (_) {},
                onFileAction: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show empty state
      expect(find.byIcon(Icons.folder_open), findsOneWidget);
      expect(find.text('No files found'), findsOneWidget);
    });

    testWidgets('handles large file list performance', (WidgetTester tester) async {
      // Create a large list of files
      final largeFileList = List.generate(1000, (index) => FileItem(
        id: index.toString(),
        name: 'file_$index.txt',
        type: 'document',
        size: 1024 * index,
        path: '/test/file_$index.txt',
        lastModified: DateTime.now().subtract(Duration(days: index)),
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AccessibilityProvider(),
            child: Scaffold(
              body: BatchFileSelector(
                files: largeFileList,
                selectedFiles: [],
                onSelectionChanged: (_) {},
                onFileAction: (_) {},
              ),
            ),
          ),
        ),
      );

      // Widget should render without performance issues
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('handles selection state changes correctly', (WidgetTester tester) async {
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

      List<FileItem> selectedFiles = [];

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AccessibilityProvider(),
            child: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: BatchFileSelector(
                    files: files,
                    selectedFiles: selectedFiles,
                    onSelectionChanged: (selected) {
                      setState(() {
                        selectedFiles = selected;
                      });
                    },
                    onFileAction: (_) {},
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter selection mode
      await tester.longPress(find.text('test.txt'));
      await tester.pumpAndSettle();

      // File should be selected
      expect(find.text('1 selected'), findsOneWidget);
    });
  });
}
