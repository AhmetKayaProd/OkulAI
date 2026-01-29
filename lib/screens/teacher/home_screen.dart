import 'package:flutter/material.dart';
import '../../services/registration_store.dart';
import '../../services/live_store.dart';
import '../../services/daily_log_store.dart';
import '../../services/feed_store.dart';
import '../../services/activity_log_store.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/modern_card.dart';
import '../../models/live_session.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  // Stores (Existing logic kept for data consistency)
  final _registrationStore = RegistrationStore();
  final _liveStore = LiveStore();
  final _dailyLogStore = DailyLogStore();
  final _feedStore = FeedStore();
  final _activityLogStore = ActivityLogStore();

  bool _isLoading = true;
  String? _classId;

  // Bottom Nav Index
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    // Mock loading or real loading
    await Future.delayed(const Duration(milliseconds: 500)); // Smooth transition
    await _registrationStore.load();
    await _liveStore.load();
    
    final teacherReg = _registrationStore.getCurrentTeacherRegistration();
    if (teacherReg != null && mounted) {
      _classId = teacherReg.className;
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Slightly cooler background
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildOverviewSection(),
                  ],
                ),
              ),
      ),
      floatingActionButton: _buildMagicFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomMenuBar(),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Merhaba,',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w400, // Light/Regular
                color: Color(0xFF1E293B),
                height: 1.1,
              ),
            ),
            const Text(
              'Hocam',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
                height: 1.1,
              ),
            ),
          ],
        ),
        Row(
          children: [
            _buildHeaderIconBtn(Icons.mail_outlined),
            const SizedBox(width: 12),
            _buildHeaderIconBtn(Icons.campaign_outlined),
            const SizedBox(width: 12),
            _buildHeaderIconBtn(Icons.notifications_none_rounded),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderIconBtn(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: const Color(0xFF64748B), size: 22),
    );
  }

  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Genel Bakış',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.95, // Adjusts height of cards
          children: [
            _buildDashboardCard(
              title: "Ödevler",
              value: "12",
              subtitle: "Bekleyen Teslim",
              icon: Icons.assignment_outlined,
              accentColor: const Color(0xFFFFA500), // Orange
              iconBgColor: const Color(0xFFFFF7ED),
              borderColor: const Color(0xFFFFA500),
            ),
            _buildDashboardCard(
              title: "Sınavlar",
              value: "3",
              subtitle: "Yaklaşan Sınav",
              icon: Icons.description_outlined,
              accentColor: const Color(0xFFa855f7), // Purple
              iconBgColor: const Color(0xFFFAF5FF),
              borderColor: const Color(0xFFa855f7),
            ),
            _buildDashboardCard(
              title: "İlerleme",
              value: "%85",
              subtitle: "Müfredat Durumu",
              icon: Icons.trending_up_rounded,
              accentColor: const Color(0xFF3B82F6), // Blue
              iconBgColor: const Color(0xFFEFF6FF),
              borderColor: const Color(0xFF3B82F6),
            ),
            _buildDashboardCard(
              title: "Yoklama",
              value: "Tamam",
              subtitle: " ", // Empty subtitle to match layout or put something
              icon: Icons.check_circle_outline_rounded,
              accentColor: const Color(0xFF10B981), // Green
              iconBgColor: const Color(0xFFECFDF5),
              borderColor: const Color(0xFF10B981),
              isComplete: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color iconBgColor,
    required Color borderColor,
    bool isComplete = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const Spacer(),
          if (!isComplete && subtitle.trim().isNotEmpty)
             Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF94A3B8),
              ),
            ),
          if (isComplete)
             const Text(
              "Bugün Tamamlandı",
               style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF10B981), // Green text
              ),
             ),
          const SizedBox(height: 8),
          // Colored bottom border line
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMagicFab() {
    return Container(
      height: 64,
      width: 64,
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
            // Magic Action
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

  Widget _buildBottomMenuBar() {
    return BottomAppBar(
      height: 70, // Slightly taller
      notchMargin: 10,
      shape: const CircularNotchedRectangle(),
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shadowColor: Colors.black12,
      elevation: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_filled, "Anasayfa"),
          _buildNavItem(1, Icons.task_alt_rounded, "Kazanım"),
          const SizedBox(width: 48), // Space for FAB
          _buildNavItem(2, Icons.menu_book_rounded, "Ödevler"), // changed icon
          _buildNavItem(3, Icons.quiz_outlined, "Sınavlar"), // changed icon
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
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
