// ignore_for_file: prefer_const_constructors, use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kitchen/features/home/home_screen.dart';
import 'package:kitchen/services/database_service.dart';

class RegistrationForm extends StatefulWidget {
  const RegistrationForm({super.key});

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
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
        title: const Text('Registration Failed'),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
        ],
      ),
    );
  }

  Future<void> signUp() async {
    if (!_formKey.currentState!.validate()) return;

    _showLoading();
    try {
      final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );

      final user = result.user;
      if (user == null) {
        _hideLoading();
        _showError("User creation failed (null user).");
        return;
      }

      await user.updateDisplayName(_username.text.trim());

      final db = DatabaseService();
      await db.upsertUserProfile(
        username: _username.text.trim(),
        email: _email.text.trim(),
        imageUrl: "",
      );

      _hideLoading();
      _navigateToHome();
    } on FirebaseAuthException catch (e) {
      _hideLoading();
      _showError(e.message ?? 'Registration failed');
    } catch (e) {
      _hideLoading();
      _showError(e.toString());
    }
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
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  prefixIcon: Icon(Icons.person, color: Colors.deepPurple[400]),
                  hintText: 'Choose a Username',
                  labelText: 'Username',
                ),
                controller: _username,
                validator: (v) => (v == null || v.trim().length < 4)
                    ? 'Username must be at least 4 chars'
                    : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  prefixIcon: Icon(Icons.email, color: Colors.deepPurple[400]),
                  hintText: 'Enter Your Email',
                  labelText: 'Email',
                ),
                controller: _email,
                validator: (v) => (v == null || !v.contains("@"))
                    ? 'Please enter a valid email'
                    : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  prefixIcon: Icon(Icons.key, color: Colors.deepPurple[400]),
                  hintText: 'Create a Password',
                  labelText: 'Password',
                ),
                controller: _password,
                validator: (v) => (v == null || v.length < 6)
                    ? 'Password must be at least 6 chars'
                    : null,
              ),

              const SizedBox(height: 45),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                  minimumSize: const Size(250, 50),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.app_registration),
                label: const Text("Sign Up"),
                onPressed: signUp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
