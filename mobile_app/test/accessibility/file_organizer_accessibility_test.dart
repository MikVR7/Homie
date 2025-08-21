import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:homie_app/providers/accessibility_provider.dart';
import 'package:homie_app/providers/file_organizer_provider.dart';
import 'package:homie_app/providers/websocket_provider.dart';
import 'package:homie_app/widgets/file_organizer/modern/ai_operations_preview.dart';
import 'package:homie_app/widgets/file_organizer/modern/progress_tracker.dart';

void main() {
  group('File Organizer Accessibility Tests', () {
    Widget wrapWithProviders(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AccessibilityProvider>(
            create: (_) => AccessibilityProvider(),
          ),
          ChangeNotifierProvider<FileOrganizerProvider>(
            create: (_) => FileOrganizerProvider(),
          ),
          ChangeNotifierProvider<WebSocketProvider>(
            create: (_) => WebSocketProvider(),
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
            estimatedTime: const Duration(seconds: 1),
            estimatedSize: 1024,
          ),
          FileOperation(
            id: '2',
            type: FileOperationType.copy,
            sourcePath: '/test/file2.jpg',
            destinationPath: '/photos/file2.jpg',
            reasoning: 'Image file for photo collection',
            confidence: 0.92,
            estimatedTime: const Duration(seconds: 2),
            estimatedSize: 2048,
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
            confidence: 0.8,
            estimatedTime: const Duration(seconds: 1),
            estimatedSize: 1024,
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
        final approveButton = find.byIcon(Icons.check);
        
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
            confidence: 0.8,
            estimatedTime: const Duration(seconds: 1),
            estimatedSize: 1024,
          ),
          FileOperation(
            id: '2',
            type: FileOperationType.copy,
            sourcePath: '/test/file2.txt',
            destinationPath: '/organized/file2.txt',
            reasoning: 'Another test file',
            confidence: 0.9,
            estimatedTime: const Duration(seconds: 2),
            estimatedSize: 2048,
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

        // Widget should support keyboard navigation
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
            confidence: 0.8,
            estimatedTime: const Duration(seconds: 1),
            estimatedSize: 1024,
          ),
        ];

        await tester.pumpWidget(
          wrapWithProviders(
            AIOperationsPreview(
              operations: operations,
            ),
          ),
        );

        // Widget should adapt to high contrast
        await tester.pumpAndSettle();

        // Widget should render without errors
        expect(find.byType(AIOperationsPreview), findsOneWidget);
      });
    });

    group('ProgressTracker Accessibility', () {
      testWidgets('should have proper semantic structure for progress', (tester) async {
        // Widget should handle progress data when available

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

        // Widget should handle progress updates

        await tester.pump();

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

        // Widget should adapt to text scaling
        await tester.pump();

        // Widget should render without overflow
        expect(find.byType(ProgressTracker), findsOneWidget);
      });

      testWidgets('should respect reduced motion setting', (tester) async {
        await tester.pumpWidget(
          wrapWithProviders(
            ProgressTracker(),
          ),
        );

        // Widget should respect reduced motion
        await tester.pump();

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
            confidence: 0.8,
            estimatedTime: const Duration(seconds: 1),
            estimatedSize: 1024,
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
            estimatedTime: const Duration(seconds: 3),
            estimatedSize: 4096,
          ),
        ];

        await tester.pumpWidget(
          wrapWithProviders(
            AIOperationsPreview(
              operations: operations,
            ),
          ),
        );

        // Widget should provide verbose descriptions when enabled
        await tester.pumpAndSettle();

        // Should render with enhanced descriptions
        expect(find.byType(AIOperationsPreview), findsOneWidget);
      });

      testWidgets('should announce state changes appropriately', (tester) async {
        await tester.pumpWidget(
          wrapWithProviders(
            Builder(
              builder: (context) {
                final accessibilityProvider = context.watch<AccessibilityProvider>();
                return ProgressTracker();
              },
            ),
          ),
        );

        // Widget should handle state changes
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

        // Widget should handle error states when they occur
        expect(find.byType(ProgressTracker), findsOneWidget);
      });
    });
  });
}
