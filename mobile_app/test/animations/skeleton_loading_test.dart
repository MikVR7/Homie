import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homie_app/animations/skeleton_loading.dart';

void main() {
  group('SkeletonLoading', () {
    testWidgets('should show skeleton when isLoading is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoading(
              isLoading: true,
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonLoading), findsOneWidget);
      expect(find.byType(AnimatedBuilder), findsWidgets);
    });

    testWidgets('should show content when isLoading is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoading(
              isLoading: false,
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.text('Content'), findsOneWidget);
      expect(find.byType(FadeTransition), findsOneWidget);
    });

    testWidgets('should update when isLoading state changes', (WidgetTester tester) async {
      bool isLoading = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => SkeletonLoading(
                isLoading: isLoading,
                child: const Text('Content'),
              ),
            ),
          ),
        ),
      );

      // Initially loading
      expect(find.byType(AnimatedBuilder), findsWidgets);

      // Change to loaded state
      isLoading = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => SkeletonLoading(
                isLoading: isLoading,
                child: const Text('Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Content'), findsOneWidget);
    });

    group('Direction', () {
      testWidgets('should support left-to-right direction', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SkeletonLoading(
                isLoading: true,
                direction: SkeletonDirection.ltr,
                child: Text('Content'),
              ),
            ),
          ),
        );

        expect(find.byType(SkeletonLoading), findsOneWidget);
      });

      testWidgets('should support right-to-left direction', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SkeletonLoading(
                isLoading: true,
                direction: SkeletonDirection.rtl,
                child: Text('Content'),
              ),
            ),
          ),
        );

        expect(find.byType(SkeletonLoading), findsOneWidget);
      });

      testWidgets('should support top-to-bottom direction', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SkeletonLoading(
                isLoading: true,
                direction: SkeletonDirection.ttb,
                child: Text('Content'),
              ),
            ),
          ),
        );

        expect(find.byType(SkeletonLoading), findsOneWidget);
      });
    });
  });

  group('SkeletonWidgets', () {
    group('Text Skeleton', () {
      testWidgets('should create text skeleton when loading', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SkeletonWidgets.text(
                isLoading: true,
                height: 20,
                width: 100,
              ),
            ),
          ),
        );

        expect(find.byType(SkeletonLoading), findsOneWidget);
        expect(find.byType(Container), findsOneWidget);
      });

      testWidgets('should show actual content when not loading', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SkeletonWidgets.text(
                isLoading: false,
                height: 20,
                width: 100,
              ),
            ),
          ),
        );

        expect(find.byType(Container), findsOneWidget);
      });
    });

    group('Avatar Skeleton', () {
      testWidgets('should create avatar skeleton', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SkeletonWidgets.avatar(
                isLoading: true,
                radius: 30,
              ),
            ),
          ),
        );

        expect(find.byType(SkeletonLoading), findsOneWidget);
        expect(find.byType(CircleAvatar), findsOneWidget);
      });
    });

    group('Image Skeleton', () {
      testWidgets('should create image skeleton', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SkeletonWidgets.image(
                isLoading: true,
                width: 100,
                height: 100,
              ),
            ),
          ),
        );

        expect(find.byType(SkeletonLoading), findsOneWidget);
        expect(find.byType(Container), findsOneWidget);
      });
    });

    group('Card Skeleton', () {
      testWidgets('should create card skeleton', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SkeletonWidgets.card(
                isLoading: true,
                height: 200,
              ),
            ),
          ),
        );

        expect(find.byType(SkeletonLoading), findsOneWidget);
        expect(find.byType(Card), findsOneWidget);
        expect(find.byType(Container), findsNWidgets(4)); // Multiple skeleton elements
      });
    });

    group('List Item Skeleton', () {
      testWidgets('should create list item skeleton with avatar', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SkeletonWidgets.listItem(
                isLoading: true,
                hasAvatar: true,
                hasSubtitle: true,
              ),
            ),
          ),
        );

        expect(find.byType(SkeletonLoading), findsOneWidget);
        expect(find.byType(CircleAvatar), findsOneWidget);
        expect(find.byType(Container), findsNWidgets(3)); // Avatar + Title and subtitle
      });

      testWidgets('should create list item skeleton without avatar', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SkeletonWidgets.listItem(
                isLoading: true,
                hasAvatar: false,
                hasSubtitle: false,
              ),
            ),
          ),
        );

        expect(find.byType(SkeletonLoading), findsOneWidget);
        expect(find.byType(CircleAvatar), findsNothing);
        expect(find.byType(Container), findsOneWidget); // Only title
      });
    });

    group('File Browser Item Skeleton', () {
      testWidgets('should create file browser item skeleton', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SkeletonWidgets.fileBrowserItem(
                isLoading: true,
              ),
            ),
          ),
        );

        expect(find.byType(SkeletonLoading), findsOneWidget);
        expect(find.byType(Container), findsNWidgets(4)); // Icon, title, subtitle, action
      });
    });

    group('Organization Preview Skeleton', () {
      testWidgets('should create organization preview skeleton', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SkeletonWidgets.organizationPreview(
                isLoading: true,
                itemCount: 3,
              ),
            ),
          ),
        );

        expect(find.byType(SkeletonLoading), findsOneWidget);
        expect(find.byType(Card), findsOneWidget);
        expect(find.byType(Container), findsNWidgets(7)); // Header + 3 items (each with bullet + text)
      });
    });
  });

  group('Performance', () {
    testWidgets('should handle rapid state changes without errors', (WidgetTester tester) async {
      bool isLoading = true;
      late StateSetter setState;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setter) {
                setState = setter;
                return SkeletonLoading(
                  isLoading: isLoading,
                  child: const Text('Content'),
                );
              },
            ),
          ),
        ),
      );

      // Rapidly toggle loading state
      for (int i = 0; i < 10; i++) {
        setState(() {
          isLoading = !isLoading;
        });
        await tester.pump();
      }

      // Should not throw any errors
      expect(find.byType(SkeletonLoading), findsOneWidget);
    });

    testWidgets('should dispose animation controller properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoading(
              isLoading: true,
              child: Text('Content'),
            ),
          ),
        ),
      );

      // Verify widget is built
      expect(find.byType(SkeletonLoading), findsOneWidget);

      // Remove widget and pump to trigger dispose
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
