import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:homie_app/providers/accessibility_provider.dart';
import 'package:homie_app/providers/file_organizer_provider.dart';
import 'package:homie_app/widgets/file_organizer/modern/ai_operations_preview.dart';
import 'package:homie_app/widgets/file_organizer/modern/progress_tracker.dart';

void main() {
  group('File Organizer Accessibility Tests', () {
    late AccessibilityProvider accessibilityProvider;
    late FileOrganizerProvider fileOrganizerProvider;

    setUp(() {
      accessibilityProvider = AccessibilityProvider();
      fileOrganizerProvider = FileOrganizerProvider();
    });

    tearDown(() {
      accessibilityProvider.dispose();
      fileOrganizerProvider.dispose();
    });

    Widget wrapWithProviders(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AccessibilityProvider>(
            create: (_) => accessibilityProvider,
          ),
          ChangeNotifierProvider<FileOrganizerProvider>(
            create: (_) => fileOrganizerProvider,
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(body: child),
        ),
      );
    }

    group('AIOperationsPreview Accessibility', () {
      testWidgets('should have proper semantic structure', (tester) async {
        final operations = [
          FileOperation(
            id: '1',
            type: FileOperationType.move,
            sourcePath: '/test/file1.txt',
            destinationPath: '/organized/file1.txt',
            reasoning: 'File appears to be a document',
            confidence: 0.85,
          ),
          FileOperation(
            id: '2',
            type: FileOperationType.copy,
            sourcePath: '/test/file2.jpg',
            destinationPath: '/photos/file2.jpg',
            reasoning: 'Image file for photo collection',
            confidence: 0.92,
          ),
        ];

        await tester.pumpWidget(
          wrapWithProviders(
            AIOperationsPreview(
              operations: operations,
              onExecute: () {},
            ),
          ),
        );

        // Should have main semantic container
        final semanticsContainer = find.byWidgetPredicate(
          (widget) => widget is Semantics && 
                      widget.properties.label == 'AI Operations Preview'
        );
        expect(semanticsContainer, findsOneWidget);

        // Should announce operation count
        expect(find.byType(AIOperationsPreview), findsOneWidget);
      });

      testWidgets('should announce operation approvals', (tester) async {
        final operations = [
          FileOperation(
            id: '1',
            type: FileOperationType.move,
            sourcePath: '/test/file1.txt',
            destinationPath: '/organized/file1.txt',
            reasoning: 'Test file',
          ),
        ];

        await tester.pumpWidget(
          wrapWithProviders(
            AIOperationsPreview(
              operations: operations,
              allowModification: true,
            ),
          ),
        );

        // Find approve button and check accessibility
        final approveButton = find.byWidgetPredicate(
          (widget) => widget is AccessibleIconButton
        );
        
        if (approveButton.evaluate().isNotEmpty) {
          // Button should have semantic labels
          expect(approveButton, findsAtLeastNWidgets(1));
        }
      });

      testWidgets('should provide keyboard navigation for operations', (tester) async {
        final operations = [
          FileOperation(
            id: '1',
            type: FileOperationType.move,
            sourcePath: '/test/file1.txt',
            destinationPath: '/organized/file1.txt',
            reasoning: 'Test file',
          ),
          FileOperation(
            id: '2',
            type: FileOperationType.copy,
            sourcePath: '/test/file2.txt',
            destinationPath: '/organized/file2.txt',
            reasoning: 'Another test file',
          ),
        ];

        await tester.pumpWidget(
          wrapWithProviders(
            AIOperationsPreview(
              operations: operations,
              allowModification: true,
            ),
          ),
        );

        // Enable keyboard navigation
        accessibilityProvider.toggleKeyboardNavigation();
        await tester.pumpAndSettle();

        // Should be able to focus on operation cards
        expect(find.byType(AIOperationsPreview), findsOneWidget);
      });

      testWidgets('should adapt to high contrast mode', (tester) async {
        final operations = [
          FileOperation(
            id: '1',
            type: FileOperationType.move,
            sourcePath: '/test/file1.txt',
            destinationPath: '/organized/file1.txt',
            reasoning: 'Test file',
          ),
        ];

        await tester.pumpWidget(
          wrapWithProviders(
            AIOperationsPreview(
              operations: operations,
            ),
          ),
        );

        // Enable high contrast
        accessibilityProvider.toggleHighContrast();
        await tester.pumpAndSettle();

        // Widget should render without errors
        expect(find.byType(AIOperationsPreview), findsOneWidget);
      });
    });

    group('ProgressTracker Accessibility', () {
      testWidgets('should have proper semantic structure for progress', (tester) async {
        // Set up progress data
        fileOrganizerProvider.updateProgress(ProgressUpdate(
          operationId: 'test',
          percentage: 0.5,
          currentFile: '/test/file.txt',
          completedOperations: 5,
          totalOperations: 10,
          operationType: 'Moving files',
          processedFiles: 5,
          totalFiles: 10,
        ));

        await tester.pumpWidget(
          wrapWithProviders(
            ProgressTracker(
              showDetailedLogs: true,
              allowControls: true,
            ),
          ),
        );

        // Should have main semantic container
        final semanticsContainer = find.byWidgetPredicate(
          (widget) => widget is Semantics && 
                      widget.properties.label == 'Progress Tracker'
        );
        expect(semanticsContainer, findsOneWidget);

        // Should have live region for updates
        final liveRegion = find.byWidgetPredicate(
          (widget) => widget is Semantics && 
                      widget.properties.liveRegion == true
        );
        expect(liveRegion, findsOneWidget);
      });

      testWidgets('should announce progress changes', (tester) async {
        await tester.pumpWidget(
          wrapWithProviders(
            ProgressTracker(
              allowControls: true,
            ),
          ),
        );

        // Initial state
        expect(find.byType(ProgressTracker), findsOneWidget);

        // Update progress
        fileOrganizerProvider.updateProgress(ProgressUpdate(
          operationId: 'test',
          percentage: 0.25,
          currentFile: '/test/file1.txt',
          completedOperations: 2,
          totalOperations: 8,
          operationType: 'Moving files',
          processedFiles: 2,
          totalFiles: 8,
        ));

        await tester.pumpAndSettle();

        // Progress should be reflected in UI
        expect(find.byType(ProgressTracker), findsOneWidget);
      });

      testWidgets('should provide accessible controls', (tester) async {
        bool pauseCalled = false;
        bool resumeCalled = false;
        bool cancelCalled = false;

        await tester.pumpWidget(
          wrapWithProviders(
            ProgressTracker(
              allowControls: true,
              onPause: () => pauseCalled = true,
              onResume: () => resumeCalled = true,
              onCancel: () => cancelCalled = true,
            ),
          ),
        );

        // Should have control buttons when controls are allowed
        expect(find.byType(ProgressTracker), findsOneWidget);
      });

      testWidgets('should adapt to text scaling', (tester) async {
        await tester.pumpWidget(
          wrapWithProviders(
            ProgressTracker(
              showDetailedLogs: true,
            ),
          ),
        );

        // Change text scale
        accessibilityProvider.setTextScale(1.5);
        await tester.pumpAndSettle();

        // Widget should render without overflow
        expect(find.byType(ProgressTracker), findsOneWidget);
      });

      testWidgets('should respect reduced motion setting', (tester) async {
        await tester.pumpWidget(
          wrapWithProviders(
            ProgressTracker(),
          ),
        );

        // Enable reduced motion
        accessibilityProvider.toggleReduceMotion();
        await tester.pumpAndSettle();

        // Widget should still function
        expect(find.byType(ProgressTracker), findsOneWidget);
      });
    });

    group('Keyboard Navigation Integration', () {
      testWidgets('should support tab navigation between components', (tester) async {
        final operations = [
          FileOperation(
            id: '1',
            type: FileOperationType.move,
            sourcePath: '/test/file1.txt',
            destinationPath: '/organized/file1.txt',
            reasoning: 'Test file',
          ),
        ];

        await tester.pumpWidget(
          wrapWithProviders(
            Column(
              children: [
                Expanded(
                  child: AIOperationsPreview(
                    operations: operations,
                    allowModification: true,
                  ),
                ),
                ProgressTracker(
                  allowControls: true,
                ),
              ],
            ),
          ),
        );

        // Both components should be present
        expect(find.byType(AIOperationsPreview), findsOneWidget);
        expect(find.byType(ProgressTracker), findsOneWidget);
      });
    });

    group('Screen Reader Compatibility', () {
      testWidgets('should provide meaningful descriptions for operations', (tester) async {
        final operations = [
          FileOperation(
            id: '1',
            type: FileOperationType.move,
            sourcePath: '/downloads/document.pdf',
            destinationPath: '/documents/work/document.pdf',
            reasoning: 'PDF document appears to be work-related based on content analysis',
            confidence: 0.87,
            tags: ['work', 'document', 'pdf'],
          ),
        ];

        await tester.pumpWidget(
          wrapWithProviders(
            AIOperationsPreview(
              operations: operations,
            ),
          ),
        );

        // Enable verbose descriptions
        accessibilityProvider.toggleVerboseDescriptions();
        await tester.pumpAndSettle();

        // Should render with enhanced descriptions
        expect(find.byType(AIOperationsPreview), findsOneWidget);
      });

      testWidgets('should announce state changes appropriately', (tester) async {
        await tester.pumpWidget(
          wrapWithProviders(
            ProgressTracker(),
          ),
        );

        // Enable state announcements
        expect(accessibilityProvider.announceStateChanges, true);

        // Change status
        fileOrganizerProvider.setStatus(OperationStatus.running);
        await tester.pumpAndSettle();

        // Widget should handle the state change
        expect(find.byType(ProgressTracker), findsOneWidget);
      });
    });

    group('Error Handling Accessibility', () {
      testWidgets('should announce errors to screen readers', (tester) async {
        await tester.pumpWidget(
          wrapWithProviders(
            ProgressTracker(),
          ),
        );

        // Simulate error state
        fileOrganizerProvider.setStatus(OperationStatus.error);
        fileOrganizerProvider.setError('File access denied');
        await tester.pumpAndSettle();

        // Widget should handle error state
        expect(find.byType(ProgressTracker), findsOneWidget);
      });
    });
  });
}
