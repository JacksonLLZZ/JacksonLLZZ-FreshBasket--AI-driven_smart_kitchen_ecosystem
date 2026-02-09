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

  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _forgotEmail.dispose();
    super.dispose();
  }

  void _setLoading(bool v) {
    if (!mounted) return;
    setState(() => _isLoading = v);
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  String? _validateEmail(String? v) {
    final s = (v ?? "").trim();
    if (s.isEmpty) return "Please enter your email";
    // Simple but sufficient verification
    final ok = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$").hasMatch(s);
    if (!ok) return "Please enter a valid email";
    return null;
  }

  String? _validatePwd(String? v) {
    final s = v ?? "";
    if (s.isEmpty) return "Please enter your password";
    if (s.length < 6) return "Password must be at least 6 chars";
    return null;
  }

  Future<void> signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    _setLoading(true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      // ❗Without navigation, hand over to main.dart——authStateChanges()
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Email login failed");
    } catch (e) {
      _showError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut(); // Reduce the problem of dirtiness

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return; // user canceled

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      // Firestore profile（Only fill in the blanks when they are missing.）
      final db = DatabaseService();
      final exists = await db.userDocExists();
      if (!exists) {
        final u = FirebaseAuth.instance.currentUser!;

        await db.upsertUserProfile(
          username: (u.displayName == null || u.displayName!.trim().isEmpty)
              ? "No Name"
              : u.displayName!.trim(),
          email: (u.email == null || u.email!.trim().isEmpty)
              ? "No Email"
              : u.email!.trim(),
        );
      }
      //
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Google login failed");
    } catch (e) {
      _showError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reset password"),
        content: Form(
          key: _forgotKey,
          child: TextFormField(
            controller: _forgotEmail,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: "Email",
              prefixIcon: Icon(Icons.email),
            ),
            validator: _validateEmail,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: _isLoading
                ? null
                : () async {
                    if (!_forgotKey.currentState!.validate()) return;
                    _setLoading(true);
                    try {
                      await FirebaseAuth.instance.sendPasswordResetEmail(
                        email: _forgotEmail.text.trim(),
                      );
                      if (!mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Reset email sent.")),
                      );
                    } catch (e) {
                      _showError(e.toString());
                    } finally {
                      _setLoading(false);
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
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        // background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.primary.withOpacity(0.14),
                cs.secondary.withOpacity(0.10),
                cs.surface,
              ],
            ),
          ),
        ),

        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          width: 64,
                          height: 64,
                          fit: BoxFit.contain,
                        ),

                        const SizedBox(height: 12),

                        Text(
                          "Welcome to FreshBasket",
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 18),

                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [
                            AutofillHints.username,
                            AutofillHints.email,
                          ],
                          decoration: InputDecoration(
                            labelText: "Email",
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: const Icon(Icons.lock),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                            ),
                          ),
                          validator: _validatePwd,
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _isLoading
                                ? null
                                : _showForgotPasswordDialog,
                            child: const Text("Forgot password?"),
                          ),
                        ),

                        const SizedBox(height: 6),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton.icon(
                            icon: const Icon(Icons.login),
                            label: const Text("Sign in"),
                            onPressed: _isLoading ? null : signInWithEmail,
                          ),
                        ),
                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            icon: const FaIcon(FontAwesomeIcons.google),
                            label: const Text("Continue with Google"),
                            onPressed: _isLoading ? null : signInWithGoogle,
                          ),
                        ),

                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.18),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
