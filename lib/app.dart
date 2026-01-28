import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kresai/theme/app_theme.dart';
import 'package:kresai/navigation/role_switcher.dart';
import 'package:kresai/screens/auth/login_screen.dart';
import 'package:kresai/screens/teacher/home_screen.dart';
import 'package:kresai/screens/teacher/homework_management_screen.dart';
import 'package:kresai/screens/teacher/homework_creation_screen.dart';

// ⚠️ TEST LAB MODE - Set to false for production!
// When true, bypasses authentication and goes directly to TeacherHomeScreen
const bool TEST_LAB_MODE = true;

/// KresAI Ana Uygulama
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KresAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routes: _buildRoutes(),
      home: TEST_LAB_MODE
          ? const RoleSwitcherScreen() // Direct access for Test Lab
          : StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                // Show loading while checking auth state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                // If user is logged in, show role switcher
                if (snapshot.hasData && snapshot.data != null) {
                  return const RoleSwitcherScreen();
                }

                // If not logged in, show login screen
                return const LoginScreen();
              },
            ),
    );
  }

  // Named routes configuration
  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      '/teacher/homework-management': (context) => const HomeworkManagementScreen(),
      '/teacher/homework-creation': (context) => const HomeworkCreationScreen(),
      // Note: Review and Report screens require 'homework' object parameter,
      // they should be navigated to using Navigator.push with MaterialPageRoute
    };
  }
}
