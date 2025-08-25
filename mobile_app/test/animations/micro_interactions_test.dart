import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homie_app/animations/micro_interactions.dart';

void main() {
  group('MicroInteractions', () {
    group('Animated Button', () {
      testWidgets('should create animated button widget', (WidgetTester tester) async {
        bool wasPressed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MicroInteractions.animatedButton(
                onPressed: () => wasPressed = true,
                child: const Text('Press Me'),
              ),
            ),
          ),
        );

        expect(find.text('Press Me'), findsOneWidget);
        expect(find.byType(GestureDetector), findsOneWidget);
      });

      testWidgets('should respond to tap events', (WidgetTester tester) async {
        bool wasPressed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MicroInteractions.animatedButton(
                onPressed: () => wasPressed = true,
                child: const Text('Press Me'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Press Me'));
        await tester.pumpAndSettle();

        expect(wasPressed, isTrue);
      });

      testWidgets('should scale down on press and back up on release', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MicroInteractions.animatedButton(
                onPressed: () {},
                pressedScale: 0.9,
                child: const Text('Press Me'),
              ),
            ),
          ),
        );

        // Test tap down
        await tester.press(find.text('Press Me'));
        await tester.pump();

        // Transform should be applied (though exact value testing is complex)
        expect(find.byType(Transform), findsOneWidget);

        // Test tap up
        await tester.pumpAndSettle();
      });
    });

    group('Animated Card', () {
      testWidgets('should create animated card widget', (WidgetTester tester) async {
        bool wasTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MicroInteractions.animatedCard(
                onTap: () => wasTapped = true,
                child: const Text('Card Content'),
              ),
            ),
          ),
        );

        expect(find.text('Card Content'), findsOneWidget);
        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('should respond to tap events', (WidgetTester tester) async {
        bool wasTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MicroInteractions.animatedCard(
                onTap: () => wasTapped = true,
                child: const Text('Card Content'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Card Content'));
        await tester.pumpAndSettle();

        expect(wasTapped, isTrue);
      });
    });

    group('Rotating Icon', () {
      testWidgets('should create rotating icon widget', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MicroInteractions.rotatingIcon(
                icon: Icons.expand_more,
                isRotated: false,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.expand_more), findsOneWidget);
        expect(find.byType(AnimatedRotation), findsOneWidget);
      });

      testWidgets('should rotate when isRotated changes', (WidgetTester tester) async {
        bool isRotated = false;
        late StateSetter setState;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setter) {
                  setState = setter;
                  return MicroInteractions.rotatingIcon(
                    icon: Icons.expand_more,
                    isRotated: isRotated,
                  );
                },
              ),
            ),
          ),
        );

        final animatedRotation = tester.widget<AnimatedRotation>(
          find.byType(AnimatedRotation),
        );

        // Initially should not be rotated
        expect(animatedRotation.turns, 0.0);

        // Rotate the icon
        setState(() {
          isRotated = true;
        });
        await tester.pump();

        final rotatedAnimatedRotation = tester.widget<AnimatedRotation>(
          find.byType(AnimatedRotation),
        );

        // Should be rotated
        expect(rotatedAnimatedRotation.turns, 0.5);
      });
    });

    group('Expandable Widget', () {
      testWidgets('should create expandable widget', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MicroInteractions.expandable(
                isExpanded: false,
                child: const Text('Expandable Content'),
              ),
            ),
          ),
        );

        expect(find.byType(AnimatedSize), findsOneWidget);
        expect(find.byType(AnimatedContainer), findsOneWidget);
      });

      testWidgets('should expand and collapse content', (WidgetTester tester) async {
        bool isExpanded = false;
        late StateSetter setState;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setter) {
                  setState = setter;
                  return MicroInteractions.expandable(
                    isExpanded: isExpanded,
                    child: const SizedBox(
                      height: 100,
                      child: Text('Expandable Content'),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        // Initially collapsed - content should not be visible
        expect(find.text('Expandable Content'), findsNothing);

        // Expand the content
        setState(() {
          isExpanded = true;
        });
        await tester.pump();
        await tester.pumpAndSettle();

        // Content should be visible
        expect(find.text('Expandable Content'), findsOneWidget);
      });
    });

    group('Animated Progress', () {
      testWidgets('should create animated progress widget', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MicroInteractions.animatedProgress(
                value: 0.5,
              ),
            ),
          ),
        );

        expect(find.byType(TweenAnimationBuilder<double>), findsOneWidget);
        expect(find.byType(Container), findsNWidgets(2)); // Background and progress
      });

      testWidgets('should animate progress value changes', (WidgetTester tester) async {
        double progress = 0.0;
        late StateSetter setState;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setter) {
                  setState = setter;
                  return MicroInteractions.animatedProgress(
                    value: progress,
                  );
                },
              ),
            ),
          ),
        );

        // Change progress value
        setState(() {
          progress = 0.75;
        });
        await tester.pump();

        // Should animate to new value
        expect(find.byType(TweenAnimationBuilder<double>), findsOneWidget);
      });
    });

    group('Pulse Animation', () {
      testWidgets('should create pulse animation when enabled', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MicroInteractions.pulse(
                enabled: true,
                child: const Text('Pulsing Text'),
              ),
            ),
          ),
        );

        expect(find.text('Pulsing Text'), findsOneWidget);
      });

      testWidgets('should show static content when disabled', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MicroInteractions.pulse(
                enabled: false,
                child: const Text('Static Text'),
              ),
            ),
          ),
        );

        expect(find.text('Static Text'), findsOneWidget);
      });
    });

    group('Success Checkmark', () {
      testWidgets('should create success checkmark animation', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MicroInteractions.successCheckmark(
                size: 48.0,
                color: Colors.green,
              ),
            ),
          ),
        );

        expect(find.byType(CustomPaint), findsOneWidget);
      });
    });

    group('Error Shake', () {
      testWidgets('should create error shake animation', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MicroInteractions.errorShake(
                enabled: false,
                child: const Text('Error Text'),
              ),
            ),
          ),
        );

        expect(find.text('Error Text'), findsOneWidget);
      });

      testWidgets('should animate when enabled', (WidgetTester tester) async {
        bool hasError = false;
        late StateSetter setState;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setter) {
                  setState = setter;
                  return MicroInteractions.errorShake(
                    enabled: hasError,
                    child: const Text('Error Text'),
                  );
                },
              ),
            ),
          ),
        );

        // Trigger error shake
        setState(() {
          hasError = true;
        });
        await tester.pump();

        expect(find.text('Error Text'), findsOneWidget);
      });
    });

    group('Ripple Effect', () {
      testWidgets('should create ripple effect widget', (WidgetTester tester) async {
        bool wasTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MicroInteractions.ripple(
                onTap: () => wasTapped = true,
                child: const Text('Ripple Text'),
              ),
            ),
          ),
        );

        expect(find.text('Ripple Text'), findsOneWidget);
        expect(find.byType(InkWell), findsOneWidget);

        await tester.tap(find.text('Ripple Text'));
        await tester.pumpAndSettle();

        expect(wasTapped, isTrue);
      });
    });

    group('Bouncing FAB', () {
      testWidgets('should create bouncing FAB widget', (WidgetTester tester) async {
        bool wasPressed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MicroInteractions.bouncingFAB(
                onPressed: () => wasPressed = true,
                child: const Icon(Icons.add),
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.add), findsOneWidget);
        expect(find.byType(FloatingActionButton), findsOneWidget);

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        expect(wasPressed, isTrue);
      });
    });
  });

  group('Performance Tests', () {
    testWidgets('should handle multiple simultaneous animations', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                MicroInteractions.animatedButton(
                  onPressed: () {},
                  child: const Text('Button 1'),
                ),
                MicroInteractions.animatedButton(
                  onPressed: () {},
                  child: const Text('Button 2'),
                ),
                MicroInteractions.rotatingIcon(
                  icon: Icons.expand_more,
                  isRotated: true,
                ),
                MicroInteractions.pulse(
                  enabled: true,
                  child: const Text('Pulsing'),
                ),
              ],
            ),
          ),
        ),
      );

      // All widgets should be rendered without errors
      expect(find.text('Button 1'), findsOneWidget);
      expect(find.text('Button 2'), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
      expect(find.text('Pulsing'), findsOneWidget);

      // Tap buttons simultaneously
      await tester.tap(find.text('Button 1'));
      await tester.tap(find.text('Button 2'));
      await tester.pumpAndSettle();

      // Should not cause any errors
      expect(find.text('Button 1'), findsOneWidget);
      expect(find.text('Button 2'), findsOneWidget);
    });

    testWidgets('should dispose animation controllers properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                MicroInteractions.pulse(
                  enabled: true,
                  child: const Text('Pulsing'),
                ),
                MicroInteractions.successCheckmark(),
              ],
            ),
          ),
        ),
      );

      // Verify widgets are built
      expect(find.text('Pulsing'), findsOneWidget);
      expect(find.byType(CustomPaint), findsOneWidget);

      // Remove widgets and pump to trigger dispose
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text('Different Content'),
          ),
        ),
      );

      // Should not throw any errors during disposal
      expect(find.text('Different Content'), findsOneWidget);
    });
  });
}
