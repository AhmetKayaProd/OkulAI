import 'package:flutter/material.dart';
import '../../services/registration_store.dart';
import '../../services/live_store.dart';
import '../../services/daily_log_store.dart';
import '../../services/feed_store.dart';
import '../../services/activity_log_store.dart';
import '../../models/live_session.dart';
import '../../models/feed_item.dart';
import '../../models/activity_event.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/modern_card.dart';
import '../../widgets/common/modern_button.dart';
import 'parent_approvals_screen.dart';
import 'exam_management_screen.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  final _registrationStore = RegistrationStore();
  final _liveStore = LiveStore();
  final _dailyLogStore = DailyLogStore();
  final _feedStore = FeedStore();
  final _activityLogStore = ActivityLogStore();

  bool _isLoading = true;
  int _pendingParents = 0;
  LiveSession? _activeSession;
  int _loggedChildren = 0;
  int _totalChildren = 0;
  List<FeedItem> _latestFeed = [];
  List<ActivityEvent> _latestActivity = [];
  String? _classId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    await _registrationStore.load();
    await _liveStore.load();
    await _dailyLogStore.load();
    await _feedStore.load();
    await _activityLogStore.load();

    final teacherReg = _registrationStore.getCurrentTeacherRegistration();
    if (teacherReg != null && mounted) {
      _classId = teacherReg.className;
      _pendingParents = _registrationStore.getPendingParents().length;
      _activeSession = _liveStore.getActiveSession(_classId!);
      
      final dateKey = _getDateKey(DateTime.now());
      _totalChildren = _dailyLogStore.getChildrenByClass(_classId!).length;
      final logsToday = _dailyLogStore.listByClassAndDate(_classId!, dateKey);
      _loggedChildren = logsToday.keys.length;

      _latestFeed = _feedStore.listForTeacher(_classId!).take(3).toList();
      _latestActivity = _activityLogStore.getLatest(limit: 5);

      setState(() => _isLoading = false);
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.backgroundLight,
      appBar: AppBar(
        title: const Text('OkulAI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppTokens.primaryLight,
              child: ListView(
                padding: const EdgeInsets.all(AppTokens.spacing20),
                children: [
                  _buildWelcomeHeader(),
                  const SizedBox(height: AppTokens.spacing24),
                  _buildQuickActionsGrid(),
                  const SizedBox(height: AppTokens.spacing32),
                  _buildSectionHeader('Bugünün Özeti', Icons.analytics_outlined),
                  const SizedBox(height: AppTokens.spacing16),
                  _buildSummaryCards(),
                  const SizedBox(height: AppTokens.spacing32),
                  if (_pendingParents > 0) ...[
                    _buildPendingApprovalsAlert(),
                    const SizedBox(height: AppTokens.spacing32),
                  ],
                  _buildSectionHeader('Son Aktiviteler', Icons.history_rounded),
                  const SizedBox(height: AppTokens.spacing16),
                  _buildActivityList(),
                ],
              ),
            ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hoş geldin, Öğretmenim 👋',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTokens.textPrimaryLight,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_classId ?? "Sınıf Seçilmedi"} • ${DateTime.now().day} Ocak Çarşamba',
          style: const TextStyle(
            color: AppTokens.textSecondaryLight,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid() {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppTokens.spacing16,
      crossAxisSpacing: AppTokens.spacing16,
      children: [
        _buildActionItem(Icons.assignment_outlined, 'Sınav', Colors.blue, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamManagementScreen()));
        }),
        _buildActionItem(Icons.edit_calendar_outlined, 'Ödev', Colors.purple, () {
          Navigator.pushNamed(context, '/teacher/homework-management');
        }),
        _buildActionItem(Icons.camera_alt_outlined, 'Paylaş', Colors.orange, () {
          Navigator.pushNamed(context, '/teacher/share');
        }),
        _buildActionItem(Icons.more_horiz_rounded, 'Daha', Colors.grey, () {}),
      ],
    );
  }

  Widget _buildActionItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          child: Container(
            padding: const EdgeInsets.all(AppTokens.spacing12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTokens.textSecondaryLight),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTokens.textPrimaryLight),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTokens.textPrimaryLight),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: ModernCard(
            color: AppTokens.primaryLightSoft,
            border: BorderSide.none,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.people_outline_rounded, color: AppTokens.primaryLight),
                const SizedBox(height: 12),
                Text(
                  '$_loggedChildren/$_totalChildren',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTokens.primaryLight),
                ),
                const Text('Yoklama', style: TextStyle(fontSize: 12, color: AppTokens.textSecondaryLight)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ModernCard(
            color: _activeSession != null ? AppTokens.secondaryLightSoft : AppTokens.surfaceLight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.videocam_outlined, 
                  color: _activeSession != null ? AppTokens.secondaryLight : AppTokens.textTertiaryLight
                ),
                const SizedBox(height: 12),
                Text(
                  _activeSession != null ? 'Aktif' : 'Kapalı',
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold, 
                    color: _activeSession != null ? AppTokens.secondaryLight : AppTokens.textSecondaryLight
                  ),
                ),
                const Text('Canlı Yayın', style: TextStyle(fontSize: 12, color: AppTokens.textSecondaryLight)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingApprovalsAlert() {
    return ModernCard(
      color: AppTokens.warningLight.withOpacity(0.1),
      border: const BorderSide(color: AppTokens.warningLight, width: 0.5),
      onTap: () => Navigator.pushNamed(context, '/teacher/parent-approvals'),
      child: Row(
        children: [
          const Icon(Icons.notification_important_rounded, color: AppTokens.warningLight),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_pendingParents Bekleyen Onay',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTokens.textPrimaryLight),
                ),
                const Text('Yeni veli kayıtlarını inceleyin.', style: TextStyle(fontSize: 13, color: AppTokens.textSecondaryLight)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppTokens.textTertiaryLight),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    if (_latestActivity.isEmpty) {
      return const ModernCard(
        child: Center(
          child: Text('Henüz aktivite yok.', style: TextStyle(color: AppTokens.textTertiaryLight)),
        ),
      );
    }

    return Column(
      children: _latestActivity.map((activity) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ModernCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTokens.backgroundLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(_getActivityIcon(activity.type.name), size: 18, color: AppTokens.primaryLight),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title ?? 'Aktivite',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    Text(
                      activity.description,
                      style: const TextStyle(color: AppTokens.textSecondaryLight, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                '12:45', // Örnek saat
                style: const TextStyle(color: AppTokens.textTertiaryLight, fontSize: 11),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'homework': return Icons.edit_note_rounded;
      case 'exam': return Icons.quiz_outlined;
      case 'feed': return Icons.photo_library_outlined;
      default: return Icons.notifications_none_rounded;
    }
  }
}
