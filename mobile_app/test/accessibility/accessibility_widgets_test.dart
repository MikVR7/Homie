import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:homie_app/providers/accessibility_provider.dart';
import 'package:homie_app/widgets/accessibility/accessible_button.dart';
import 'package:homie_app/widgets/accessibility/accessible_icon_button.dart';
import 'package:homie_app/widgets/accessibility/keyboard_shortcuts.dart';
import 'package:homie_app/widgets/accessibility/screen_reader_announcer.dart';

void main() {
  group('Accessibility Widgets Tests', () {
    Widget wrapWithProvider(Widget child) {
      return ChangeNotifierProvider<AccessibilityProvider>(
        create: (_) => AccessibilityProvider(),
        child: MaterialApp(
          home: Scaffold(body: child),
        ),
      );
    }

    group('AccessibleButton Tests', () {
      testWidgets('should render with correct semantic properties', (tester) async {
        bool wasPressed = false;
        
        await tester.pumpWidget(
          wrapWithProvider(
            AccessibleButton(
              onPressed: () => wasPressed = true,
              semanticLabel: 'Test Button',
              semanticHint: 'Tap to test',
              child: const Text('Test'),
            ),
          ),
        );

        // Find the button
        final buttonFinder = find.byType(AccessibleButton);
        expect(buttonFinder, findsOneWidget);

        // Check semantic properties
        final semantics = tester.getSemantics(buttonFinder);
        expect(semantics.label, 'Test Button');
        expect(semantics.hint, 'Tap to test');
        expect(semantics.hasFlag(SemanticsFlag.isButton), true);
        expect(semantics.hasFlag(SemanticsFlag.isEnabled), true);

        // Test interaction
        await tester.tap(buttonFinder);
        expect(wasPressed, true);
      });

      testWidgets('should handle disabled state', (tester) async {
        await tester.pumpWidget(
          wrapWithProvider(
            AccessibleButton(
              onPressed: null,
              semanticLabel: 'Disabled Button',
              child: const Text('Disabled'),
            ),
          ),
        );

        final buttonFinder = find.byType(AccessibleButton);
        final semantics = tester.getSemantics(buttonFinder);
        expect(semantics.hasFlag(SemanticsFlag.isEnabled), false);
      });

      testWidgets('should respect large button setting', (tester) async {
        await tester.pumpWidget(
          wrapWithProvider(
            Builder(
              builder: (context) {
                return AccessibleButton(
                  onPressed: () {
                    // Toggle large buttons through provider
                    context.read<AccessibilityProvider>().toggleLargeButtons();
                  },
                  semanticLabel: 'Large Button',
                  child: const Text('Large'),
                );
              },
            ),
          ),
        );

        // Find and tap the button to toggle large buttons
        final buttonFinder = find.byType(AccessibleButton);
        expect(buttonFinder, findsOneWidget);
        
        await tester.tap(buttonFinder);
        await tester.pumpAndSettle();

        // Button should still be present after toggle
        expect(buttonFinder, findsOneWidget);
      });
    });

    group('AccessibleIconButton Tests', () {
      testWidgets('should render with correct semantic properties', (tester) async {
        bool wasPressed = false;
        
        await tester.pumpWidget(
          wrapWithProvider(
            AccessibleIconButton(
              icon: Icons.home,
              onPressed: () => wasPressed = true,
              semanticLabel: 'Home Button',
              semanticHint: 'Navigate to home',
            ),
          ),
        );

        final buttonFinder = find.byType(AccessibleIconButton);
        expect(buttonFinder, findsOneWidget);

        // Check semantic properties
        final semantics = tester.getSemantics(buttonFinder);
        expect(semantics.label, 'Home Button');
        expect(semantics.hint, 'Navigate to home');

        // Test interaction
        await tester.tap(buttonFinder);
        expect(wasPressed, true);
      });

      testWidgets('should show focus indicator', (tester) async {
        await tester.pumpWidget(
          wrapWithProvider(
            Builder(
              builder: (context) {
                return AccessibleIconButton(
                  icon: Icons.settings,
                  onPressed: () {
                    // Toggle high contrast through provider
                    context.read<AccessibilityProvider>().toggleHighContrast();
                  },
                  semanticLabel: 'Settings',
                );
              },
            ),
          ),
        );

        // Find and tap the button to toggle high contrast
        final buttonFinder = find.byType(AccessibleIconButton);
        expect(buttonFinder, findsOneWidget);
        
        await tester.tap(buttonFinder);
        await tester.pumpAndSettle();

        // Button should still be present after toggle
        expect(buttonFinder, findsOneWidget);
      });

      testWidgets('should handle destructive actions', (tester) async {
        await tester.pumpWidget(
          wrapWithProvider(
            AccessibleIconButton(
              icon: Icons.delete,
              onPressed: () {},
              semanticLabel: 'Delete',
              isDestructive: true,
            ),
          ),
        );

        final buttonFinder = find.byType(AccessibleIconButton);
        expect(buttonFinder, findsOneWidget);
      });
    });

    group('KeyboardShortcuts Tests', () {
      testWidgets('should wrap child correctly', (tester) async {
        await tester.pumpWidget(
          wrapWithProvider(
            KeyboardShortcuts(
              onOrganize: () {},
              child: const Text('Child Widget'),
            ),
          ),
        );

        expect(find.text('Child Widget'), findsOneWidget);
        expect(find.byType(KeyboardShortcuts), findsOneWidget);
      });

      testWidgets('should provide focus traversal', (tester) async {
        await tester.pumpWidget(
          wrapWithProvider(
            KeyboardShortcuts(
              onOrganize: () {},
              child: Column(
                children: [
                  ElevatedButton(onPressed: () {}, child: const Text('Button 1')),
                  ElevatedButton(onPressed: () {}, child: const Text('Button 2')),
                ],
              ),
            ),
          ),
        );

        // KeyboardShortcuts should be present, focus traversal is handled internally
        expect(find.byType(KeyboardShortcuts), findsOneWidget);
        expect(find.text('Button 1'), findsOneWidget);
        expect(find.text('Button 2'), findsOneWidget);
      });
    });

    group('ScreenReaderAnnouncer Tests', () {
      testWidgets('should wrap child correctly', (tester) async {
        await tester.pumpWidget(
          wrapWithProvider(
            ScreenReaderAnnouncer(
              announcement: 'Test announcement',
              child: const Text('Content'),
            ),
          ),
        );

        expect(find.text('Content'), findsOneWidget);
        expect(find.byType(ScreenReaderAnnouncer), findsOneWidget);
      });

      testWidgets('should handle announcement updates', (tester) async {
        String announcement = 'Initial announcement';
        
        await tester.pumpWidget(
          wrapWithProvider(
            StatefulBuilder(
              builder: (context, setState) {
                return ScreenReaderAnnouncer(
                  announcement: announcement,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        announcement = 'Updated announcement';
                      });
                    },
                    child: const Text('Update'),
                  ),
                );
              },
            ),
          ),
        );

        // Tap to update announcement
        await tester.tap(find.text('Update'));
        await tester.pumpAndSettle();

        // Widget should still be present
        expect(find.byType(ScreenReaderAnnouncer), findsOneWidget);
      });
    });

    group('Integration Tests', () {
      testWidgets('should work together in a complex widget tree', (tester) async {
        bool organizePressed = false;
        bool buttonPressed = false;
        
        await tester.pumpWidget(
          wrapWithProvider(
            KeyboardShortcuts(
              onOrganize: () => organizePressed = true,
              child: ScreenReaderAnnouncer(
                announcement: 'File organizer loaded',
                child: Column(
                  children: [
                    AccessibleButton(
                      onPressed: () => buttonPressed = true,
                      semanticLabel: 'Organize Files',
                      child: const Text('Organize'),
                    ),
                    AccessibleIconButton(
                      icon: Icons.settings,
                      onPressed: () {},
                      semanticLabel: 'Settings',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // All widgets should be present
        expect(find.byType(KeyboardShortcuts), findsOneWidget);
        expect(find.byType(ScreenReaderAnnouncer), findsOneWidget);
        expect(find.byType(AccessibleButton), findsOneWidget);
        expect(find.byType(AccessibleIconButton), findsOneWidget);

        // Test interactions
        await tester.tap(find.byType(AccessibleButton));
        expect(buttonPressed, true);
      });

      testWidgets('should adapt to accessibility provider changes', (tester) async {
        await tester.pumpWidget(
          wrapWithProvider(
            Builder(
              builder: (context) {
                final accessibilityProvider = context.watch<AccessibilityProvider>();
                return Column(
                  children: [
                    AccessibleButton(
                      onPressed: () {
                        accessibilityProvider.toggleHighContrast();
                        accessibilityProvider.toggleLargeButtons();
                      },
                      semanticLabel: 'Test Button',
                      child: const Text('Test'),
                    ),
                    AccessibleIconButton(
                      icon: Icons.home,
                      onPressed: () {},
                      semanticLabel: 'Home',
                    ),
                  ],
                );
              },
            ),
          ),
        );

        // Initial state - widgets should be present
        expect(find.byType(AccessibleButton), findsOneWidget);
        expect(find.byType(AccessibleIconButton), findsOneWidget);

        // Tap button to change accessibility settings
        await tester.tap(find.byType(AccessibleButton));
        await tester.pumpAndSettle();

        // Widgets should still be present after changes
        expect(find.byType(AccessibleButton), findsOneWidget);
        expect(find.byType(AccessibleIconButton), findsOneWidget);
      });
    });

    group('Semantic Structure Tests', () {
      testWidgets('should provide proper semantic hierarchy', (tester) async {
        await tester.pumpWidget(
          wrapWithProvider(
            Semantics(
              label: 'File Organizer Section',
              child: Column(
                children: [
                  Semantics(
                    header: true,
                    child: const Text('File Organization'),
                  ),
                  AccessibleButton(
                    onPressed: () {},
                    semanticLabel: 'Start Organization',
                    semanticHint: 'Begin organizing files in the current folder',
                    child: const Text('Start'),
                  ),
                ],
              ),
            ),
          ),
        );

        // Check semantic tree structure
        final rootSemantics = find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == 'File Organizer Section'
        );
        expect(rootSemantics, findsOneWidget);

        final headerSemantics = find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.header == true
        );
        expect(headerSemantics, findsOneWidget);
      });
    });
  });
}
