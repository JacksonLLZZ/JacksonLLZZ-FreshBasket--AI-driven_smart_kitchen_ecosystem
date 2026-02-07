import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kitchen/features/recipes/presentation/recipe_info_screen.dart';
import 'package:kitchen/features/recipes/data/recipe.dart';
import 'package:kitchen/services/database_service.dart';
import 'package:kitchen/core/constants/test_keys.dart';
import '../test_helpers.dart';
import '../mock_dependencies.dart';

void main() {
  late MockDatabaseService mockDb;
  late Recipe testRecipe;

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    mockDb = MockDatabaseService();
    
    // 创建测试用的食谱数据
    testRecipe = Recipe(
      id: 1,
      title: 'Test Pasta Dish',
      image: 'https://example.com/pasta.jpg',
      usedIngredientCount: 3,
      missedIngredientCount: 2,
      usedIngredients: [],
      missedIngredients: [],
      area: 'Italian',
      category: 'Main Course',
    );

    // Mock database stream to return empty cart
    when(() => mockDb.getShoppingCartStream()).thenAnswer(
      (_) => Stream.value([]),
    );
  });

  group('RecipeInfoScreen Widget Tests -', () {
    testWidgets('应该显示食谱标题', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: RecipeInfoScreen(recipe: testRecipe),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - 验证标题
      expect(find.text('Test Pasta Dish'), findsOneWidget);
      expect(
        find.byKey(const Key(TestKeys.recipeInfoScreenScaffold)),
        findsOneWidget,
      );
    });

    testWidgets('应该显示食材统计信息（Have和Need）', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: RecipeInfoScreen(recipe: testRecipe),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - 验证统计信息
      expect(find.text('Have'), findsOneWidget);
      expect(find.text('Need'), findsOneWidget);
      expect(find.text('3'), findsOneWidget); // usedIngredientCount
      expect(find.text('2'), findsOneWidget); // missedIngredientCount
    });

    testWidgets('应该显示地区和类别标签', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: RecipeInfoScreen(recipe: testRecipe),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - 验证标签
      expect(find.text('Italian'), findsOneWidget);
      expect(find.text('Main Course'), findsOneWidget);
    });

    testWidgets('应该显示SliverAppBar', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: RecipeInfoScreen(recipe: testRecipe),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - 验证SliverAppBar存在
      expect(find.byType(SliverAppBar), findsOneWidget);
    });

    testWidgets('应该显示统计卡片包含图标', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: RecipeInfoScreen(recipe: testRecipe),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - 验证统计图标
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.shopping_cart), findsOneWidget);
    });

    testWidgets('应该能够滚动页面查看更多内容', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: RecipeInfoScreen(recipe: testRecipe),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // 尝试滚动
      final scrollView = find.byType(CustomScrollView);
      await tester.drag(scrollView, const Offset(0, -200));
      await tester.pumpAndSettle();

      // Assert - 验证无异常
      expect(tester.takeException(), isNull);
    });

    testWidgets('应该显示公共图标（area标签）', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: RecipeInfoScreen(recipe: testRecipe),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - 验证公共图标存在
      expect(find.byIcon(Icons.public), findsWidgets);
    });

    testWidgets('没有地区信息时不应该显示地区标签', (WidgetTester tester) async {
      // Arrange - 创建没有area的食谱
      final recipeWithoutArea = Recipe(
        id: 2,
        title: 'Simple Recipe',
        image: 'https://example.com/simple.jpg',
        usedIngredientCount: 1,
        missedIngredientCount: 0,
        usedIngredients: [],
        missedIngredients: [],
        area: null,
        category: null,
      );

      final widget = createTestApp(
        child: RecipeInfoScreen(recipe: recipeWithoutArea),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - 验证area标签不存在
      expect(find.byIcon(Icons.public), findsNothing);
    });

    testWidgets('应该显示Card容器', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: RecipeInfoScreen(recipe: testRecipe),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - 验证Card存在
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('应该正确处理食谱图片加载', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: RecipeInfoScreen(recipe: testRecipe),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pump(); // 不使用pumpAndSettle，因为图片可能还在加载

      // Assert - 验证图片widget存在（即使还在加载）
      expect(find.byType(FlexibleSpaceBar), findsOneWidget);
    });
  });
}
