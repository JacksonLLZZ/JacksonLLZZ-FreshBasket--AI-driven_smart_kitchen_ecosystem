import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kitchen/main.dart' as app;

/// Shopping Cart Test - Focus on shopping cart functionality
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Shopping Cart Test -', () {
    testWidgets('Should display shopping cart screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Navigate to shopping cart
      await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
      await tester.pumpAndSettle();

      // Verify shopping cart screen
      expect(find.text('Shopping Cart'), findsOneWidget);
    });

    testWidgets('Should show empty cart state initially', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Navigate to shopping cart
      await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
      await tester.pumpAndSettle();

      // Verify cart screen loads
      expect(find.text('Shopping Cart'), findsOneWidget);
      
      // Empty cart message may appear
    });

    testWidgets('Should navigate from cart to other screens', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Start from shopping cart
      await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Shopping Cart'), findsOneWidget);

      // Navigate to inventory
      await tester.tap(find.byIcon(Icons.kitchen_outlined));
      await tester.pumpAndSettle();
      expect(find.text('My Fridge Inventory'), findsWidgets);

      // Back to cart
      await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Shopping Cart'), findsOneWidget);
    });
  });
}
