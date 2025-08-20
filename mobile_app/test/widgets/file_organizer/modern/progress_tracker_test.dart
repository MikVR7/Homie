import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:homie_app/widgets/file_organizer/modern/progress_tracker.dart';
import 'package:homie_app/providers/file_organizer_provider.dart';
import 'package:homie_app/providers/websocket_provider.dart';

class MockFileOrganizerProvider extends FileOrganizerProvider {
  OperationStatus _mockStatus = OperationStatus.idle;
  ProgressUpdate? _mockProgress;

  @override
  OperationStatus get status => _mockStatus;

  @override
  ProgressUpdate? get currentProgress => _mockProgress;

  void setMockStatus(OperationStatus status) {
    _mockStatus = status;
    notifyListeners();
  }

  void setMockProgress(ProgressUpdate progress) {
    _mockProgress = progress;
    notifyListeners();
  }
}

class MockWebSocketProvider extends WebSocketProvider {
  @override
  bool get isConnected => true;
}

void main() {
  group('ProgressTracker', () {
    Widget createTestWidget({
      FileOrganizerProvider? fileProvider,
      WebSocketProvider? wsProvider,
      Function()? onPause,
      Function()? onResume,
      Function()? onCancel,
      bool showDetailedLogs = true,
      bool allowControls = true,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: MultiProvider(
            providers: [
              ChangeNotifierProvider<FileOrganizerProvider>(
                create: (_) => fileProvider ?? MockFileOrganizerProvider(),
              ),
              ChangeNotifierProvider<WebSocketProvider>(
                create: (_) => wsProvider ?? MockWebSocketProvider(),
              ),
            ],
            child: ProgressTracker(
              onPause: onPause,
              onResume: onResume,
              onCancel: onCancel,
              showDetailedLogs: showDetailedLogs,
              allowControls: allowControls,
            ),
          ),
        ),
      );
    }

    ProgressUpdate createMockProgress({
      double percentage = 50.0,
      int completed = 5,
      int total = 10,
      String currentFile = 'test_file.txt',
      Duration elapsed = const Duration(minutes: 2),
      Duration? estimated,
      int filesPerSecond = 2,
    }) {
      return ProgressUpdate(
        operationId: 'test_op_1',
        completedOperations: completed,
        totalOperations: total,
        percentage: percentage,
        currentFile: currentFile,
        elapsed: elapsed,
        estimated: estimated ?? const Duration(minutes: 2),
        filesPerSecond: filesPerSecond,
        recentErrors: [],
        status: OperationStatus.executing,

      );
    }

    testWidgets('displays idle state by default', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Ready to Begin'), findsOneWidget);
      expect(find.text('No operations in progress'), findsOneWidget);
      expect(find.text('Start file analysis to see progress here'), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsAtLeastNWidgets(1));
    });

    testWidgets('shows analyzing state correctly', (WidgetTester tester) async {
      final mockProvider = MockFileOrganizerProvider();
      mockProvider.setMockStatus(OperationStatus.analyzing);

      await tester.pumpWidget(createTestWidget(fileProvider: mockProvider));

      expect(find.text('Analyzing Files'), findsOneWidget);
      expect(find.text('AI is analyzing your files'), findsOneWidget);
      expect(find.byIcon(Icons.analytics), findsOneWidget);
    });

    testWidgets('displays executing state with progress', (WidgetTester tester) async {
      final mockProvider = MockFileOrganizerProvider();
      mockProvider.setMockStatus(OperationStatus.executing);
      mockProvider.setMockProgress(createMockProgress());

      await tester.pumpWidget(createTestWidget(fileProvider: mockProvider));

      expect(find.text('Processing Files'), findsOneWidget);
      expect(find.text('Moving and organizing files'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('shows progress bar with correct percentage', (WidgetTester tester) async {
      final mockProvider = MockFileOrganizerProvider();
      mockProvider.setMockStatus(OperationStatus.executing);
      mockProvider.setMockProgress(createMockProgress(percentage: 75.0));

      await tester.pumpWidget(createTestWidget(fileProvider: mockProvider));

      expect(find.text('Progress'), findsOneWidget);
      expect(find.text('75.0% Complete'), findsOneWidget);
      expect(find.text('5/10'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('displays operation details correctly', (WidgetTester tester) async {
      final mockProvider = MockFileOrganizerProvider();
      mockProvider.setMockStatus(OperationStatus.executing);
      mockProvider.setMockProgress(createMockProgress(
        currentFile: 'important_document.pdf',
        filesPerSecond: 3,
      ));

      await tester.pumpWidget(createTestWidget(fileProvider: mockProvider));

      expect(find.text('Current File'), findsOneWidget);
      expect(find.text('important_document.pdf'), findsOneWidget);
      expect(find.text('Processing Speed'), findsOneWidget);
      expect(find.text('3 files/sec'), findsOneWidget);
      expect(find.text('Elapsed Time'), findsOneWidget);
    });

    testWidgets('shows ETA when available', (WidgetTester tester) async {
      final mockProvider = MockFileOrganizerProvider();
      mockProvider.setMockStatus(OperationStatus.executing);
      mockProvider.setMockProgress(createMockProgress(
        estimated: const Duration(minutes: 3, seconds: 30),
      ));

      await tester.pumpWidget(createTestWidget(fileProvider: mockProvider));

      expect(find.textContaining('ETA:'), findsOneWidget);
    });

    testWidgets('displays pause and cancel buttons when executing', (WidgetTester tester) async {
      bool pauseCalled = false;
      bool cancelCalled = false;

      final mockProvider = MockFileOrganizerProvider();
      mockProvider.setMockStatus(OperationStatus.executing);
      mockProvider.setMockProgress(createMockProgress());

      await tester.pumpWidget(createTestWidget(
        fileProvider: mockProvider,
        onPause: () => pauseCalled = true,
        onCancel: () => cancelCalled = true,
      ));

      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Pause'));
      expect(pauseCalled, isTrue);

      await tester.tap(find.text('Cancel'));
      expect(cancelCalled, isTrue);
    });

    testWidgets('shows resume and cancel buttons when paused', (WidgetTester tester) async {
      bool resumeCalled = false;
      bool cancelCalled = false;

      final mockProvider = MockFileOrganizerProvider();
      mockProvider.setMockStatus(OperationStatus.paused);
      mockProvider.setMockProgress(createMockProgress());

      await tester.pumpWidget(createTestWidget(
        fileProvider: mockProvider,
        onResume: () => resumeCalled = true,
        onCancel: () => cancelCalled = true,
      ));

      expect(find.text('Resume'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Resume'));
      expect(resumeCalled, isTrue);

      await tester.tap(find.text('Cancel'));
      expect(cancelCalled, isTrue);
    });

    testWidgets('hides control buttons when allowControls is false', (WidgetTester tester) async {
      final mockProvider = MockFileOrganizerProvider();
      mockProvider.setMockStatus(OperationStatus.executing);
      mockProvider.setMockProgress(createMockProgress());

      await tester.pumpWidget(createTestWidget(
        fileProvider: mockProvider,
        allowControls: false,
      ));

      expect(find.text('Pause'), findsNothing);
      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('displays completed state', (WidgetTester tester) async {
      final mockProvider = MockFileOrganizerProvider();
      mockProvider.setMockStatus(OperationStatus.completed);

      await tester.pumpWidget(createTestWidget(fileProvider: mockProvider));

      expect(find.text('Completed Successfully'), findsOneWidget);
      expect(find.text('All operations completed successfully'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('displays error state', (WidgetTester tester) async {
      final mockProvider = MockFileOrganizerProvider();
      mockProvider.setMockStatus(OperationStatus.error);

      await tester.pumpWidget(createTestWidget(fileProvider: mockProvider));

      expect(find.text('Error Occurred'), findsOneWidget);
      expect(find.text('An error occurred during processing'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('displays cancelled state', (WidgetTester tester) async {
      final mockProvider = MockFileOrganizerProvider();
      mockProvider.setMockStatus(OperationStatus.cancelled);

      await tester.pumpWidget(createTestWidget(fileProvider: mockProvider));

      expect(find.text('Operation Cancelled'), findsOneWidget);
      expect(find.text('Operation was cancelled by user'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('shows status indicator with correct styling', (WidgetTester tester) async {
      final mockProvider = MockFileOrganizerProvider();
      mockProvider.setMockStatus(OperationStatus.executing);

      await tester.pumpWidget(createTestWidget(fileProvider: mockProvider));

      expect(find.text('RUNNING'), findsOneWidget);
    });

    testWidgets('animates progress bar updates', (WidgetTester tester) async {
      final mockProvider = MockFileOrganizerProvider();
      mockProvider.setMockStatus(OperationStatus.executing);
      mockProvider.setMockProgress(createMockProgress(percentage: 25.0));

      await tester.pumpWidget(createTestWidget(fileProvider: mockProvider));

      // Should contain animated progress bar
      expect(find.byType(AnimatedBuilder), findsAtLeastNWidgets(1));
    });

    testWidgets('pulses icon during execution', (WidgetTester tester) async {
      final mockProvider = MockFileOrganizerProvider();
      mockProvider.setMockStatus(OperationStatus.executing);
      mockProvider.setMockProgress(createMockProgress());

      await tester.pumpWidget(createTestWidget(fileProvider: mockProvider));

      // Should have pulsing animation for executing status
      expect(find.byType(AnimatedBuilder), findsAtLeastNWidgets(1));
    });

    testWidgets('shows logs section when enabled', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(showDetailedLogs: true));

      expect(find.text('Operation Logs'), findsOneWidget);
      expect(find.text('Show Logs'), findsOneWidget);
    });

    testWidgets('hides logs section when disabled', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(showDetailedLogs: false));

      expect(find.text('Operation Logs'), findsNothing);
    });

    testWidgets('toggles logs visibility when button is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(showDetailedLogs: true));

      // Initially should show "Show Logs"
      expect(find.text('Show Logs'), findsOneWidget);

      await tester.tap(find.text('Show Logs'));
      await tester.pumpAndSettle();

      // Should change to "Hide Logs"
      expect(find.text('Hide Logs'), findsOneWidget);
    });

    testWidgets('handles progress with errors', (WidgetTester tester) async {
      final mockProvider = MockFileOrganizerProvider();
      mockProvider.setMockStatus(OperationStatus.executing);
      mockProvider.setMockProgress(ProgressUpdate(
        operationId: 'test_op_1',
        completedOperations: 5,
        totalOperations: 10,
        percentage: 50.0,
        currentFile: 'test_file.txt',
        elapsed: const Duration(minutes: 2),
        estimated: const Duration(minutes: 2),
        filesPerSecond: 2,
        recentErrors: ['Error 1', 'Error 2'],
        status: OperationStatus.executing,

      ));

      await tester.pumpWidget(createTestWidget(fileProvider: mockProvider));

      expect(find.text('Recent Errors'), findsOneWidget);
      expect(find.text('2 errors'), findsOneWidget);
    });

    testWidgets('formats time durations correctly', (WidgetTester tester) async {
      final mockProvider = MockFileOrganizerProvider();
      mockProvider.setMockStatus(OperationStatus.executing);
      mockProvider.setMockProgress(createMockProgress(
        elapsed: const Duration(hours: 1, minutes: 30, seconds: 45),
      ));

      await tester.pumpWidget(createTestWidget(fileProvider: mockProvider));

      expect(find.textContaining('1h 30m 45s'), findsOneWidget);
    });

    testWidgets('shows appropriate progress bar color for different states', (WidgetTester tester) async {
      final mockProvider = MockFileOrganizerProvider();
      
      // Test error state
      mockProvider.setMockStatus(OperationStatus.error);
      mockProvider.setMockProgress(createMockProgress());

      await tester.pumpWidget(createTestWidget(fileProvider: mockProvider));

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}
