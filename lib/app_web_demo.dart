import 'package:flutter/material.dart';
import 'package:kresai/theme/app_theme.dart';
import 'package:kresai/screens/teacher/home_screen.dart';
import 'package:kresai/screens/parent/home_screen.dart';
import 'package:kresai/screens/admin/teacher_code_screen.dart';

class AppWebDemo extends StatelessWidget {
  const AppWebDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OkulAI Demo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const DemoHome(),
    );
  }
}

class DemoHome extends StatelessWidget {
  const DemoHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OkulAI Tasarım Önizleme')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildDemoItem(context, 'Öğretmen Paneli', Icons.school, const TeacherHomeScreen()),
          const SizedBox(height: 16),
          _buildDemoItem(context, 'Veli Paneli', Icons.family_restroom, const ParentHomeScreen()),
          const SizedBox(height: 16),
          _buildDemoItem(context, 'Yönetici Paneli', Icons.admin_panel_settings, const AdminTeacherCodeScreen()),
        ],
      ),
    );
  }

  Widget _buildDemoItem(BuildContext context, String title, IconData icon, Widget screen) {
    return ListTile(
      leading: Icon(icon, size: 32, color: Theme.of(context).primaryColor),
      title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
    );
  }
}
