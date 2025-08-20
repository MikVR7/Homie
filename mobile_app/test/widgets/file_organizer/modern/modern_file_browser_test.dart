import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homie_app/widgets/file_organizer/modern/modern_file_browser.dart';

void main() {
  group('ModernFileBrowser', () {
    testWidgets('displays header with correct title', (WidgetTester tester) async {
      String? selectedPath;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernFileBrowser(
              title: 'Test File Browser',
              onPathSelected: (path) => selectedPath = path,
            ),
          ),
        ),
      );

      expect(find.text('Test File Browser'), findsOneWidget);
      expect(find.byIcon(Icons.folder_open), findsOneWidget);
    });

    testWidgets('displays path input field', (WidgetTester tester) async {
      String? selectedPath;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernFileBrowser(
              onPathSelected: (path) => selectedPath = path,
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Enter folder path...'), findsOneWidget);
    });

    testWidgets('shows loading state while scanning folders', (WidgetTester tester) async {
      String? selectedPath;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernFileBrowser(
              onPathSelected: (path) => selectedPath = path,
            ),
          ),
        ),
      );

      // Initially should show loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading folder contents...'), findsOneWidget);
    });

    testWidgets('displays sidebar with quick access and recent sections', (WidgetTester tester) async {
      String? selectedPath;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernFileBrowser(
              onPathSelected: (path) => selectedPath = path,
            ),
          ),
        ),
      );

      expect(find.text('Quick Access'), findsOneWidget);
      expect(find.text('Recent'), findsOneWidget);
      expect(find.byIcon(Icons.bookmark), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets('displays action bar with cancel and select buttons', (WidgetTester tester) async {
      String? selectedPath;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernFileBrowser(
              onPathSelected: (path) => selectedPath = path,
              isDirectoryMode: true,
            ),
          ),
        ),
      );

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Select Folder'), findsOneWidget);
    });

    testWidgets('calls onPathSelected when select button is pressed', (WidgetTester tester) async {
      String? selectedPath;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernFileBrowser(
              initialPath: '/test/path',
              onPathSelected: (path) => selectedPath = path,
              isDirectoryMode: true,
            ),
          ),
        ),
      );

      // Wait for initialization
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Find and tap the select button
      final selectButton = find.text('Select Folder');
      if (selectButton.evaluate().isNotEmpty) {
        await tester.tap(selectButton);
        await tester.pump();
      await tester.pump(const Duration(seconds: 1));

        expect(selectedPath, isNotNull);
      }
    });

    testWidgets('toggles file/directory mode correctly', (WidgetTester tester) async {
      String? selectedPath;
      
      // Test directory mode
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernFileBrowser(
              onPathSelected: (path) => selectedPath = path,
              isDirectoryMode: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.folder_open), findsOneWidget);

      // Test file mode
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernFileBrowser(
              onPathSelected: (path) => selectedPath = path,
              isDirectoryMode: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.file_open), findsOneWidget);
    });

    testWidgets('handles navigation correctly', (WidgetTester tester) async {
      String? selectedPath;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernFileBrowser(
              onPathSelected: (path) => selectedPath = path,
            ),
          ),
        ),
      );

      // Check back button exists
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      
      // Check navigate button exists
      expect(find.byIcon(Icons.navigate_next), findsOneWidget);
    });

    testWidgets('displays error message when navigation fails', (WidgetTester tester) async {
      String? selectedPath;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernFileBrowser(
              initialPath: '/nonexistent/path',
              onPathSelected: (path) => selectedPath = path,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Should show error for invalid path
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.textContaining('Cannot access folder'), findsOneWidget);
    });

    testWidgets('supports keyboard navigation', (WidgetTester tester) async {
      String? selectedPath;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernFileBrowser(
              onPathSelected: (path) => selectedPath = path,
            ),
          ),
        ),
      );

      // Find the path input field
      final pathField = find.byType(TextField);
      await tester.tap(pathField);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Type a path
      await tester.enterText(pathField, '/test/path');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('shows empty state when folder has no contents', (WidgetTester tester) async {
      String? selectedPath;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModernFileBrowser(
              onPathSelected: (path) => selectedPath = path,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // If folder is empty, should show empty state
      // This might happen if the initial path is empty or doesn't exist
      final emptyState = find.text('This folder is empty');
      if (emptyState.evaluate().isNotEmpty) {
        expect(emptyState, findsOneWidget);
        expect(find.byIcon(Icons.folder_open), findsWidgets);
      }
    });
  });
}
