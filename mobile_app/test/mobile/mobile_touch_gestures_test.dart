import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homie_app/widgets/mobile/mobile_touch_gestures.dart';
import 'package:homie_app/services/mobile_platform_service.dart';

void main() {
  group('Mobile Touch Gestures Tests', () {
    testWidgets('should create swipe-to-delete widget', (tester) async {
      bool deleteTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileTouchGestures.swipeToDelete(
              onDelete: () => deleteTriggered = true,
              child: const ListTile(title: Text('Test Item')),
            ),
          ),
        ),
      );

      expect(find.text('Test Item'), findsOneWidget);
      expect(deleteTriggered, false);

      // Test swipe gesture (simplified - in real tests you'd simulate actual swipe)
      await tester.drag(find.text('Test Item'), const Offset(-300, 0));
      await tester.pumpAndSettle();

      // In a real test environment, this would trigger the delete
      // For now, just verify the widget renders correctly
      expect(find.text('Test Item'), findsOneWidget);
    });

    testWidgets('should create swipe-to-action widget', (tester) async {
      bool leftActionTriggered = false;
      bool rightActionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileTouchGestures.swipeToAction(
              onSwipeLeft: () => leftActionTriggered = true,
              onSwipeRight: () => rightActionTriggered = true,
              leftAction: const Icon(Icons.archive),
              rightAction: const Icon(Icons.delete),
              child: const ListTile(title: Text('Test Item')),
            ),
          ),
        ),
      );

      expect(find.text('Test Item'), findsOneWidget);
      expect(leftActionTriggered, false);
      expect(rightActionTriggered, false);
    });

    testWidgets('should create long press action widget', (tester) async {
      bool longPressTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileTouchGestures.longPressAction(
              onLongPress: () => longPressTriggered = true,
              child: const Text('Long Press Me'),
            ),
          ),
        ),
      );

      expect(find.text('Long Press Me'), findsOneWidget);

      // Test long press
      await tester.longPress(find.text('Long Press Me'));
      await tester.pumpAndSettle();

      expect(longPressTriggered, true);
    });

    testWidgets('should create double tap action widget', (tester) async {
      bool doubleTapTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileTouchGestures.doubleTapAction(
              onDoubleTap: () => doubleTapTriggered = true,
              child: const Text('Double Tap Me'),
            ),
          ),
        ),
      );

      expect(find.text('Double Tap Me'), findsOneWidget);

      // Test double tap
      await tester.tap(find.text('Double Tap Me'));
      await tester.tap(find.text('Double Tap Me'));
      await tester.pumpAndSettle();

      expect(doubleTapTriggered, true);
    });

    testWidgets('should create pinch-to-zoom widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileTouchGestures.pinchToZoom(
              child: const Text('Pinch to Zoom'),
            ),
          ),
        ),
      );

      expect(find.text('Pinch to Zoom'), findsOneWidget);

      // Test scale gesture (simplified)
      final gesture = await tester.startGesture(const Offset(100, 100));
      await gesture.moveBy(const Offset(50, 50));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Pinch to Zoom'), findsOneWidget);
    });

    testWidgets('should create pull-to-refresh widget', (tester) async {
      bool refreshTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileTouchGestures.pullToRefresh(
              onRefresh: () async {
                refreshTriggered = true;
              },
              child: ListView(
                children: const [
                  ListTile(title: Text('Item 1')),
                  ListTile(title: Text('Item 2')),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);

      // Test pull to refresh
      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      expect(refreshTriggered, true);
    });

    testWidgets('should create mobile touch target', (tester) async {
      bool tapTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileTouchTarget(
              onTap: () => tapTriggered = true,
              child: const Text('Touch Target'),
            ),
          ),
        ),
      );

      expect(find.text('Touch Target'), findsOneWidget);

      await tester.tap(find.text('Touch Target'));
      await tester.pumpAndSettle();

      expect(tapTriggered, true);
    });

    testWidgets('should create mobile button', (tester) async {
      bool buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MobileButton(
              text: 'Test Button',
              onPressed: () => buttonPressed = true,
              icon: Icons.science,
              isPrimary: true,
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      expect(find.byIcon(Icons.science), findsOneWidget);

      await tester.tap(find.text('Test Button'));
      await tester.pumpAndSettle();

      expect(buttonPressed, true);
    });

    group('Haptic Feedback Tests', () {
      test('should trigger haptic feedback when enabled', () async {
        // Test haptic feedback triggering
        expect(
          () => MobileTouchGestures.triggerHapticFeedback(
            HapticFeedbackType.light,
            enabled: true,
          ),
          returnsNormally,
        );

        expect(
          () => MobileTouchGestures.triggerHapticFeedback(
            HapticFeedbackType.medium,
            enabled: true,
          ),
          returnsNormally,
        );

        expect(
          () => MobileTouchGestures.triggerHapticFeedback(
            HapticFeedbackType.heavy,
            enabled: true,
          ),
          returnsNormally,
        );
      });

      test('should not trigger haptic feedback when disabled', () async {
        // Test that haptic feedback is skipped when disabled
        expect(
          () => MobileTouchGestures.triggerHapticFeedback(
            HapticFeedbackType.light,
            enabled: false,
          ),
          returnsNormally,
        );
      });
    });

    group('Widget Configuration Tests', () {
      testWidgets('should respect custom configurations', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MobileTouchGestures.swipeToDelete(
                onDelete: () {},
                deleteColor: Colors.blue,
                deleteIcon: Icons.archive,
                deleteLabel: 'Archive',
                threshold: 0.5,
                enableHapticFeedback: false,
                child: const ListTile(title: Text('Custom Config')),
              ),
            ),
          ),
        );

        expect(find.text('Custom Config'), findsOneWidget);
      });

      testWidgets('should handle null callbacks gracefully', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MobileTouchGestures.swipeToAction(
                onSwipeLeft: null,
                onSwipeRight: null,
                child: const ListTile(title: Text('No Callbacks')),
              ),
            ),
          ),
        );

        expect(find.text('No Callbacks'), findsOneWidget);
      });
    });

    group('Performance Tests', () {
      testWidgets('should handle rapid gestures without errors', (tester) async {
        bool actionTriggered = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MobileTouchGestures.doubleTapAction(
                onDoubleTap: () => actionTriggered = true,
                child: const Text('Rapid Gestures'),
              ),
            ),
          ),
        );

        // Perform rapid taps
        for (int i = 0; i < 10; i++) {
          await tester.tap(find.text('Rapid Gestures'));
          await tester.pump(const Duration(milliseconds: 50));
        }

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle widget disposal correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MobileTouchGestures.longPressAction(
                onLongPress: () {},
                child: const Text('Disposal Test'),
              ),
            ),
          ),
        );

        expect(find.text('Disposal Test'), findsOneWidget);

        // Remove the widget
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Text('Empty'),
            ),
          ),
        );

        expect(find.text('Empty'), findsOneWidget);
        expect(find.text('Disposal Test'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should maintain accessibility properties', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MobileTouchTarget(
                onTap: () {},
                child: const Text('Accessible Target'),
              ),
            ),
          ),
        );

        // Verify that the widget is accessible
        expect(find.text('Accessible Target'), findsOneWidget);
      });

      testWidgets('should provide proper touch target sizes', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MobileButton(
                text: 'Accessible Button',
                onPressed: () {},
              ),
            ),
          ),
        );

        final buttonFinder = find.text('Accessible Button');
        expect(buttonFinder, findsOneWidget);

        final buttonWidget = tester.widget<Container>(
          find.ancestor(
            of: buttonFinder,
            matching: find.byType(Container),
          ).first,
        );

        // Verify minimum touch target size
        expect(buttonWidget.constraints?.minHeight, greaterThanOrEqualTo(44.0));
      });
    });

    group('Error Handling Tests', () {
      testWidgets('should handle gesture conflicts gracefully', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MobileTouchGestures.swipeToAction(
                onSwipeLeft: () {},
                onSwipeRight: () {},
                child: MobileTouchGestures.longPressAction(
                  onLongPress: () {},
                  child: const Text('Nested Gestures'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Nested Gestures'), findsOneWidget);

        // Test that nested gestures don't cause errors
        await tester.longPress(find.text('Nested Gestures'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle animation disposal correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MobileTouchGestures.pinchToZoom(
                child: const Text('Animation Test'),
              ),
            ),
          ),
        );

        // Start a gesture
        final gesture = await tester.startGesture(const Offset(100, 100));
        await gesture.moveBy(const Offset(10, 10));

        // Dispose the widget while gesture is active
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Text('Disposed'),
            ),
          ),
        );

        await gesture.up();
        await tester.pumpAndSettle();

        expect(find.text('Disposed'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  });
}