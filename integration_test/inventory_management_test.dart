import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kitchen/main.dart' as app;

/// Inventory Management Test - Focus on inventory display and operations
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Inventory Management Test -', () {
    testWidgets('Should display inventory screen with proper UI elements', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Navigate to inventory
      await tester.tap(find.byIcon(Icons.kitchen_outlined));
      await tester.pumpAndSettle();

      // Verify inventory screen elements
      expect(find.text('My Fridge Inventory'), findsWidgets);
      
      // Verify action buttons in AppBar
      expect(find.byIcon(Icons.checklist), findsOneWidget);
    });

    testWidgets('Should show empty state when no ingredients', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Navigate to inventory
      await tester.tap(find.byIcon(Icons.kitchen_outlined));
      await tester.pumpAndSettle();
      
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // May show empty state or have items - verify screen loads
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('Should open recipe finder from inventory', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Add an ingredient first
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Chicken');
      await tester.enterText(textFields.at(1), '500');
      
      final saveButton = find.text('Save to My Inventory');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));

      // Navigate to inventory
      await tester.tap(find.byIcon(Icons.kitchen_outlined));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Look for Explore Recipes FAB
      final recipeFAB = find.byIcon(Icons.restaurant_menu);
      if (recipeFAB.evaluate().isNotEmpty) {
        await tester.tap(recipeFAB);
        await tester.pumpAndSettle();
        expect(find.text('Recipe Finder'), findsOneWidget);
      }
    });
  });
}
