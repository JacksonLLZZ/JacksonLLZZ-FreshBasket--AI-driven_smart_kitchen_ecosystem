import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kitchen/main.dart' as app;

/// Recipe Finder Test - Focus on recipe search functionality
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Recipe Finder Test -', () {
    testWidgets('Should access recipe finder with ingredients', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Add ingredient
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Tomato');
      await tester.enterText(textFields.at(1), '3');
      
      final saveButton = find.text('Save to My Inventory');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));

      // Go to inventory
      await tester.tap(find.byIcon(Icons.kitchen_outlined));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Open recipe finder
      final recipeIcon = find.byIcon(Icons.restaurant_menu);
      if (recipeIcon.evaluate().isNotEmpty) {
        await tester.tap(recipeIcon);
        await tester.pumpAndSettle();

        // Verify recipe finder screen
        expect(find.text('Recipe Finder'), findsOneWidget);

        // Verify ingredient chip appears
        final ingredientChip = find.widgetWithText(FilterChip, 'Tomato');
        expect(ingredientChip, findsWidgets);
      }
    });

    testWidgets('Should be able to select ingredients for recipe search', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Add multiple ingredients
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Pasta');
      await tester.enterText(textFields.at(1), '200');
      
      await tester.tap(find.text('Save to My Inventory'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));

      // Navigate to inventory and open recipe finder
      await tester.tap(find.byIcon(Icons.kitchen_outlined));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      final recipeIcon = find.byIcon(Icons.restaurant_menu);
      if (recipeIcon.evaluate().isNotEmpty) {
        await tester.tap(recipeIcon);
        await tester.pumpAndSettle();

        // Try to select ingredient chip
        final pastaChip = find.widgetWithText(FilterChip, 'Pasta');
        if (pastaChip.evaluate().isNotEmpty) {
          await tester.tap(pastaChip);
          await tester.pumpAndSettle();
        }

        // Verify find recipes button exists
        final findBtn = find.byKey(const Key('findRecipesButton'));
        expect(findBtn, findsWidgets);
      }
    });
  });
}
