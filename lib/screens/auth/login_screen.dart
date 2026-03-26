import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      // 2. TRIGGER THE SHEET (replaces .signIn())
      // ignore: unnecessary_nullable_for_final_variable_declarations
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance
          .authenticate();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      // 3. GET ID TOKEN (Authentication is now a synchronous getter)
      final String? idToken = googleUser.authentication.idToken;

      // 4. GET ACCESS TOKEN (Authorization is now a separate step)
      final List<String> scopes = ['email', 'profile'];
      final authClient = await googleUser.authorizationClient.authorizeScopes(
        scopes,
      );
      // ignore: unnecessary_nullable_for_final_variable_declarations
      final String? accessToken = authClient.accessToken;

      // 5. CREATE CREDENTIAL
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );

      // 6. SIGN IN TO FIREBASE
      await FirebaseAuth.instance.signInWithCredential(credential);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Homescreen()),
        );
      }
    } catch (e) {
      log('Error during Google Sign-In: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFD1DC), // Baby Pink
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.purple)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Kiwi",
                    style: TextStyle(
                      fontFamily: 'Pacifico',
                      fontSize: 48,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: _handleGoogleSignIn,
                    icon: const Icon(Icons.login),
                    label: const Text("Continue with Google"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
