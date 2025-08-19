import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:homie_app/screens/file_organizer/modern_file_organizer_screen.dart';
import 'package:homie_app/providers/file_organizer_provider.dart';
import 'package:homie_app/providers/websocket_provider.dart';
import 'package:homie_app/theme/app_theme.dart';

/// Test helper to create a testable widget with all required providers
Widget createTestWidget({
  bool isStandaloneLaunch = false,
  FileOrganizerProvider? fileOrganizerProvider,
  WebSocketProvider? webSocketProvider,
}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<FileOrganizerProvider>(
          create: (_) => fileOrganizerProvider ?? FileOrganizerProvider(),
        ),
        ChangeNotifierProvider<WebSocketProvider>(
          create: (_) => webSocketProvider ?? WebSocketProvider(),
        ),
      ],
      child: ModernFileOrganizerScreen(
        isStandaloneLaunch: isStandaloneLaunch,
      ),
    ),
  );
}

void main() {
  group('ModernFileOrganizerScreen Tests', () {
    late FileOrganizerProvider mockFileOrganizerProvider;
    late WebSocketProvider mockWebSocketProvider;

    setUp(() {
      mockFileOrganizerProvider = FileOrganizerProvider();
      mockWebSocketProvider = WebSocketProvider();
    });

    group('6.1.1 - Modern Material Design 3 Layout', () {
      testWidgets('displays modern app bar with correct elements', (tester) async {
        await tester.pumpWidget(createTestWidget(
          fileOrganizerProvider: mockFileOrganizerProvider,
          webSocketProvider: mockWebSocketProvider,
        ));

        // Wait for animations to complete
        await tester.pumpAndSettle();

        // Verify app icon and title are present
        expect(find.byIcon(Icons.auto_fix_high_rounded), findsOneWidget);
        expect(find.text('AI File Organizer'), findsOneWidget);

        // Verify settings button is present
        expect(find.byIcon(Icons.settings_rounded), findsOneWidget);

        // Verify connection status indicator is present
        expect(find.text('Disconnected'), findsOneWidget);
      });

      testWidgets('shows back button when not standalone launch', (tester) async {
        await tester.pumpWidget(createTestWidget(
          isStandaloneLaunch: false,
          fileOrganizerProvider: mockFileOrganizerProvider,
          webSocketProvider: mockWebSocketProvider,
        ));

        await tester.pumpAndSettle();

        // Should show back button for non-standalone launch
        expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      });

      testWidgets('hides back button when standalone launch', (tester) async {
        await tester.pumpWidget(createTestWidget(
          isStandaloneLaunch: true,
          fileOrganizerProvider: mockFileOrganizerProvider,
          webSocketProvider: mockWebSocketProvider,
        ));

        await tester.pumpAndSettle();

        // Should not show back button for standalone launch
        expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
      });

      testWidgets('displays welcome section with correct content', (tester) async {
        await tester.pumpWidget(createTestWidget(
          fileOrganizerProvider: mockFileOrganizerProvider,
          webSocketProvider: mockWebSocketProvider,
        ));

        await tester.pumpAndSettle();

        // Verify welcome section elements
        expect(find.text('AI-Powered File Organization'), findsOneWidget);
        expect(find.text('Let AI intelligently organize your files based on content, type, and your preferences. Select folders below to get started.'), findsOneWidget);
        expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
      });

      testWidgets('displays configuration panel with header', (tester) async {
        await tester.pumpWidget(createTestWidget(
          fileOrganizerProvider: mockFileOrganizerProvider,
          webSocketProvider: mockWebSocketProvider,
        ));

        await tester.pumpAndSettle();

        // Verify configuration panel
        expect(find.text('Organization Configuration'), findsOneWidget);
        expect(find.byIcon(Icons.tune_rounded), findsAtLeastNWidgets(1));
      });

      testWidgets('displays action buttons with correct labels', (tester) async {
        await tester.pumpWidget(createTestWidget(
          fileOrganizerProvider: mockFileOrganizerProvider,
          webSocketProvider: mockWebSocketProvider,
        ));

        await tester.pumpAndSettle();

        // Verify action buttons are present
        expect(find.text('Analyze Files'), findsOneWidget);
        expect(find.text('Execute Operations'), findsOneWidget);
      });
    });

    group('6.1.2 - Responsive Layout Adaptation', () {
      testWidgets('shows mobile layout on narrow screens', (tester) async {
        // Set small screen size
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createTestWidget(
          fileOrganizerProvider: mockFileOrganizerProvider,
          webSocketProvider: mockWebSocketProvider,
        ));

        await tester.pumpAndSettle();

        // In mobile layout, should have tab navigation
        expect(find.text('Organize'), findsOneWidget);
        expect(find.text('Insights'), findsOneWidget);

        // Should have PageView for mobile layout
        expect(find.byType(PageView), findsOneWidget);

        // Reset the screen size
        addTearDown(() => tester.view.reset());
      });

      testWidgets('shows medium layout on medium screens', (tester) async {
        // Set medium screen size
        tester.view.physicalSize = const Size(1000, 700);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createTestWidget(
          fileOrganizerProvider: mockFileOrganizerProvider,
          webSocketProvider: mockWebSocketProvider,
        ));

        await tester.pumpAndSettle();

        // In medium layout, should have side panel but no sidebar navigation
        expect(find.byType(PageView), findsNothing);

        // Reset the screen size
        addTearDown(() => tester.view.reset());
      });

      testWidgets('shows wide layout on large screens', (tester) async {
        // Set large screen size
        tester.view.physicalSize = const Size(1400, 900);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createTestWidget(
          fileOrganizerProvider: mockFileOrganizerProvider,
          webSocketProvider: mockWebSocketProvider,
        ));

        await tester.pumpAndSettle();

        // In wide layout, should have sidebar navigation
        expect(find.text('File Organizer'), findsOneWidget);
        expect(find.text('Organization'), findsOneWidget);
        expect(find.text('Insights'), findsOneWidget);
        expect(find.text('History'), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);

        // Reset the screen size
        addTearDown(() => tester.view.reset());
      });
    });

    group('6.1.3 - Smooth Animations and Transitions', () {
      testWidgets('performs fade-in animation on load', (tester) async {
        await tester.pumpWidget(createTestWidget(
          fileOrganizerProvider: mockFileOrganizerProvider,
          webSocketProvider: mockWebSocketProvider,
        ));

        // At the beginning, content should be fading in
        expect(find.byType(FadeTransition), findsOneWidget);
        expect(find.byType(SlideTransition), findsOneWidget);

        // Complete the animation
        await tester.pumpAndSettle();

        // Content should be fully visible
        expect(find.text('AI File Organizer'), findsOneWidget);
      });

      testWidgets('animates button states during operations', (tester) async {
        // Set up provider with analyzing state
        mockFileOrganizerProvider.setStatus(OperationStatus.analyzing);

        await tester.pumpWidget(createTestWidget(
          fileOrganizerProvider: mockFileOrganizerProvider,
          webSocketProvider: mockWebSocketProvider,
        ));

        await tester.pumpAndSettle();

        // Should show analyzing state
        expect(find.text('Analyzing...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
      });

      testWidgets('shows smooth color transitions on connection status', (tester) async {
        await tester.pumpWidget(createTestWidget(
          fileOrganizerProvider: mockFileOrganizerProvider,
          webSocketProvider: mockWebSocketProvider,
        ));

        await tester.pumpAndSettle();

        // Initial disconnected state
        expect(find.text('Disconnected'), findsOneWidget);
        expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);

        // Change connection status
        mockWebSocketProvider.setConnectionStatus(ConnectionStatus.connected);
        await tester.pump();

        // Should update to connected state
        expect(find.text('Connected'), findsOneWidget);
        expect(find.byIcon(Icons.wifi_rounded), findsOneWidget);
      });

      testWidgets('animates tab navigation on mobile', (tester) async {
        // Set mobile screen size
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createTestWidget(
          fileOrganizerProvider: mockFileOrganizerProvider,
          webSocketProvider: mockWebSocketProvider,
        ));

        await tester.pumpAndSettle();

        // Tap on Insights tab
        await tester.tap(find.text('Insights'));
        await tester.pumpAndSettle();

        // Should animate to the insights page
        expect(find.byType(PageView), findsOneWidget);

        // Reset the screen size
        addTearDown(() => tester.view.reset());
      });
    });

    group('6.1.4 - Visual Hierarchy and Typography', () {
      testWidgets('uses correct typography hierarchy', (tester) async {
        await tester.pumpWidget(createTestWidget(
          fileOrganizerProvider: mockFileOrganizerProvider,
          webSocketProvider: mockWebSocketProvider,
        ));

        await tester.pumpAndSettle();

        // Find main title and verify it's styled correctly
        final titleWidget = tester.widget<Text>(
          find.text('AI File Organizer')
        );
        expect(titleWidget.style?.fontSize, 20);
        expect(titleWidget.style?.fontWeight, FontWeight.w700);

        // Find welcome section title
        final welcomeTitle = tester.widget<Text>(
          find.text('AI-Powered File Organization')
        );
        expect(welcomeTitle.style?.fontSize, 20);
        expect(welcomeTitle.style?.fontWeight, FontWeight.w700);

        // Find configuration panel title
        final configTitle = tester.widget<Text>(
          find.text('Organization Configuration')
        );
        expect(configTitle.style?.fontSize, 18);
        expect(configTitle.style?.fontWeight, FontWeight.w600);
      });

      testWidgets('maintains proper spacing between elements', (tester) async {
        await tester.pumpWidget(createTestWidget(
          fileOrganizerProvider: mockFileOrganizerProvider,
          webSocketProvider: mockWebSocketProvider,
        ));

        await tester.pumpAndSettle();

        // Verify SizedBox widgets are used for spacing
        expect(find.byType(SizedBox), findsAtLeastNWidgets(5));

        // Verify proper padding is applied
        expect(find.byType(Padding), findsAtLeastNWidgets(3));
      });

      testWidgets('uses consistent color scheme', (tester) async {
        await tester.pumpWidget(createTestWidget(
          fileOrganizerProvider: mockFileOrganizerProvider,
          webSocketProvider: mockWebSocketProvider,
        ));

        await tester.pumpAndSettle();

        // Verify gradient containers are present
        expect(find.byType(Container), findsAtLeastNWidgets(5));

        // Check that icons use consistent colors
        final iconFinder = find.byIcon(Icons.auto_fix_high_rounded);
        expect(iconFinder, findsAtLeastNWidgets(1));
      });
    });

    group('6.1.5 - Interactive Elements', () {
      testWidgets('handles settings dialog interaction', (tester) async {
        await tester.pumpWidget(createTestWidget(
          fileOrganizerProvider: mockFileOrganizerProvider,
          webSocketProvider: mockWebSocketProvider,
        ));

        await tester.pumpAndSettle();

        // Tap settings button
        await tester.tap(find.byIcon(Icons.settings_rounded));
        await tester.pumpAndSettle();

        // Should show settings dialog
        expect(find.text('Settings'), findsOneWidget);
        expect(find.text('Settings panel coming soon...'), findsOneWidget);

        // Close dialog
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();

        // Dialog should be closed
        expect(find.text('Settings panel coming soon...'), findsNothing);
      });

      testWidgets('handles analyze files button interaction', (tester) async {
        await tester.pumpWidget(createTestWidget(
          fileOrganizerProvider: mockFileOrganizerProvider,
          webSocketProvider: mockWebSocketProvider,
        ));

        await tester.pumpAndSettle();

        // Find and tap analyze button
        final analyzeButton = find.text('Analyze Files');
        expect(analyzeButton, findsOneWidget);
        
        await tester.tap(analyzeButton);
        await tester.pump();

        // Provider should be in analyzing state
        expect(mockFileOrganizerProvider.status, OperationStatus.analyzing);
      });

      testWidgets('disables execute button when no operations', (tester) async {
        await tester.pumpWidget(createTestWidget(
          fileOrganizerProvider: mockFileOrganizerProvider,
          webSocketProvider: mockWebSocketProvider,
        ));

        await tester.pumpAndSettle();

        // Execute button should be present but disabled (no operations)
        final executeButton = find.text('Execute Operations');
        expect(executeButton, findsOneWidget);

        // Button should be visually disabled (we can check this by looking for specific styling)
        final buttonWidget = tester.widget<ElevatedButton>(
          find.ancestor(
            of: executeButton,
            matching: find.byType(ElevatedButton),
          ),
        );
        expect(buttonWidget.onPressed, isNull); // Should be disabled
      });
    });

    group('6.1.6 - State Management Integration', () {
      testWidgets('responds to FileOrganizerProvider status changes', (tester) async {
        await tester.pumpWidget(createTestWidget(
          fileOrganizerProvider: mockFileOrganizerProvider,
          webSocketProvider: mockWebSocketProvider,
        ));

        await tester.pumpAndSettle();

        // Initial state
        expect(find.text('Ready to organize files'), findsOneWidget);
        expect(find.text('Analyze Files'), findsOneWidget);

        // Change to analyzing state
        mockFileOrganizerProvider.setStatus(OperationStatus.analyzing);
        await tester.pump();

        // Should update UI
        expect(find.text('Analyzing files...'), findsOneWidget);
        expect(find.text('Analyzing...'), findsOneWidget);

        // Change to completed state
        mockFileOrganizerProvider.setStatus(OperationStatus.completed);
        await tester.pump();

        // Should update UI again
        expect(find.text('Organization complete'), findsOneWidget);
      });

      testWidgets('responds to WebSocketProvider connection changes', (tester) async {
        await tester.pumpWidget(createTestWidget(
          fileOrganizerProvider: mockFileOrganizerProvider,
          webSocketProvider: mockWebSocketProvider,
        ));

        await tester.pumpAndSettle();

        // Initial disconnected state
        expect(find.text('Disconnected'), findsOneWidget);

        // Change to connecting
        mockWebSocketProvider.setConnectionStatus(ConnectionStatus.connecting);
        await tester.pump();

        expect(find.text('Connecting'), findsOneWidget);

        // Change to connected
        mockWebSocketProvider.setConnectionStatus(ConnectionStatus.connected);
        await tester.pump();

        expect(find.text('Connected'), findsOneWidget);

        // Change to authenticated
        mockWebSocketProvider.setConnectionStatus(ConnectionStatus.authenticated);
        await tester.pump();

        expect(find.text('Ready'), findsOneWidget);
      });
    });
  });
}
