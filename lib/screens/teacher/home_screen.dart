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
    // No Scaffold here - handled by TeacherShell
    return _isLoading
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
}
