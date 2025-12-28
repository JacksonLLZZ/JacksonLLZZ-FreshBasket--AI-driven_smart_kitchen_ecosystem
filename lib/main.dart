import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/constants/theme.dart';
import 'features/home/home_screen.dart';
import 'features/inventory/presentation/inventory_screen.dart';

import '../widgets/login/loginform_widget.dart';
import '../widgets/login/registrationform_widget.dart';
import '../features/profile/presentation/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    debugPrint("Firebase initialized successfully");
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }

  runApp(const NutriScanApp());
}

class NutriScanApp extends StatelessWidget {
  const NutriScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NutriScan',
      theme: AppTheme.lightTheme,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        //initialData: FirebaseAuth.instance.currentUser, // 关键
        builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // 已登录
          if (snapshot.hasData) {
            return const MainNavigation();
          }

          // 未登录
          return const AuthScreen();
        },
      ),

    );
  }
}

/// 主导航壳子：处理底部导航逻辑
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // 页面列表：将登录后的功能模块化
  final List<Widget> _pages = [
    const InventoryScreen(), // 默认展示冰箱库存
    const HomeScreen(),      // 这里的 HomeScreen 实际上是你的“添加食物”功能
    ProfileScreen(), // 预留的设置或食谱页
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.kitchen),
            label: "Fridge",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: "Add Food",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}

/// 授权页面容器：用于切换显示你的 LoginFormWidget 和 RegistrationFormWidget
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;

  void toggleView() {
    setState(() => isLogin = !isLogin);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isLogin ? "Welcome Back" : "Create Account"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.restaurant_menu, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 32),
            
            // 这里替换为你真实的 Widget
            isLogin 
               ? const LoginForm()
               : const RegistrationForm(),

            const SizedBox(height: 16),
            
            TextButton(
              onPressed: toggleView,
              child: Text(
                isLogin 
                  ? "Don't have an account? Register now" 
                  : "Already have an account? Login here",
                style: const TextStyle(color: Colors.blueAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}