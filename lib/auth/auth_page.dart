import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:test_task_beomy_tech/home/home_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showEmailForm = false;

  // Method for handling the result of authorization
  void _handleAuthResult(User? user, String provider) {
    if (user != null) {
      print('Увійшов через $provider: ${user.email}');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  // Registration with email + password
  Future<void> _register() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: _emailController.text, password: _passwordController.text);
      _handleAuthResult(userCredential.user, 'Email/Password');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('Занадто слабкий пароль.');
      } else if (e.code == 'email-already-in-use') {
        print('Акаунт з таким email вже існує.');
      }
    } catch (e) {
      print(e);
    }
  }

  // Login with email + password
  Future<void> _signIn() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: _emailController.text, password: _passwordController.text);
      _handleAuthResult(userCredential.user, 'Email/Password');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('Користувача з таким email не знайдено.');
      } else if (e.code == 'wrong-password') {
        print('Невірний пароль.');
      }
    }
  }

  // Method for Google Sign-In

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw Exception('Вхід скасовано користувачем');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      _handleAuthResult(userCredential.user, 'Google');
    } catch (e) {
      print('Помилка входу через Google: $e');
    }
  }

  // Method for Facebook Sign-In

  Future<UserCredential> signInWithFacebook() async {
    final LoginResult result = await FacebookAuth.instance.login();

    if (result.status == LoginStatus.success) {
      final AccessToken? accessToken = result.accessToken;
      if (accessToken != null) {
        final String token = accessToken.tokenString;
        final facebookAuthCredential = FacebookAuthProvider.credential(token);
        return await FirebaseAuth.instance
            .signInWithCredential(facebookAuthCredential);
      }
    }
    throw Exception('Помилка входу через Facebook: ${result.status}');
  }

  Widget _buildEmailPasswordForm() {
    return Column(
      key: const ValueKey('EmailForm'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Email'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Будь ласка, введіть email';
            }
            return null;
          },
        ),
        TextFormField(
          controller: _passwordController,
          decoration: const InputDecoration(labelText: 'Пароль'),
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Будь ласка, введіть пароль';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _signIn();
              }
            },
            child: const Text('Вхід'),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _register();
              }
            },
            child: const Text('Реєстрація'),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Авторизація'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => setState(() {
                    _showEmailForm = !_showEmailForm;
                  }),
                  child: Text(_showEmailForm
                      ? 'Сховати Email/Пароль'
                      : 'Показати Email/Пароль'),
                ),
              ),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => SizeTransition(
                  sizeFactor: animation,
                  child: child,
                ),
                child: _showEmailForm
                    ? _buildEmailPasswordForm()
                    : const SizedBox(key: ValueKey('EmptySpace')),
              ),
              Divider(),
              selectButton('assets/google.512x512.png', 'Увійти через Google',
                  _signInWithGoogle),
              selectButton('assets/Facebook_logo_PNG12.png',
                  'Увійти через Facebook', signInWithFacebook)
            ],
          ),
        ),
      ),
    );
  }

  SizedBox selectButton(
      String? imagePath, String nameButton, Function onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
        onPressed: () => onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(imagePath ?? '', height: 24),
            const SizedBox(width: 8),
            Text(nameButton),
          ],
        ),
      ),
    );
  }
}
