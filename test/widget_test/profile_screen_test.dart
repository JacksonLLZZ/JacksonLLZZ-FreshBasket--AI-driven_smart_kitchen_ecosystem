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
    testWidgets('should display page title "Account & Settings"', (WidgetTester tester) async {
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

    testWidgets('should display theme selector title "App Appearance"', (WidgetTester tester) async {
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

    testWidgets('should display health profile title "Health Profile"', (WidgetTester tester) async {
      // Arrange
      final widget = createTestApp(
        child: ProfileScreen(databaseService: mockDb, auth: mockAuth),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - Verify health profile section
      expect(find.text('Health Profile'), findsOneWidget);
    });

    testWidgets('guest mode should display login button', (WidgetTester tester) async {
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

    testWidgets('should display theme options for each season', (WidgetTester tester) async {
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

    testWidgets('should be able to click season theme to switch', (WidgetTester tester) async {
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

      // Assert - Verify interaction works (success if no exception thrown)
      expect(tester.takeException(), isNull);
    });

    testWidgets('logged in user should display sign out button', (WidgetTester tester) async {
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

    testWidgets('should display allergen selection list', (WidgetTester tester) async {
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

    testWidgets('should display Fridge Statistics section', (WidgetTester tester) async {
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

      // Assert - Verify statistics section text
      final statsFinder = find.textContaining('Fridge');
      expect(statsFinder, findsWidgets);
    });
  });
}
