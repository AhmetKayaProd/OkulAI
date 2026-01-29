import 'package:flutter/material.dart';
import 'package:kresai/screens/teacher_screens.dart';
import 'package:kresai/screens/teacher/home_screen.dart'; // The new dashboard content
import 'package:kresai/screens/teacher/homework_management_screen.dart'; // ÖdevAI
import 'package:kresai/screens/teacher/exam_management_screen.dart'; // SınavAI

// Placeholder for Kazanım Screen (Temporary)
class TeacherAchievementsScreen extends StatelessWidget {
  const TeacherAchievementsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text("Kazanım Ekranı (Yakında)")),
    );
  }
}

/// Teacher Shell - New Design Implementation
/// Anasayfa, Kazanım, [FAB], Ödevler, Sınavlar
class TeacherShell extends StatefulWidget {
  const TeacherShell({super.key});

  @override
  State<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends State<TeacherShell> {
  int _currentIndex = 0;

  // The simplified screens list for the new design
  late final List<Widget> _screens = [
    const TeacherHomeScreen(),           // Index 0: Anasayfa (New Dashboard)
    const TeacherAchievementsScreen(),     // Index 1: Kazanım
    const HomeworkManagementScreen(),      // Index 2: Ödevler
    const ExamManagementScreen(),          // Index 3: Sınavlar
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Background matching home screen
      // No AppBar for Dashboard (Index 0) because it has its own custom header
      // For others, we might want one, but sticking to design request for now.
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      floatingActionButton: _buildMagicFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomMenuBar(),
    );
  }

  Widget _buildMagicFab() {
    return Container(
      height: 64,
      width: 64,
      margin: const EdgeInsets.only(top: 24), // Push it slightly up from bottom bar if needed
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)], // Indigo to Purple
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Magic Action - Could be "Create New" menu or AI Assistant
            _showMagicMenu(context);
          },
          customBorder: const CircleBorder(),
          child: const Icon(
            Icons.auto_fix_high_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }

  void _showMagicMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Sihirli İşlemler", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            ListTile(leading: Icon(Icons.auto_awesome), title: Text("AI ile Ödev Oluştur")),
            ListTile(leading: Icon(Icons.quiz), title: Text("Sınav Hazırla")),
            ListTile(leading: Icon(Icons.notifications), title: Text("Duyuru Gönder")),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomMenuBar() {
    return BottomAppBar(
      height: 70, 
      notchMargin: 10,
      shape: const CircularNotchedRectangle(),
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shadowColor: Colors.black12,
      elevation: 20,
      padding: EdgeInsets.zero, // Important to control padding manually
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_filled, "Anasayfa"),
          _buildNavItem(1, Icons.task_alt_rounded, "Kazanım"),
          const SizedBox(width: 48), // Space for FAB
          _buildNavItem(2, Icons.menu_book_rounded, "Ödevler"), 
          _buildNavItem(3, Icons.quiz_outlined, "Sınavlar"), 
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center vertically
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
