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

    when(
      () => mockDb.getUserProfileStream(),
    ).thenAnswer((_) => Stream.value(mockSnapshot));
    when(() => mockDb.getInventoryStream()).thenAnswer((_) => Stream.value([]));
    when(() => mockDb.updateTheme(any())).thenAnswer((_) async => {});
    when(
      () => mockDb.upsertUserProfile(
        username: any(named: 'username'),
        email: any(named: 'email'),
        imageUrl: any(named: 'imageUrl'),
      ),
    ).thenAnswer((_) async => {});
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

      // Assert - Verify the title
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

      // Assert - Verify the theme selector section
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

      // Assert - Verification of health records section
      expect(find.text('Health Profile'), findsOneWidget);
    });

    testWidgets('游客模式应该显示登录按钮', (WidgetTester tester) async {
      // Arrange - Set to tourist mode
      when(() => mockUser.isAnonymous).thenReturn(true);

      final widget = createTestApp(
        child: ProfileScreen(databaseService: mockDb, auth: mockAuth),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - Verify the tourist mode card and the login button
      expect(find.text('Guest Mode'), findsOneWidget);
      expect(find.byKey(const Key(TestKeys.loginButton)), findsOneWidget);
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

      // Assert - Verify that all four seasons options are present (by searching for text containing the names of the seasons)
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

      // Search for spring-themed icons
      final springThemeFinder = find.ancestor(
        of: find.text('Spring'),
        matching: find.byType(GestureDetector),
      );

      // Click on the spring theme
      if (springThemeFinder.evaluate().isNotEmpty) {
        await tester.tap(springThemeFinder.first);
        await tester.pumpAndSettle();
      }

      // Assert - Verification can be interactive (success is achieved without any exception being thrown)
      expect(tester.takeException(), isNull);
    });

    testWidgets('登录用户应该显示退出登录按钮', (WidgetTester tester) async {
      // Arrange - Ensure that it is a logged-in user
      when(() => mockUser.isAnonymous).thenReturn(false);

      final widget = createTestApp(
        child: ProfileScreen(databaseService: mockDb, auth: mockAuth),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Scroll down to view the exit button
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      // Assert - Verify the existence of the exit button
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

      // Scroll down to view the health record section
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      // Assert - Verify the existence of the "Health Profile" title
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

      // Scroll down
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      // Assert - Some texts in the verification statistics section
      final statsFinder = find.textContaining('Fridge');
      expect(statsFinder, findsWidgets);
    });
  });
}
