import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  //
  // Registration with email + password
  //

  Future<void> _register() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: _emailController.text, password: _passwordController.text);

      User? user = userCredential.user;
      if (user != null) {
        print('Зареєстрований користувач: ${user.email}');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
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

  //
  // Login with email + password
  //

  Future<void> _signIn() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: _emailController.text, password: _passwordController.text);

      User? user = userCredential.user;
      if (user != null) {
        print('Користувач увійшов: ${user.email}');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('Користувача з таким email не знайдено.');
      } else if (e.code == 'wrong-password') {
        print('Невірний пароль.');
      }
    }
  }

  //
  // Method for Google Sign-In
  //

  Future<void> _signInWithGoogle() async {
    try {
      // Запускаємо процес вибору Google-акаунту
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // Якщо користувач скасував вікно вибору акаунту
        throw Exception('Вхід скасовано користувачем');
      }

      // Отримуємо токени доступу з Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Створюємо спеціальний credential для Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Входимо у Firebase за допомогою обліковки Google
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final user = userCredential.user;
      if (user != null) {
        print('Увійшов через Google: ${user.email}');
        // Переходимо на HomePage (або PresentPage)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      print('Помилка входу через Google: $e');
    }
  }

  //
  // UI
  //
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
            children: <Widget>[
              // Email field
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
              // Password field
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

              // "Login" button (email/password)
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _signIn();
                  }
                },
                child: const Text('Вхід'),
              ),

              // "Register" button (email/password)
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _register();
                  }
                },
                child: const Text('Реєстрація'),
              ),
              const SizedBox(height: 16),
              // "Login with Google" button
              ElevatedButton(
                onPressed: _signInWithGoogle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Можете додати свій логотип Google (png/svg), якщо бажаєте
                    // Напр. Image.asset('assets/google_logo.png', height: 24),
                    const Icon(Icons.login, color: Colors.blueAccent),
                    const SizedBox(width: 8),
                    const Text('Увійти через Google'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
