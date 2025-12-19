// ignore_for_file: prefer_const_constructors, use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kitchen/services/database_service.dart';


class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  final _forgotKey = GlobalKey<FormState>();
  final _forgotEmail = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _forgotEmail.dispose();
    super.dispose();
  }



  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _hideLoading() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
        ],
      ),
    );
  }

    Future<void> signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    _showLoading();
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      _hideLoading();
      // ❗ 不导航，交给 authStateChanges
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _hideLoading();
      _showError(e.message ?? 'Email login failed');
    } catch (e) {
      if (!mounted) return;
      _hideLoading();
      _showError(e.toString());
    }
  } 


  Future<void> signInWithGoogle() async {
    _showLoading();
    try {
      // 1️⃣ 确保干净状态（模拟器/真机都更稳）
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      // 2️⃣ 弹出 Google 选择账号
      final GoogleSignInAccount? googleUser =
          await googleSignIn.signIn();

      // 用户取消
      if (googleUser == null) {
        if (!mounted) return;
        _hideLoading();
        return;
      }

      // 3️⃣ 获取 Google token
      final googleAuth = await googleUser.authentication;

      // 4️⃣ 转成 Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 5️⃣ Firebase 登录
      await FirebaseAuth.instance.signInWithCredential(credential);

      // 6️⃣ Firestore profile（只在缺失时）
      final db = DatabaseService();
      final exists = await db.userDocExists();
      if (!exists) {
        final u = FirebaseAuth.instance.currentUser!;
        await db.upsertUserProfile(
          username: u.displayName ?? 'No Name',
          email: u.email ?? 'No Email',
          imageUrl: u.photoURL ?? '',
        );
      }

      // 7️⃣ 关闭 loading（不导航）
      if (!mounted) return;
      _hideLoading();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _hideLoading();
      _showError(e.message ?? 'Google login failed');
    } catch (e) {
      if (!mounted) return;
      _hideLoading();
      _showError(e.toString());
    }
  }


  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Forgot Password"),
        content: Form(
          key: _forgotKey,
          child: TextFormField(
            controller: _forgotEmail,
            decoration: const InputDecoration(
              labelText: "Email",
              icon: Icon(Icons.email),
            ),
            validator: (v) => (v == null || !v.contains("@")) ? "Enter a valid email" : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (!_forgotKey.currentState!.validate()) return;
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(
                  email: _forgotEmail.text.trim(),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Reset email sent!")),
                );
              } catch (e) {
                _showError(e.toString());
              }
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  prefixIcon: Icon(Icons.email, color: Colors.deepPurple[400]),
                  hintText: 'Enter Your Email',
                  labelText: 'Email',
                ),
                controller: _email,
                validator: (v) => (v == null || v.isEmpty) ? "Please enter your email" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  prefixIcon: Icon(Icons.key, color: Colors.deepPurple[400]),
                  hintText: 'Do not share it!',
                  labelText: 'Password',
                ),
                controller: _password,
                validator: (v) => (v == null || v.isEmpty) ? "Please enter your password" : null,
              ),
              const SizedBox(height: 45),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                  minimumSize: const Size(250, 50),
                ),
                icon: const Icon(Icons.login),
                label: const Text("Sign In"),
                onPressed: signInWithEmail,
              ),

              const SizedBox(height: 15),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                  minimumSize: const Size(250, 50),
                  foregroundColor: Colors.red[600],
                ),
                icon: const FaIcon(FontAwesomeIcons.google),
                label: const Text("Sign In with Google"),
                onPressed: signInWithGoogle,
              ),

              TextButton(
                onPressed: _showForgotPasswordDialog,
                child: const Text("Forgot Password?"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
