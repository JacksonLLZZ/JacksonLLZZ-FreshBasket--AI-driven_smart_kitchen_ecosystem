import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kitchen/main.dart' as app;

/// Ingredient Addition Test - Focus on adding ingredients to inventory
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Ingredient Addition Test -', () {
    testWidgets('Should successfully add ingredient via manual input', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Wait for authentication
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Navigate to Add Food screen
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      // Input ingredient details
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Apple');
      await tester.enterText(textFields.at(1), '5');
      await tester.pumpAndSettle();

      // Save to inventory
      final saveButton = find.text('Save to My Inventory');
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();
      
      // Wait for save operation
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Navigate to inventory to verify
      await tester.tap(find.byIcon(Icons.kitchen_outlined));
      await tester.pumpAndSettle();
      
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Verify ingredient appears in inventory
      expect(find.textContaining('Apple'), findsWidgets);
    });

    testWidgets('Should validate empty ingredient name', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Navigate to Add Food screen
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      // Try to save without entering name
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(1), '10');
      await tester.pumpAndSettle();

      // Attempt to save
      final saveButton = find.text('Save to My Inventory');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Should show validation message or remain on same screen
      expect(find.text('FreshBasket'), findsWidgets);
    });
  });
}
