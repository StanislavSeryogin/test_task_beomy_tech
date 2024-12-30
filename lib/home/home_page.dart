import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:test_task_beomy_tech/auth/auth_page.dart';
import 'package:test_task_beomy_tech/home/widgets/sun/animated_sun.dart';
import 'package:test_task_beomy_tech/home/widgets/wave/animated_wave.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    await FacebookAuth.instance.logOut();
    await FlutterSecureStorage().deleteAll();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Log out of account',
          onPressed: () => _signOut(context),
        ),
        title: const Text('BeomyTech'),
      ),
      body: Stack(
        children: [
          const AnimatedWave(),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'BeomyTech',
                  style: TextStyle(fontSize: 40),
                ),
              ],
            ),
          ),
          Positioned(
            top: 50,
            right: 20,
            child: SizedBox(
              width: 200,
              height: 200,
              child: Center(
                child: AnimatedSun(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
