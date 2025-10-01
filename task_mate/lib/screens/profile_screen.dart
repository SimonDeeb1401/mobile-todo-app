import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.person,
                  size: 80,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  "John Doe",
                  style: AppTextStyles.heading2,
                ),
                const SizedBox(height: 8),
                Text("Email: johndoe@example.com", style: AppTextStyles.bodyLarge),
                const SizedBox(height: 8),
                Text("Age: 23", style: AppTextStyles.bodyLarge),
                const SizedBox(height: 8),
                Text("Occupation: Student", style: AppTextStyles.bodyLarge),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                    child: ElevatedButton(
                    onPressed: () async {
                      final success = await ApiService.logout();
                      if (success) {
                        // if (!mounted) return;
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      } else {
                        // if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Logout failed. Please try again.')),
                        );
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                      Icon(Icons.logout),
                      SizedBox(width: 8),
                      Text("Log Out"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
