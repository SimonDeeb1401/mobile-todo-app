import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:task_mate/my_tasks.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FlutterAppAuth appAuth = const FlutterAppAuth();

  // Replace with your credentials
  final String googleClientId =
      "521153989375-gdn6vqoae5dsurri124fn3ks9otomef4.apps.googleusercontent.com"; // From Google Cloud Console
  final String microsoftClientId =
      "YOUR_MICROSOFT_CLIENT_ID"; // From Azure App Registration

  Future<void> _signInWithGoogle() async {
    try {
      final result = await appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          googleClientId,
          "com.example.task_mate:/oauth2redirect", // match with Google console
          discoveryUrl:
              "https://accounts.google.com/.well-known/openid-configuration",
          scopes: ["openid", "email", "profile"],
        ),
      );
      if (result != null) {
        _showMessage("Google Sign-In Success\nID Token: ${result.idToken}");
        if (!mounted) return; // Check if widget is still mounted
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => TaskListScreen()),
        );
      }
    } catch (e) {
      _showMessage("Google Sign-In Error: $e");
    }
  }

  Future<void> _signInWithMicrosoft() async {
    try {
      final result = await appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          microsoftClientId,
          "com.example.app://auth", // match with Azure Redirect URI
          discoveryUrl:
              "https://login.microsoftonline.com/common/v2.0/.well-known/openid-configuration",
          scopes: ["openid", "email", "profile", "User.Read"],
        ),
      );
      if (result != null) {
        _showMessage("Microsoft Sign-In Success\nID Token: ${result.idToken}");
      }
    } catch (e) {
      _showMessage("Microsoft Sign-In Error: $e");
    }
  }

  void _showMessage(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Login Result"),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login Screen")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _signInWithGoogle,
              child: const Text("Sign in with Google"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signInWithMicrosoft,
              child: const Text("Sign in with Microsoft"),
            ),
          ],
        ),
      ),
    );
  }
}
