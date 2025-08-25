import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homie_app/animations/material_motion.dart';

void main() {
  group('MaterialMotion', () {
    group('Motion Durations', () {
      test('should provide standard Material Design 3 durations', () {
        expect(MaterialMotion.extraShort, const Duration(milliseconds: 50));
        expect(MaterialMotion.short1, const Duration(milliseconds: 100));
        expect(MaterialMotion.short2, const Duration(milliseconds: 150));
        expect(MaterialMotion.short3, const Duration(milliseconds: 200));
        expect(MaterialMotion.short4, const Duration(milliseconds: 250));
        expect(MaterialMotion.medium1, const Duration(milliseconds: 300));
        expect(MaterialMotion.medium2, const Duration(milliseconds: 350));
        expect(MaterialMotion.medium3, const Duration(milliseconds: 400));
        expect(MaterialMotion.medium4, const Duration(milliseconds: 450));
        expect(MaterialMotion.long1, const Duration(milliseconds: 500));
        expect(MaterialMotion.long2, const Duration(milliseconds: 600));
        expect(MaterialMotion.long3, const Duration(milliseconds: 700));
        expect(MaterialMotion.long4, const Duration(milliseconds: 800));
        expect(MaterialMotion.extraLong1, const Duration(milliseconds: 900));
        expect(MaterialMotion.extraLong2, const Duration(milliseconds: 1000));
        expect(MaterialMotion.extraLong3, const Duration(milliseconds: 1100));
        expect(MaterialMotion.extraLong4, const Duration(milliseconds: 1200));
      });
    });

    group('Motion Curves', () {
      test('should provide Material Design 3 standard curves', () {
        expect(MaterialMotion.emphasized, Curves.easeInOutCubicEmphasized);
        expect(MaterialMotion.standard, Curves.easeInOutCubic);
        expect(MaterialMotion.decelerated, Curves.easeOut);
        expect(MaterialMotion.accelerated, Curves.easeIn);
        expect(MaterialMotion.linear, Curves.linear);
      });
    });

    group('Fade Transition', () {
      testWidgets('should create fade transition widget', (WidgetTester tester) async {
        final animation = AnimationController(
          duration: MaterialMotion.medium1,
          vsync: tester,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MaterialMotion.fadeTransition(
                animation: animation,
                child: const Text('Test Widget'),
              ),
            ),
          ),
        );

        expect(find.text('Test Widget'), findsOneWidget);
        expect(find.byType(FadeTransition), findsOneWidget);
      });

      testWidgets('should animate opacity from 0 to 1', (WidgetTester tester) async {
        final animationController = AnimationController(
          duration: MaterialMotion.medium1,
          vsync: tester,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MaterialMotion.fadeTransition(
                animation: animationController,
                child: const Text('Test Widget'),
              ),
            ),
          ),
        );

        final fadeTransition = tester.widget<FadeTransition>(
          find.byType(FadeTransition),
        );

        // Initially should be transparent
        expect(fadeTransition.opacity.value, 0.0);

        // Start animation
        animationController.forward();
        await tester.pump(MaterialMotion.medium1 ~/ 2);

        // Should be partially visible
        expect(fadeTransition.opacity.value, greaterThan(0.0));
        expect(fadeTransition.opacity.value, lessThan(1.0));

        await tester.pumpAndSettle();

        // Should be fully visible
        expect(fadeTransition.opacity.value, 1.0);
      });
    });

    group('Slide Transition', () {
      testWidgets('should create slide transition widget', (WidgetTester tester) async {
        final animation = AnimationController(
          duration: MaterialMotion.medium2,
          vsync: tester,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MaterialMotion.slideTransition(
                animation: animation,
                child: const Text('Test Widget'),
              ),
            ),
          ),
        );

        expect(find.text('Test Widget'), findsOneWidget);
        expect(find.byType(SlideTransition), findsOneWidget);
      });

      testWidgets('should slide from specified offset', (WidgetTester tester) async {
        final animationController = AnimationController(
          duration: MaterialMotion.medium2,
          vsync: tester,
        );

        const testBegin = Offset(1.0, 0.0);
        const testEnd = Offset.zero;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MaterialMotion.slideTransition(
                animation: animationController,
                begin: testBegin,
                end: testEnd,
                child: const Text('Test Widget'),
              ),
            ),
          ),
        );

        final slideTransition = tester.widget<SlideTransition>(
          find.byType(SlideTransition),
        );

        // Initially should be at begin position
        expect(slideTransition.position.value, testBegin);

        // Start animation
        animationController.forward();
        await tester.pumpAndSettle();

        // Should be at end position
        expect(slideTransition.position.value, testEnd);
      });
    });

    group('Scale Transition', () {
      testWidgets('should create scale transition widget', (WidgetTester tester) async {
        final animation = AnimationController(
          duration: MaterialMotion.short4,
          vsync: tester,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MaterialMotion.scaleTransition(
                animation: animation,
                child: const Text('Test Widget'),
              ),
            ),
          ),
        );

        expect(find.text('Test Widget'), findsOneWidget);
        expect(find.byType(ScaleTransition), findsOneWidget);
      });

      testWidgets('should scale from begin to end values', (WidgetTester tester) async {
        final animationController = AnimationController(
          duration: MaterialMotion.short4,
          vsync: tester,
        );

        const testBegin = 0.5;
        const testEnd = 1.5;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MaterialMotion.scaleTransition(
                animation: animationController,
                begin: testBegin,
                end: testEnd,
                child: const Text('Test Widget'),
              ),
            ),
          ),
        );

        final scaleTransition = tester.widget<ScaleTransition>(
          find.byType(ScaleTransition),
        );

        // Initially should be at begin scale
        expect(scaleTransition.scale.value, testBegin);

        // Start animation
        animationController.forward();
        await tester.pumpAndSettle();

        // Should be at end scale
        expect(scaleTransition.scale.value, testEnd);
      });
    });

    group('Staggered List Animation', () {
      testWidgets('should create staggered animation for list items', (WidgetTester tester) async {
        final animationController = AnimationController(
          duration: MaterialMotion.medium3,
          vsync: tester,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  MaterialMotion.staggeredListAnimation(
                    animation: animationController,
                    index: 0,
                    child: const Text('Item 1'),
                  ),
                  MaterialMotion.staggeredListAnimation(
                    animation: animationController,
                    index: 1,
                    child: const Text('Item 2'),
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 2'), findsOneWidget);
        expect(find.byType(FadeTransition), findsNWidgets(2));
        expect(find.byType(SlideTransition), findsNWidgets(2));
      });
    });

    group('Pulse Animation', () {
      testWidgets('should create pulsing widget', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MaterialMotion.pulseAnimation(
                child: const Text('Pulsing Widget'),
              ),
            ),
          ),
        );

        expect(find.text('Pulsing Widget'), findsOneWidget);
        expect(find.byType(TweenAnimationBuilder<double>), findsOneWidget);
      });
    });
  });
}
