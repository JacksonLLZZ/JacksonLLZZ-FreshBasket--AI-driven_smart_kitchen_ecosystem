import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/constants/theme.dart';
import 'services/database_service.dart';
import 'features/home/home_screen.dart';
import 'features/inventory/presentation/inventory_screen.dart';
import 'features/shopping_cart/presentation/shopping_cart_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/assistant/presentation/assistant_screen.dart';
import 'firebase_options.dart';
import 'widgets/login/loginform_widget.dart';
import 'widgets/login/registrationform_widget.dart';
import 'core/notifications/notification_service.dart';
import 'core/notifications/expiry_reminder_service.dart';

/// Global state to control the authentication flow
/// true: App will automatically log in as Guest (shows AutoLoginSplash)
/// false: App will stay on the manual login/register screen (shows AuthPage)
final ValueNotifier<bool> allowAnonymousLogin = ValueNotifier<bool>(true);

/// Global state for current theme selection
final ValueNotifier<String> currentTheme = ValueNotifier<String>('Default');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }
  try {
    await NotificationService.instance.init();
    await NotificationService.instance.requestPermissions();
  } catch (e) {
    debugPrint("Notification initialization failed: $e");
  }
  runApp(const FreshBasketApp());
}

class FreshBasketApp extends StatefulWidget {
  const FreshBasketApp({super.key});

  @override
  State<FreshBasketApp> createState() => _FreshBasketAppState();
}

class _FreshBasketAppState extends State<FreshBasketApp> {
  String _currentTheme = 'Default';
  final DatabaseService _db = DatabaseService();
  StreamSubscription? _themeSubscription;

  @override
  void initState() {
    super.initState();
    _initAuthListener();
  }

  void _initAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _themeSubscription?.cancel();
      if (user != null) {
        _themeSubscription = _db.getUserProfileStream().listen((snapshot) {
          if (snapshot.exists) {
            final data = snapshot.data() as Map<String, dynamic>?;
            final themeName = data?['theme'] ?? 'Default';
            if (mounted && _currentTheme != themeName) {
              setState(() => _currentTheme = themeName);
              currentTheme.value = themeName; // 更新全局状态
            }
          }
        });
        ExpiryReminderService.instance.startForUser(user.uid);
      } else {
        ExpiryReminderService.instance.stop();
        if (mounted) {
          setState(() => _currentTheme = 'Default');
          currentTheme.value = 'Default'; // 更新全局状态
        }
      }
    });
  }

  @override
  void dispose() {
    _themeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FreshBasket',
      theme: AppTheme.getTheme(_currentTheme),
      home: const AuthWrapper(),
    );
  }
}

/// AuthWrapper: The "Traffic Controller" of the app
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: allowAnonymousLogin,
      builder: (context, allowAnonymous, _) {
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final user = snapshot.data;

            // 1. If user is logged in (Guest OR Registered) -> Go to App
            if (user != null) {
              return const MainNavigation();
            }

            // 2. If NO user & Auto-Guest is enabled -> Show Guest Interface (AutoLoginSplash)
            if (allowAnonymous) {
              return const AutoLoginSplash();
            }

            // 3. If NO user & Auto-Guest is disabled -> Show Manual Login Interface (AuthPage)
            return const AuthPage();
          },
        );
      },
    );
  }
}

/// GUEST INTERFACE (AutoLoginSplash)
/// This is what users see when they first open the app or when they log out to Guest mode.
class AutoLoginSplash extends StatefulWidget {
  const AutoLoginSplash({super.key});
  @override
  State<AutoLoginSplash> createState() => _AutoLoginSplashState();
}

class _AutoLoginSplashState extends State<AutoLoginSplash> {
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _handleLogin();
  }

  Future<void> _handleLogin() async {
    try {
      if (mounted) setState(() => _errorMessage = null);
      // Wait a moment for visual effect
      await Future.delayed(const Duration(milliseconds: 1500));
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().contains('admin-restricted-operation')
              ? "Guest mode is disabled. Please sign in manually."
              : "Connection error. Please check your internet.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              Image.asset(
              'assets/images/logo.png',
              width: 80,
              height: 80,             
              ),

            const SizedBox(height: 24),
            const Text(
              "FreshBasket",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? "Preparing your smart kitchen...",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 48),
            if (_errorMessage == null)
              const CircularProgressIndicator(strokeWidth: 2.5)
            else
              ElevatedButton(
                onPressed: () {
                  // If guest fails, let user go to manual login
                  allowAnonymousLogin.value = false;
                },
                child: const Text("Sign In Manually"),
              ),
          ],
        ),
      ),
    );
  }
}

/// MANUAL LOGIN INTERFACE (AuthPage)
/// This is what users see when they click "Sign In / Register" in Profile.
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool showLogin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              allowAnonymousLogin.value = true, // Go back to Guest mode splash
        ),
        title: Text(showLogin ? "Sign In" : "Register"),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const SizedBox.shrink(),
            const SizedBox(height: 20),

            // Your uploaded widgets
            showLogin ? const LoginForm() : const RegistrationForm(),

            TextButton(
              onPressed: () => setState(() => showLogin = !showLogin),
              child: Text(
                showLogin
                    ? "Create an account"
                    : "Already have an account? Sign In",
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const InventoryScreen(),
    const AssistantScreen(),
    const HomeScreen(),
    const ShoppingCartScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // 响应式布局：根据屏幕宽度决定使用 NavigationRail 或 BottomNavigationBar
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      body: Row(
        children: [
          // 平板模式：显示侧边导航栏 (NavigationRail)
          if (isTablet)
            NavigationRail(
              selectedIndex: _currentIndex < 4 ? _currentIndex : 0,
              onDestinationSelected: (i) => setState(() => _currentIndex = i),
              labelType: NavigationRailLabelType.selected,
              selectedIconTheme: IconThemeData(
                color: Theme.of(context).primaryColor,
              ),
              selectedLabelTextStyle: TextStyle(
                color: Theme.of(context).primaryColor,
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.kitchen_outlined),
                  label: Text("Fridge"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.smart_toy_outlined),
                  label: Text("AI Assistant"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.add_circle_outline),
                  label: Text("Add Food"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.shopping_cart_outlined),
                  label: Text("Cart"),
                ),
              ],
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: IconButton(
                      icon: Icon(
                        Icons.person_outline,
                        color: _currentIndex == 4
                            ? Theme.of(context).primaryColor
                            : Colors.grey[600],
                      ),
                      onPressed: () => setState(() => _currentIndex = 4),
                      tooltip: 'Profile',
                    ),
                  ),
                ),
              ),
            ),

          // 分隔线
          if (isTablet) const VerticalDivider(thickness: 1, width: 1),

          // 主内容区域
          Expanded(
            child: IndexedStack(index: _currentIndex, children: _pages),
          ),
        ],
      ),
      // 手机模式：显示底部导航栏 (BottomNavigationBar)
      bottomNavigationBar: isTablet
          ? null
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              selectedItemColor: Theme.of(context).primaryColor,
              unselectedItemColor: Colors.grey[400],
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.kitchen_outlined),
                  label: "Fridge",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.smart_toy_outlined),
                  label: "AI Assistant",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.add_circle_outline),
                  label: "Add Food",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_cart_outlined),
                  label: "Cart",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  label: "Profile",
                ),
              ],
            ),
    );
  }
}
