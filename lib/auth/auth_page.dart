import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
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
  final _localAuth = LocalAuthentication();
  final _secureStorage = const FlutterSecureStorage();
  bool _showEmailForm = false;

  static const String emailKey = 'email';
  static const String passwordKey = 'password';
  static const String userIdKey = 'userId';
  static const String useBiometricsKey = 'useBiometrics';
  static const String isGoogleSignInKey = 'isGoogleSignIn';
  static const String isFacebookSignInKey = 'isFacebookSignIn';

  @override
  void initState() {
    super.initState();
    _tryBiometricLogin();
  }

  // Method for handling the result of authorization
  void _handleAuthResult(User? user, String provider,
      {bool isGoogleSignIn = false, bool isFacebookSignIn = false}) async {
    if (user != null) {
      debugPrint('Entered $provider: ${user.email}');

      await _secureStorage.write(key: emailKey, value: user.email ?? '');
      if (isGoogleSignIn) {
        await _secureStorage.write(key: userIdKey, value: user.uid);
        await _secureStorage.write(key: isGoogleSignInKey, value: 'true');
        await _secureStorage.write(key: isFacebookSignInKey, value: 'false');
      } else if (isFacebookSignIn) {
        await _secureStorage.write(key: userIdKey, value: user.uid);
        await _secureStorage.write(key: isGoogleSignInKey, value: 'false');
        await _secureStorage.write(key: isFacebookSignInKey, value: 'true');
      } else {
        await _secureStorage.write(
            key: passwordKey, value: _passwordController.text);
        await _secureStorage.write(key: isGoogleSignInKey, value: 'false');
        await _secureStorage.write(key: isFacebookSignInKey, value: 'false');
      }

      String? useBiometrics = await _secureStorage.read(key: useBiometricsKey);
      if (useBiometrics == 'true') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        _askBiometrics(user);
      }
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
        debugPrint('Password too weak.');
      } else if (e.code == 'email-already-in-use') {
        debugPrint('An account with this email already exists.');
      }
    } catch (e) {
      debugPrint('Error: $e');
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
        debugPrint('No user with this email was found.');
      } else if (e.code == 'wrong-password') {
        debugPrint('Incorrect password.');
      }
    }
  }

  // Method for Google Sign-In
  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw Exception('Login canceled by user');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      _handleAuthResult(userCredential.user, 'Google', isGoogleSignIn: true);
    } catch (e) {
      debugPrint('Google login error: $e');
    }
  }

  // Method for biometric login
  Future<void> _tryBiometricLogin() async {
    try {
      String? useBiometrics = await _secureStorage.read(key: useBiometricsKey);
      if (useBiometrics != 'true') {
        debugPrint('Biometrics is not activated.');
        return;
      }

      bool canCheck = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      if (!canCheck) {
        debugPrint('The device does not support biometrics.');
        return;
      }

      bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Verify your identity through biometrics',
        options: const AuthenticationOptions(
          biometricOnly: true,
        ),
      );

      if (didAuthenticate) {
        final email = await _secureStorage.read(key: emailKey);
        final isGoogleSignIn =
            await _secureStorage.read(key: isGoogleSignInKey) == 'true';

        if (isGoogleSignIn) {
          final userId = await _secureStorage.read(key: userIdKey);
          debugPrint('Biometric login with Google: $email, UserID: $userId');
          if (email != null && userId != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }
        } else {
          final password = await _secureStorage.read(key: passwordKey);
          debugPrint(
              'Biometric login with email/password: $email, Password: $password');
          if (email != null && password != null) {
            final userCredential =
                await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
            _handleAuthResult(userCredential.user, 'Biometric');
          }
        }
      }
    } catch (e) {
      debugPrint('Biometrics error: $e');
    }
  }

  Future<void> _askBiometrics(User? user) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Use biometrics?'),
          content: const Text(
              'Do you want to use biometrics to quickly log into the app next time?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _secureStorage.write(
                    key: useBiometricsKey, value: 'true');
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<UserCredential> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        final AccessToken? accessToken = result.accessToken;
        if (accessToken != null) {
          final facebookAuthCredential =
              FacebookAuthProvider.credential(accessToken.tokenString);
          UserCredential userCredential = await FirebaseAuth.instance
              .signInWithCredential(facebookAuthCredential);
          _handleAuthResult(userCredential.user, 'Facebook',
              isFacebookSignIn: true);
          return userCredential;
        }
      }
      throw Exception('Facebook login error: ${result.status}');
    } catch (e) {
      debugPrint('Facebook login error: $e');
      rethrow;
    }
  }

  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Authorization'),
      ),
      body: SingleChildScrollView(
        child: Form(
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
                        ? 'Hide Email/Password'
                        : 'Enter Email/Password'),
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
                selectButton('assets/google.512x512.png', 'Sign in with Google',
                    _signInWithGoogle),
                selectButton('assets/Facebook_logo_PNG12.png',
                    'Sign in with Facebook', signInWithFacebook)
              ],
            ),
          ),
        ),
      ),
    );
  }

  SizedBox selectButton(
      String? imagePath, String nameButton, Function() onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
        onPressed: onPressed,
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
              return 'Please enter your email.';
            }
            return null;
          },
        ),
        TextFormField(
          controller: _passwordController,
          decoration: const InputDecoration(labelText: 'Password'),
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
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
            child: const Text('Login'),
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
            child: const Text('Registration'),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
