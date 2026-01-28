import 'package:flutter/material.dart';
import 'package:kresai/services/registration_store.dart';
import 'package:kresai/services/live_store.dart';
import 'package:kresai/services/daily_log_store.dart';
import 'package:kresai/services/feed_store.dart';
import 'package:kresai/services/activity_log_store.dart';
import 'package:kresai/services/app_config_store.dart';
import 'package:kresai/models/live_session.dart';
import 'package:kresai/models/feed_item.dart';
import 'package:kresai/models/activity_event.dart';
import 'package:kresai/models/app_config.dart';
import 'package:kresai/theme/tokens.dart';
import 'package:kresai/screens/teacher/parent_approvals_screen.dart';
import 'package:kresai/screens/teacher/share_screen.dart';
import 'package:kresai/screens/teacher/exam_management_screen.dart';

/// Teacher Home Screen
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
    setState(() => _isLoading = true);

    await _registrationStore.load();
    await _liveStore.load();
    await _dailyLogStore.load();
    await _feedStore.load();
    await _activityLogStore.load();

    final teacherReg = _registrationStore.getCurrentTeacherRegistration();
    if (teacherReg != null && mounted) {
      _classId = teacherReg.className;

      // Pending parents
      _pendingParents = _registrationStore.getPendingParents().length;

      // Active live session
      _activeSession = _liveStore.getActiveSession(_classId!);

      // Today logs progress
      final dateKey = _getDateKey(DateTime.now());
      _totalChildren = _dailyLogStore.getChildrenByClass(_classId!).length;
      final logsToday = _dailyLogStore.listByClassAndDate(_classId!, dateKey);
      _loggedChildren = logsToday.keys.length;

      // Latest feed
      _latestFeed = _feedStore.listForTeacher(_classId!).take(3).toList();
      
      // Latest activity (son 5)
      _latestActivity = _activityLogStore.getLatest(limit: 5);

      setState(() => _isLoading = false);
    } else {
      setState(() => _isLoading = false);
    }
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Sayfa'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(AppTokens.spacing16),
                children: [
                  // Quick Actions Hero Section
                  _buildQuickActionsHero(),
                  const SizedBox(height: AppTokens.spacing24),

                  // At-a-Glance Summary
                  _buildAtAGlanceSummary(),
                  const SizedBox(height: AppTokens.spacing24),

                  // Collapsible Cards
                  _buildPendingParentsCard(),
                  const SizedBox(height: AppTokens.spacing12),

                  _buildLiveStatusCard(),
                  const SizedBox(height: AppTokens.spacing12),

                  _buildTodayLogsCard(),
                  const SizedBox(height: AppTokens.spacing12),

                  _buildLatestFeedCard(),
                  const SizedBox(height: AppTokens.spacing12),

                  _buildLatestActivityCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildQuickActionsHero() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hoş geldin! 👋',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTokens.primaryLight,
              ),
            ),
            const SizedBox(height: AppTokens.spacing8),
            Text(
              'Bugün ne yapmak istersin?',
              style: TextStyle(
                fontSize: 14,
                color: AppTokens.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppTokens.spacing24),
            // Quick action buttons grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: [
                _buildQuickActionButton(
                  icon: Icons.assignment,
                  label: 'Sınav Oluştur',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ExamManagementScreen(),
                      ),
                    );
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.school,
                  label: 'Ödev Ver',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pushNamed(context, '/teacher/homework-management');
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.today,
                  label: 'Bugünün Planı',
                  color: Colors.green,
                  onTap: () {
                    // TODO: Navigate to today plan
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Plan ekranı yakında...')),
                    );
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.message,
                  label: 'Veli Mesajları',
                  color: Colors.orange,
                  onTap: () {
                    // TODO: Navigate to messages
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mesajlar yakında...')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAtAGlanceSummary() {
    return Card(
      color: AppTokens.primaryLight.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today, size: 20, color: AppTokens.primaryLight),
                const SizedBox(width: 8),
                const Text(
                  'Bugün',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildSummaryChip(
                  icon: Icons.people,
                  label: '$_loggedChildren/$_totalChildren giriş yapıldı',
                  color: _loggedChildren == _totalChildren 
                      ? Colors.green 
                      : Colors.blue,
                ),
                if (_pendingParents > 0)
                  _buildSummaryChip(
                    icon: Icons.notification_important,
                    label: '$_pendingParents veli onayı',
                    color: Colors.orange,
                  ),
                if (_activeSession != null)
                  _buildSummaryChip(
                    icon: Icons.videocam,
                    label: 'Canlı yayın aktif',
                    color: Colors.red,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLatestActivityCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: AppTokens.primaryLight),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Son Aktiviteler',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spacing12),
            if (_latestActivity.isEmpty)
              Text(
                'Henüz aktivite yok',
                style: TextStyle(color: AppTokens.textSecondaryLight),
              )
            else
              Column(
                children: _latestActivity.map((event) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          _getActivityIcon(event.type),
                          size: 16,
                          color: AppTokens.textSecondaryLight,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            event.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getActivityIcon(ActivityEventType type) {
    switch (type) {
      case ActivityEventType.teacherApproved:
      case ActivityEventType.parentApproved:
        return Icons.check_circle;
      case ActivityEventType.teacherRejected:
      case ActivityEventType.parentRejected:
        return Icons.cancel;
      case ActivityEventType.liveStarted:
        return Icons.videocam;
      case ActivityEventType.liveEnded:
        return Icons.videocam_off;
      case ActivityEventType.feedPosted:
        return Icons.dynamic_feed;
      case ActivityEventType.dailyUpdated:
        return Icons.assignment;
    }
  }

  Widget _buildPendingParentsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.how_to_reg, color: AppTokens.primaryLight),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Bekleyen Veli Başvuruları',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _pendingParents > 0 ? Colors.orange : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _pendingParents.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spacing12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TeacherParentApprovalsScreen(),
                    ),
                  );
                },
                child: const Text('Onaylara Git'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.videocam,
                  color: _activeSession != null ? Colors.red : AppTokens.primaryLight,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _activeSession != null ? 'Canlı Yayın Aktif' : 'Canlı Yayın',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_activeSession != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'CANLI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (_activeSession != null) ...[
              const SizedBox(height: 8),
              Text(
                _activeSession!.title,
                style: TextStyle(color: AppTokens.textSecondaryLight),
              ),
            ],
            const SizedBox(height: AppTokens.spacing12),
            Text(
              _activeSession != null
                  ? 'Canlı yayınınız devam ediyor. Bitirmek için Canlı sekmesine gidin.'
                  : 'Canlı yayın başlatmak için Canlı sekmesine gidin.',
              style: TextStyle(
                fontSize: 12,
                color: AppTokens.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayLogsCard() {
    // Feature flags
    final config = AppConfigStore().config;
    final title = config != null && config.schoolType == SchoolType.primaryPrivate
        ? 'Bugün (Ders Girişi)'
        : 'Bugün Girişleri';
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment, color: AppTokens.primaryLight),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spacing12),
            Row(
              children: [
                Text(
                  '$_loggedChildren / $_totalChildren',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'çocuk için giriş yapıldı',
                  style: TextStyle(color: AppTokens.textSecondaryLight),
                ),
              ],
            ),
            if (_totalChildren > 0) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _loggedChildren / _totalChildren,
                backgroundColor: Colors.grey.withOpacity(0.2),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLatestFeedCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dynamic_feed, color: AppTokens.primaryLight),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Son Paylaşımlar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spacing12),
            if (_latestFeed.isEmpty)
              Text(
                'Henüz paylaşım yok',
                style: TextStyle(color: AppTokens.textSecondaryLight),
              )
            else
              Column(
                children: _latestFeed.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${_getFeedTypeLabel(item.type)}: ${item.textContent ?? ""}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: AppTokens.spacing12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TeacherShareScreen(),
                        ),
                      );
                    },
                    child: const Text('Paylaş'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getFeedTypeLabel(FeedItemType type) {
    switch (type) {
      case FeedItemType.photo:
        return 'Fotoğraf';
      case FeedItemType.video:
        return 'Video';
      case FeedItemType.activity:
        return 'Aktivite';
      case FeedItemType.text:
        return 'Metin';
    }
  }
}
