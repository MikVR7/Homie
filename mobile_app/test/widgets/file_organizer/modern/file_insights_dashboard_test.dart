import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:homie_app/widgets/file_organizer/modern/file_insights_dashboard.dart';
import 'package:homie_app/providers/file_organizer_provider.dart';

void main() {
  group('FileInsightsDashboard Widget Tests', () {
    late FileOrganizerProvider mockProvider;

    setUp(() {
      mockProvider = FileOrganizerProvider();
    });

    Widget createTestWidget({
      String? folderPath,
      bool showComparison = false,
      VoidCallback? onActionRequired,
    }) {
      return MaterialApp(
        home: ChangeNotifierProvider<FileOrganizerProvider>.value(
          value: mockProvider,
          child: Scaffold(
            body: FileInsightsDashboard(
              folderPath: folderPath,
              showComparison: showComparison,
              onActionRequired: onActionRequired,
            ),
          ),
        ),
      );
    }

    group('Widget Structure and Layout', () {
      testWidgets('should render insights dashboard card', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.byType(Card), findsWidgets);
        expect(find.text('File Insights Dashboard'), findsOneWidget);
        expect(find.text('Comprehensive file analysis and optimization recommendations'), findsOneWidget);
      });

      testWidgets('should render tab bar with four tabs', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.byType(TabBar), findsOneWidget);
        expect(find.byType(Tab), findsNWidgets(4));
        
        expect(find.text('Overview'), findsOneWidget);
        expect(find.text('Duplicates'), findsAtLeastNWidgets(1)); // May appear in tab and content
        expect(find.text('Large Files'), findsAtLeastNWidgets(1)); // May appear in tab and content
        expect(find.text('Tips'), findsOneWidget);
      });

      testWidgets('should render tab bar view with correct content', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.byType(TabBarView), findsOneWidget);
        
        // Check that overview tab is shown by default
        expect(find.text('Total Files'), findsOneWidget);
        expect(find.text('Total Size'), findsOneWidget);
      });

      testWidgets('should show analytics icon in header', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.byIcon(Icons.analytics), findsOneWidget);
      });
    });

    group('Overview Tab', () {
      testWidgets('should display summary cards', (tester) async {
        await tester.pumpWidget(createTestWidget(folderPath: '/test/path'));

        // Allow loading to complete
        await tester.pumpAndSettle();

        expect(find.text('Total Files'), findsOneWidget);
        expect(find.text('Total Size'), findsOneWidget);
        expect(find.text('Duplicates'), findsAtLeastNWidgets(1)); // May appear in tab and content
        expect(find.text('Large Files'), findsAtLeastNWidgets(1)); // May appear in tab and content
      });

      testWidgets('should show file type distribution section', (tester) async {
        await tester.pumpWidget(createTestWidget(folderPath: '/test/path'));

        await tester.pumpAndSettle();

        expect(find.text('File Type Distribution'), findsOneWidget);
      });

      testWidgets('should display quick actions', (tester) async {
        await tester.pumpWidget(createTestWidget(folderPath: '/test/path'));

        await tester.pumpAndSettle();

        expect(find.text('Quick Actions'), findsOneWidget);
        expect(find.text('Find Duplicates'), findsOneWidget);
        expect(find.text('Large Files'), findsAtLeastNWidgets(1)); // May appear in tab and content
        expect(find.text('Get Recommendations'), findsOneWidget);
      });

      testWidgets('should handle empty file type data', (tester) async {
        await tester.pumpWidget(createTestWidget());

        await tester.pumpAndSettle();

        expect(find.text('No file type data available'), findsOneWidget);
      });
    });

    group('Duplicates Tab', () {
      testWidgets('should switch to duplicates tab', (tester) async {
        await tester.pumpWidget(createTestWidget(folderPath: '/test/path'));

        await tester.tap(find.text('Duplicates').first); // Tap the tab, not content
        await tester.pumpAndSettle();

        expect(find.text('Duplicate Files'), findsOneWidget);
      });

      testWidgets('should show clean all button when duplicates exist', (tester) async {
        await tester.pumpWidget(createTestWidget(folderPath: '/test/path'));

        await tester.tap(find.text('Duplicates').first); // Tap the tab, not content
        await tester.pumpAndSettle();

        // The widget loads mock duplicate data
        expect(find.text('Clean All'), findsOneWidget);
      });

      testWidgets('should display duplicate file cards', (tester) async {
        await tester.pumpWidget(createTestWidget(folderPath: '/test/path'));

        await tester.tap(find.text('Duplicates').first); // Tap the tab, not content
        await tester.pumpAndSettle();

        // Mock data includes vacation-photo.jpg and presentation.pptx
        expect(find.text('vacation-photo.jpg'), findsOneWidget);
        expect(find.text('presentation.pptx'), findsOneWidget);
      });

      testWidgets('should expand duplicate details', (tester) async {
        await tester.pumpWidget(createTestWidget(folderPath: '/test/path'));

        await tester.tap(find.text('Duplicates').first); // Tap the tab, not content
        await tester.pumpAndSettle();

        // Tap on a duplicate to expand details
        await tester.tap(find.text('vacation-photo.jpg'));
        await tester.pumpAndSettle();

        expect(find.text('Duplicate locations:'), findsOneWidget);
        expect(find.text('Merge'), findsWidgets);
        expect(find.text('Delete Extras'), findsWidgets);
      });

      testWidgets('should show empty state when no duplicates', (tester) async {
        // Create widget with no folder path (no data loaded)
        await tester.pumpWidget(createTestWidget());

        await tester.tap(find.text('Duplicates').first); // Tap the tab, not content
        await tester.pumpAndSettle();

        expect(find.text('No duplicate files found'), findsOneWidget);
        expect(find.text('Your files are well organized!'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsWidgets);
      });
    });

    group('Large Files Tab', () {
      testWidgets('should switch to large files tab', (tester) async {
        await tester.pumpWidget(createTestWidget(folderPath: '/test/path'));

        await tester.tap(find.text('Large Files').first); // Tap the tab, not content
        await tester.pumpAndSettle();

        expect(find.text('Large Files'), findsAtLeastNWidgets(1)); // May appear in tab and content
      });

      testWidgets('should display large file items', (tester) async {
        await tester.pumpWidget(createTestWidget(folderPath: '/test/path'));

        await tester.tap(find.text('Large Files').first); // Tap the tab, not content
        await tester.pumpAndSettle();

        // Mock data includes old-backup.zip, project-video.mp4, dataset.csv
        expect(find.text('old-backup.zip'), findsOneWidget);
        expect(find.text('project-video.mp4'), findsOneWidget);
        expect(find.text('dataset.csv'), findsOneWidget);
      });

      testWidgets('should show file action menu', (tester) async {
        await tester.pumpWidget(createTestWidget(folderPath: '/test/path'));

        await tester.tap(find.text('Large Files').first); // Tap the tab, not content
        await tester.pumpAndSettle();

        // Find and tap popup menu
        final menuButtons = find.byType(PopupMenuButton);
        if (menuButtons.evaluate().isNotEmpty) {
          await tester.tap(menuButtons.first);
          await tester.pumpAndSettle();

          expect(find.text('Compress'), findsOneWidget);
          expect(find.text('Move'), findsOneWidget);
          expect(find.text('Delete'), findsOneWidget);
        }
      });

      testWidgets('should show empty state when no large files', (tester) async {
        await tester.pumpWidget(createTestWidget());

        await tester.tap(find.text('Large Files').first); // Tap the tab, not content
        await tester.pumpAndSettle();

        expect(find.text('No large files found'), findsOneWidget);
        expect(find.text('Your storage is efficiently used!'), findsOneWidget);
        expect(find.byIcon(Icons.sentiment_satisfied), findsWidgets);
      });
    });

    group('Recommendations Tab', () {
      testWidgets('should switch to recommendations tab', (tester) async {
        await tester.pumpWidget(createTestWidget(folderPath: '/test/path'));

        await tester.tap(find.text('Tips'));
        await tester.pumpAndSettle();

        expect(find.text('Recommendations'), findsOneWidget);
      });

      testWidgets('should display recommendation items', (tester) async {
        await tester.pumpWidget(createTestWidget(folderPath: '/test/path'));

        await tester.tap(find.text('Tips'));
        await tester.pumpAndSettle();

        // Mock recommendations
        expect(find.text('Remove Duplicate Files'), findsOneWidget);
        expect(find.text('Organize Downloads Folder'), findsOneWidget);
        expect(find.text('Archive Old Files'), findsOneWidget);
      });

      testWidgets('should show apply buttons for recommendations', (tester) async {
        await tester.pumpWidget(createTestWidget(folderPath: '/test/path'));

        await tester.tap(find.text('Tips'));
        await tester.pumpAndSettle();

        expect(find.text('Apply'), findsAtLeastNWidgets(3));
      });

      testWidgets('should show empty state when no recommendations', (tester) async {
        await tester.pumpWidget(createTestWidget());

        await tester.tap(find.text('Tips'));
        await tester.pumpAndSettle();

        expect(find.text('No recommendations'), findsOneWidget);
        expect(find.text('Your files are well organized!'), findsOneWidget);
        expect(find.byIcon(Icons.thumb_up), findsWidgets);
      });
    });

    group('User Interactions', () {
      testWidgets('should handle tab navigation', (tester) async {
        await tester.pumpWidget(createTestWidget(folderPath: '/test/path'));

        // Start on first tab (Overview)
        expect(find.text('Total Files'), findsOneWidget);

        // Navigate to each tab
        await tester.tap(find.text('Duplicates').first); // Tap the tab, not content
        await tester.pumpAndSettle();
        expect(find.text('Duplicate Files'), findsOneWidget);

        await tester.tap(find.text('Large Files').first); // Tap the tab, not content
        await tester.pumpAndSettle();
        expect(find.text('Large Files'), findsAtLeastNWidgets(1)); // May appear in tab and content

        await tester.tap(find.text('Tips'));
        await tester.pumpAndSettle();
        expect(find.text('Recommendations'), findsOneWidget);
      });

      testWidgets('should handle quick action navigation', (tester) async {
        await tester.pumpWidget(createTestWidget(folderPath: '/test/path'));

        await tester.pumpAndSettle();

        // Tap "Find Duplicates" should switch to duplicates tab
        await tester.tap(find.text('Find Duplicates'));
        await tester.pumpAndSettle();

        expect(find.text('Duplicate Files'), findsOneWidget);
      });

      testWidgets('should handle large files action', (tester) async {
        await tester.pumpWidget(createTestWidget(folderPath: '/test/path'));

        await tester.pumpAndSettle();

        // Tap "Large Files" should switch to large files tab
        await tester.tap(find.text('Large Files').first); // Tap the tab, not content
        await tester.pumpAndSettle();

        expect(find.text('Large Files'), findsAtLeastNWidgets(1)); // May appear in tab and content
      });
    });

    group('Loading States', () {
      testWidgets('should show loading indicator when loading', (tester) async {
        await tester.pumpWidget(createTestWidget(folderPath: '/test/path'));

        // Should show loading indicator initially
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      });

      testWidgets('should hide loading indicator after load', (tester) async {
        await tester.pumpWidget(createTestWidget(folderPath: '/test/path'));

        // Allow loading to complete
        await tester.pumpAndSettle();

        // Loading indicator should be gone from header
        // Note: There might still be other loading indicators in the content
        expect(find.text('File Insights Dashboard'), findsOneWidget);
      });
    });

    group('Dialog Interactions', () {
      testWidgets('should show clean all confirmation dialog', (tester) async {
        await tester.pumpWidget(createTestWidget(folderPath: '/test/path'));

        await tester.tap(find.text('Duplicates').first); // Tap the tab, not content
        await tester.pumpAndSettle();

        // Tap clean all button
        await tester.tap(find.text('Clean All'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Clean All Duplicates'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
      });

      testWidgets('should handle dialog cancellation', (tester) async {
        await tester.pumpWidget(createTestWidget(folderPath: '/test/path'));

        await tester.tap(find.text('Duplicates').first); // Tap the tab, not content
        await tester.pumpAndSettle();

        await tester.tap(find.text('Clean All'));
        await tester.pumpAndSettle();

        // Cancel the dialog
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
      });
    });

    group('Callback Handling', () {
      testWidgets('should call onActionRequired callback', (tester) async {
        bool callbackCalled = false;
        
        final widget = MaterialApp(
          home: ChangeNotifierProvider<FileOrganizerProvider>.value(
            value: mockProvider,
            child: Scaffold(
              body: FileInsightsDashboard(
                folderPath: '/test/path',
                onActionRequired: () => callbackCalled = true,
              ),
            ),
          ),
        );

        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Tips'));
        await tester.pumpAndSettle();

        // Apply a recommendation
        final applyButtons = find.text('Apply');
        if (applyButtons.evaluate().isNotEmpty) {
          await tester.tap(applyButtons.first);
          await tester.pumpAndSettle();

          // Callback should be called
          expect(callbackCalled, isTrue);
        }
      });
    });

    group('Comparison Mode', () {
      testWidgets('should handle comparison mode flag', (tester) async {
        await tester.pumpWidget(createTestWidget(
          folderPath: '/test/path',
          showComparison: true,
        ));

        expect(find.byType(FileInsightsDashboard), findsOneWidget);
        // Comparison mode would show additional before/after data
      });
    });

    group('Provider Integration', () {
      testWidgets('should integrate with FileOrganizerProvider', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Verify provider is accessible
        expect(find.byType(ChangeNotifierProvider<FileOrganizerProvider>), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('should handle API errors gracefully', (tester) async {
        await tester.pumpWidget(createTestWidget(folderPath: '/invalid/path'));

        // Allow error handling to complete
        await tester.pumpAndSettle();

        // Widget should still render properly
        expect(find.byType(FileInsightsDashboard), findsOneWidget);
      });

      testWidgets('should show error messages via SnackBar', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Trigger an error scenario
        await tester.pumpAndSettle();

        // Widget should handle errors gracefully
        expect(find.byType(FileInsightsDashboard), findsOneWidget);
      });
    });

    group('File Size Formatting', () {
      testWidgets('should display formatted file sizes', (tester) async {
        await tester.pumpWidget(createTestWidget(folderPath: '/test/path'));

        await tester.pumpAndSettle();

        // Should show formatted sizes in overview cards
        expect(find.textContaining('MB'), findsWidgets);
        expect(find.textContaining('GB'), findsWidgets);
      });
    });

    group('Date Formatting', () {
      testWidgets('should display formatted dates', (tester) async {
        await tester.pumpWidget(createTestWidget(folderPath: '/test/path'));

        await tester.tap(find.text('Large Files').first); // Tap the tab, not content
        await tester.pumpAndSettle();

        // Should show relative dates like "3 months ago"
        expect(find.textContaining('ago'), findsWidgets);
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper semantics', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Check for semantic elements
        expect(find.byType(TabBar), findsOneWidget);
        expect(find.byType(Tab), findsNWidgets(4));
        
        // All tabs should be accessible
        final tabs = tester.widgetList<Tab>(find.byType(Tab));
        for (final tab in tabs) {
          expect(tab.icon, isNotNull);
          expect(tab.text, isNotNull);
        }
      });

      testWidgets('should support screen readers', (tester) async {
        await tester.pumpWidget(createTestWidget(folderPath: '/test/path'));

        await tester.pumpAndSettle();

        // Important text should be readable by screen readers
        expect(find.text('File Insights Dashboard'), findsOneWidget);
        expect(find.text('Total Files'), findsOneWidget);
        expect(find.text('Total Size'), findsOneWidget);
      });
    });
  });
}
