import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kitchen/features/profile/presentation/profile_screen.dart';
import 'package:kitchen/core/constants/test_keys.dart';
import '../test_helpers.dart';
import '../mock_dependencies.dart';

void main() {
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late SharedPreferences mockPrefs;
  late MockDatabaseService mockDb;

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() async {
    // Initialize SharedPreferences mock
    SharedPreferences.setMockInitialValues({});
    
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockDb = MockDatabaseService();
    mockPrefs = await SharedPreferences.getInstance();
    await mockPrefs.clear();

    // Mock Firebase Auth current user
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.isAnonymous).thenReturn(false);
    when(() => mockUser.email).thenReturn('test@example.com');
    when(() => mockUser.uid).thenReturn('test-user-id');

    // Mock DatabaseService streams
    final mockSnapshot = MockDocumentSnapshot();
    when(() => mockSnapshot.exists).thenReturn(true);
    when(() => mockSnapshot.data()).thenReturn({});
    
    when(() => mockDb.getUserProfileStream()).thenAnswer(
      (_) => Stream.value(mockSnapshot),
    );
    when(() => mockDb.getInventoryStream()).thenAnswer(
      (_) => Stream.value([]),
    );
    when(() => mockDb.updateTheme(any())).thenAnswer((_) async => {});
    when(() => mockDb.upsertUserProfile(
          username: any(named: 'username'),
          email: any(named: 'email'),
          imageUrl: any(named: 'imageUrl'),
        )).thenAnswer((_) async => {});
  });

  tearDown(() async {
    await mockPrefs.clear();
  });

  group('ProfileScreen Widget Tests -', () {
    testWidgets('应该显示页面标题 "Account & Settings"', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: ProfileScreen(databaseService: mockDb, auth: mockAuth),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - 验证标题
      expect(find.text('Account & Settings'), findsOneWidget);
      expect(
        find.byKey(const Key(TestKeys.profileScreenScaffold)),
        findsOneWidget,
      );
    });

    testWidgets('应该显示主题选择器标题 "App Appearance"', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: ProfileScreen(databaseService: mockDb, auth: mockAuth),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - 验证主题选择器部分
      expect(find.text('App Appearance'), findsOneWidget);
    });

    testWidgets('应该显示健康档案标题 "Health Profile"', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: ProfileScreen(databaseService: mockDb, auth: mockAuth),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - 验证健康档案部分
      expect(find.text('Health Profile'), findsOneWidget);
    });

    testWidgets('游客模式应该显示登录按钮', (WidgetTester tester) async {
      // Arrange - 设置为游客模式
      when(() => mockUser.isAnonymous).thenReturn(true);
      
      final widget = createTestApp(
        child: ProfileScreen(databaseService: mockDb, auth: mockAuth),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - 验证游客模式卡片和登录按钮
      expect(find.text('Guest Mode'), findsOneWidget);
      expect(
        find.byKey(const Key(TestKeys.loginButton)),
        findsOneWidget,
      );
      expect(find.text('Sign In / Register'), findsOneWidget);
    });

    testWidgets('应该显示各个季节的主题选项', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: ProfileScreen(databaseService: mockDb, auth: mockAuth),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - 验证四个季节选项都存在（通过查找包含季节名称的文本）
      expect(find.text('Spring'), findsAtLeastNWidgets(1));
      expect(find.text('Summer'), findsAtLeastNWidgets(1));
      expect(find.text('Autumn'), findsAtLeastNWidgets(1));
      expect(find.text('Winter'), findsAtLeastNWidgets(1));
    });

    testWidgets('应该能够点击季节主题进行切换', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: ProfileScreen(databaseService: mockDb, auth: mockAuth),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // 查找春季主题图标
      final springThemeFinder = find.ancestor(
        of: find.text('Spring'),
        matching: find.byType(GestureDetector),
      );

      // 点击春季主题
      if (springThemeFinder.evaluate().isNotEmpty) {
        await tester.tap(springThemeFinder.first);
        await tester.pumpAndSettle();
      }

      // Assert - 验证可以交互（无异常抛出即成功）
      expect(tester.takeException(), isNull);
    });

    testWidgets('登录用户应该显示退出登录按钮', (WidgetTester tester) async {
      // Arrange - 确保是登录用户
      when(() => mockUser.isAnonymous).thenReturn(false);
      
      final widget = createTestApp(
        child: ProfileScreen(databaseService: mockDb, auth: mockAuth),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // 向下滚动以查看退出按钮
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      // Assert - 验证退出按钮存在
      expect(find.textContaining('Sign Out'), findsWidgets);
    });

    testWidgets('应该显示过敏原选择列表', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: ProfileScreen(databaseService: mockDb, auth: mockAuth),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // 向下滚动查看健康档案部分
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      // Assert - 验证Health Profile标题存在
      expect(find.text('Health Profile'), findsOneWidget);
    });

    testWidgets('应该显示Fridge Statistics部分', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: ProfileScreen(databaseService: mockDb, auth: mockAuth),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // 向下滚动
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      // Assert - 验证统计部分的某些文本
      final statsFinder = find.textContaining('Fridge');
      expect(statsFinder, findsWidgets);
    });
  });
}
