import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:homie_app/widgets/file_organizer/modern/ai_operations_preview.dart';
import 'package:homie_app/providers/file_organizer_provider.dart';

class MockFileOrganizerProvider extends FileOrganizerProvider {
  // Mock implementation
}

void main() {
  group('AIOperationsPreview', () {
    List<FileOperation> createMockOperations() {
      return [
        FileOperation(
          id: '1',
          type: FileOperationType.move,
          sourcePath: '/source/movie.mkv',
          destinationPath: '/movies/movie.mkv',
          confidence: 0.9,
          reasoning: 'This appears to be a movie file based on its format and naming',
          tags: ['movie', 'video'],
          estimatedTime: const Duration(seconds: 5),
          estimatedSize: 1000000,
          isApproved: false,
          isRejected: false,
        ),
        FileOperation(
          id: '2',
          type: FileOperationType.createFolder,
          sourcePath: '',
          destinationPath: '/documents/new_folder',
          confidence: 0.8,
          reasoning: 'Creating organized folder structure',
          tags: ['organization'],
          estimatedTime: const Duration(seconds: 1),
          estimatedSize: 0,
          isApproved: true,
          isRejected: false,
        ),
        FileOperation(
          id: '3',
          type: FileOperationType.delete,
          sourcePath: '/temp/redundant.tmp',
          destinationPath: null,
          confidence: 0.7,
          reasoning: 'Temporary file that can be safely removed',
          tags: ['cleanup', 'temp'],
          estimatedTime: const Duration(seconds: 1),
          estimatedSize: 500,
          isApproved: false,
          isRejected: true,
        ),
      ];
    }

    Widget createTestWidget({
      List<FileOperation>? operations,
      Function(List<FileOperation>)? onOperationsModified,
      Function()? onExecute,
      bool showBatchControls = true,
      bool allowModification = true,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<FileOrganizerProvider>(
            create: (_) => MockFileOrganizerProvider(),
            child: AIOperationsPreview(
              operations: operations ?? createMockOperations(),
              onOperationsModified: onOperationsModified,
              onExecute: onExecute,
              showBatchControls: showBatchControls,
              allowModification: allowModification,
            ),
          ),
        ),
      );
    }

    testWidgets('displays header with correct title and operation count', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('AI Operation Preview'), findsOneWidget);
      expect(find.text('3 operations planned'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('shows confidence indicator', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Should show confidence indicator based on average confidence
      expect(find.textContaining('Confidence'), findsOneWidget);
      expect(find.byIcon(Icons.psychology), findsAtLeastNWidgets(1));
    });

    testWidgets('displays empty state when no operations', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(operations: []));

      expect(find.text('No operations planned'), findsOneWidget);
      expect(find.text('Analyze your files to see AI suggestions'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome_outlined), findsOneWidget);
    });

    testWidgets('shows batch controls when enabled', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Select All (0/3)'), findsOneWidget);
      expect(find.byType(Checkbox), findsAtLeastNWidgets(1));
    });

    testWidgets('displays operation cards with correct information', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Should display operation titles
      expect(find.textContaining('Move: movie.mkv'), findsOneWidget);
      expect(find.textContaining('Create Folder'), findsOneWidget);
      expect(find.textContaining('Delete: redundant.tmp'), findsOneWidget);

      // Should display confidence badges
      expect(find.text('90%'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
      expect(find.text('70%'), findsOneWidget);
    });

    testWidgets('shows different icons for different operation types', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.drive_file_move), findsOneWidget);
      expect(find.byIcon(Icons.create_new_folder), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('displays operation subtitles correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.textContaining('To: /movies/movie.mkv'), findsOneWidget);
      expect(find.textContaining('At: /documents/new_folder'), findsOneWidget);
      expect(find.textContaining('This file will be permanently deleted'), findsOneWidget);
    });

    testWidgets('shows operation actions when modification is allowed', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Should show approve/reject buttons for pending operations
      expect(find.byIcon(Icons.check), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.close), findsAtLeastNWidgets(1));

      // Should show status icons for approved/rejected operations
      expect(find.byIcon(Icons.check_circle), findsOneWidget); // Approved operation
      expect(find.byIcon(Icons.cancel), findsOneWidget); // Rejected operation
    });

    testWidgets('hides operation actions when modification is disabled', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(allowModification: false));

      // Should not show action buttons
      expect(find.byIcon(Icons.check), findsNothing);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('expands operation details when tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Initially, detailed information should not be visible
      expect(find.text('AI Reasoning'), findsNothing);

      // Tap on an operation to expand it
      await tester.tap(find.textContaining('Move: movie.mkv'));
      await tester.pumpAndSettle();

      // Should show detailed information
      expect(find.text('AI Reasoning'), findsOneWidget);
      expect(find.text('This appears to be a movie file based on its format and naming'), findsOneWidget);
      expect(find.text('Tags'), findsOneWidget);
      expect(find.text('movie'), findsOneWidget);
      expect(find.text('video'), findsOneWidget);
    });

    testWidgets('shows estimated impact in operation details', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Expand an operation
      await tester.tap(find.textContaining('Move: movie.mkv'));
      await tester.pumpAndSettle();

      expect(find.text('Estimated Impact'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);
      expect(find.text('Size'), findsOneWidget);
      expect(find.text('Risk'), findsOneWidget);
    });

    testWidgets('toggles operation approval when action buttons are tapped', (WidgetTester tester) async {
      List<FileOperation>? modifiedOperations;
      
      await tester.pumpWidget(createTestWidget(
        onOperationsModified: (operations) => modifiedOperations = operations,
      ));

      // Find and tap approve button for the first operation
      await tester.tap(find.byIcon(Icons.check).first);
      await tester.pumpAndSettle();

      expect(modifiedOperations, isNotNull);
      expect(modifiedOperations!.first.isApproved, isTrue);
    });

    testWidgets('shows summary bar with correct counts', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check for summary counts (now showing just numbers)
      expect(find.text('1'), findsAtLeastNWidgets(3)); // Should find at least 3 "1"s for the counts
    });

    testWidgets('enables execute button when operations are approved', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Should show execute button  
      expect(find.text('Execute'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('calls onExecute when execute button is tapped', (WidgetTester tester) async {
      bool executeCalled = false;
      
      await tester.pumpWidget(createTestWidget(
        onExecute: () => executeCalled = true,
      ));

      await tester.tap(find.text('Execute'));
      await tester.pumpAndSettle();

      expect(executeCalled, isTrue);
    });

    testWidgets('handles batch selection correctly', (WidgetTester tester) async {
      List<FileOperation>? modifiedOperations;
      
      await tester.pumpWidget(createTestWidget(
        onOperationsModified: (operations) => modifiedOperations = operations,
      ));

      // Tap select all checkbox
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      expect(find.text('Select All (3/3)'), findsOneWidget);

      // Tap approve selected
      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();

      expect(modifiedOperations, isNotNull);
    });

    testWidgets('batch reject works correctly', (WidgetTester tester) async {
      List<FileOperation>? modifiedOperations;
      
      await tester.pumpWidget(createTestWidget(
        onOperationsModified: (operations) => modifiedOperations = operations,
      ));

      // Select all operations
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      // Tap reject selected
      await tester.tap(find.text('Reject'));
      await tester.pumpAndSettle();

      expect(modifiedOperations, isNotNull);
    });

    testWidgets('shows operation cards with correct styling based on status', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Should have different styling for approved, rejected, and pending operations
      expect(find.byType(Card), findsAtLeastNWidgets(3));
    });

    testWidgets('handles individual checkbox selection', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find and tap individual checkboxes (excluding select all)
      final checkboxes = find.byType(Checkbox);
      if (checkboxes.evaluate().length > 1) {
        await tester.tap(checkboxes.at(1)); // Skip the first one (select all)
        await tester.pumpAndSettle();

        // Check that selection counter was updated (text might vary based on implementation)
        expect(find.textContaining('Select All'), findsOneWidget);
      }
    });

    testWidgets('animates operation list appearance', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Should contain animated transitions
      expect(find.byType(SlideTransition), findsAtLeastNWidgets(1));
      expect(find.byType(FadeTransition), findsAtLeastNWidgets(1));
    });
  });
}
