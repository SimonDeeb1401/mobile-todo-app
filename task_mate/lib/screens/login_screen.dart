import 'package:flutter/material.dart';
import 'package:task_mate/screens/bottom_navigation_bar.dart';
import '../services/api_service.dart';
import 'signup_screen.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  void login() async {
    setState(() => isLoading = true);
    final success = await ApiService.login(emailController.text, passwordController.text);
    setState(() => isLoading = false);
    if (success) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BottomNavigationBarScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Wrong email or password")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo/Title
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: AppDecorations.iconContainerDecoration,
                  child: Icon(
                    Icons.check_circle,
                    size: 50,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 40),
                
                // Welcome Text
                Text(
                  "Welcome to TaskMate",
                  style: AppTextStyles.heading1,
                ),
                SizedBox(height: 8),
                Text(
                  "Sign in to continue",
                  style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                ),
                SizedBox(height: 40),

                // Email Input
                Container(
                  decoration: AppDecorations.inputFieldDecoration,
                  child: TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Email",
                      prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Password Input
                Container(
                  decoration: AppDecorations.inputFieldDecoration,
                  child: TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                  ),
                ),
                SizedBox(height: 30),

                // Login Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: AppDecorations.buttonDecoration,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: isLoading ? null : login,
                      child: Container(
                        alignment: Alignment.center,
                        child: isLoading
                            ? CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : Text(
                                "Sign In",
                                style: AppTextStyles.button,
                              ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 30),

                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SignupScreen()),
                        );
                      },
                      child: Text(
                        "Sign Up",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
