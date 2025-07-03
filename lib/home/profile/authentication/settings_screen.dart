// settings_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../authentication/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings and Privacy'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Account'),
          _buildListTile(
            title: 'Account Information',
            icon: Icons.person_outline,
            onTap: () {
              // Navigate to account info screen
            },
          ),
          _buildListTile(
            title: 'Privacy',
            icon: Icons.lock_outline,
            onTap: () {
              // Navigate to privacy settings
            },
          ),
          _buildListTile(
            title: 'Security',
            icon: Icons.security_outlined,
            onTap: () {
              // Navigate to security settings
            },
          ),
          _buildSectionHeader('Content & Display'),
          _buildListTile(
            title: 'Content Preferences',
            icon: Icons.visibility_outlined,
            onTap: () {
              // Navigate to content preferences
            },
          ),
          _buildListTile(
            title: 'Digital Wellbeing',
            icon: Icons.health_and_safety_outlined,
            onTap: () {
              // Navigate to digital wellbeing
            },
          ),
          _buildSectionHeader('Support & About'),
          _buildListTile(
            title: 'Help Center',
            icon: Icons.help_outline,
            onTap: () {
              // Open help center
            },
          ),
          _buildListTile(
            title: 'Report a Problem',
            icon: Icons.report_problem_outlined,
            onTap: () {
              // Report problem
            },
          ),
          _buildListTile(
            title: 'Terms of Service',
            icon: Icons.description_outlined,
            onTap: () {
              // Show terms
            },
          ),
          _buildSectionHeader('Actions'),
          _buildListTile(
            title: 'Logout',
            icon: Icons.logout,
            onTap: () async {
              await _showLogoutConfirmation(context);
            },
            textColor: Colors.red,
            iconColor: Colors.red,
          ),
          _buildListTile(
            title: 'Delete Account',
            icon: Icons.delete_outline,
            onTap: () {
              // Show delete account confirmation
            },
            textColor: Colors.red,
            iconColor: Colors.red,
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'App Version 1.0.0',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(color: textColor),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                await _performLogout();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Get.offAll(() => const LoginScreen());
    } catch (e) {
      Get.snackbar('Error', 'Failed to logout: ${e.toString()}');
    }
  }
}