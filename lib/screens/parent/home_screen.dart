import 'package:flutter/material.dart';
import 'package:kresai/services/live_store.dart';
import 'package:kresai/services/daily_log_store.dart';
import 'package:kresai/services/feed_store.dart';
import 'package:kresai/services/registration_store.dart';
import 'package:kresai/services/app_config_store.dart';
import 'package:kresai/models/live_session.dart';
import 'package:kresai/models/daily_log.dart';
import 'package:kresai/models/feed_item.dart';
import 'package:kresai/models/app_config.dart';
import 'package:kresai/theme/tokens.dart';
import 'package:kresai/screens/parent/live_screen.dart';
import 'package:kresai/screens/parent/daily_log_screen.dart';
import 'package:kresai/screens/parent/homework_list_screen.dart';
import 'package:kresai/screens/parent/exam_list_screen.dart';
import 'package:kresai/app.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Parent Home Screen - Ana Sayfa
class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  final _liveStore = LiveStore();
  final _dailyLogStore = DailyLogStore();
  final _feedStore = FeedStore();
  final _registrationStore = RegistrationStore();

  bool _isLoading = true;
  LiveSession? _activeSession;
  Map<DailyLogType, DailyLogItem?> _dailySummary = {};
  List<FeedItem> _latestFeed = [];
  bool _hasConsent = false;
  String? _childId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    await _liveStore.load();
    await _dailyLogStore.load();
    await _feedStore.load();
    await _registrationStore.load();

    final parentReg = _registrationStore.getCurrentParentRegistration();
    if (parentReg != null && mounted) {
      _hasConsent = parentReg.photoConsent;

      // Child ID
      _childId = '${parentReg.studentName.toLowerCase().replaceAll(' ', '_')}_global';

      // Live session (demo: global classId)
      _activeSession = _liveStore.getActiveSession('global');

      // Daily summary (today)
      final dateKey = _getDateKey(DateTime.now());
      _dailySummary = _dailyLogStore.summaryForParent(_childId!, dateKey);

      // Latest feed (top 3)
      final allFeed = _feedStore.listForParent(
        parentId: parentReg.id,
        classId: 'global',
        parentConsentGranted: _hasConsent,
      );
      _latestFeed = allFeed.take(3).toList();

      setState(() => _isLoading = false);
    } else {
      setState(() => _isLoading = false);
    }
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getTypeLabel(DailyLogType type) {
    switch (type) {
      case DailyLogType.meal:
        return 'Yemek';
      case DailyLogType.nap:
        return 'Uyku';
      case DailyLogType.toilet:
        return 'Tuvalet';
      case DailyLogType.activity:
        return 'Etkinlik';
      case DailyLogType.note:
        return 'Not';
    }
  }

  IconData _getDailyIcon(DailyLogType type) {
    switch (type) {
      case DailyLogType.meal:
        return Icons.restaurant;
      case DailyLogType.nap:
        return Icons.bed;
      case DailyLogType.toilet:
        return Icons.wc;
      case DailyLogType.activity:
        return Icons.palette;
      case DailyLogType.note:
        return Icons.note;
    }
  }

  String _getStatusLabel(DailyLogStatus status) {
    switch (status) {
      case DailyLogStatus.done:
        return 'Tamamlandı';
      case DailyLogStatus.partial:
        return 'Kısmi';
      case DailyLogStatus.skipped:
        return 'Atlandı';
    }
  }

  Color _getStatusColor(DailyLogStatus status) {
    switch (status) {
      case DailyLogStatus.done:
        return Colors.green;
      case DailyLogStatus.partial:
        return Colors.orange;
      case DailyLogStatus.skipped:
        return Colors.grey;
    }
  }

  IconData _getFeedIcon(FeedItemType type) {
    switch (type) {
      case FeedItemType.photo:
        return Icons.photo;
      case FeedItemType.video:
        return Icons.videocam;
      case FeedItemType.activity:
        return Icons.directions_run;
      case FeedItemType.text:
        return Icons.text_snippet;
    }
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
                  // Live Card (only if active)
                  if (_activeSession != null) ...[
                    _buildLiveCard(),
                    const SizedBox(height: AppTokens.spacing16),
                  ],

                  // Today Summary Card
                  _buildTodaySummaryCard(),
                  const SizedBox(height: AppTokens.spacing16),

                  // Homework Shortcut Card
                  _buildHomeworkCard(context),
                  const SizedBox(height: AppTokens.spacing16),

                  // Exam Shortcut Card
                  _buildExamCard(context),
                  const SizedBox(height: AppTokens.spacing16),

                  // Latest Feed Card
                  _buildLatestFeedCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildLiveCard() {
    // Consent check
    if (_activeSession!.requiresConsent && !_hasConsent) {
      return Card(
        color: Colors.orange.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spacing16),
          child: Row(
            children: [
              const Icon(Icons.lock_outline, color: Colors.orange),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Canlı yayın aktif ancak izin gerekli',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to settings
                  Navigator.pushNamed(context, '/parent/settings');
                },
                child: const Text('Ayarlar'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'CANLI YAYIN',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _activeSession!.title,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: AppTokens.spacing12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LivePlayerStubScreen(session: _activeSession!),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('İzle'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySummaryCard() {
    final hasAnyLog = _dailySummary.values.any((log) => log != null);
    
    // Feature flags
    final config = AppConfigStore().config;
    final title = config != null 
        ? FeatureFlags(config.schoolType).todaySummaryTitle 
        : 'Bugünkü Özet';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTokens.spacing12),
            if (!hasAnyLog)
              Text(
                'Bugün henüz giriş yok',
                style: TextStyle(color: AppTokens.textSecondaryLight),
              )
            else
              Column(
                children: [
                  _buildDailySummaryRow(DailyLogType.meal, _dailySummary[DailyLogType.meal]),
                  const Divider(height: 20),
                  _buildDailySummaryRow(DailyLogType.nap, _dailySummary[DailyLogType.nap]),
                  const Divider(height: 20),
                  _buildDailySummaryRow(DailyLogType.toilet, _dailySummary[DailyLogType.toilet]),
                  const Divider(height: 20),
                  _buildDailySummaryRow(DailyLogType.activity, _dailySummary[DailyLogType.activity]),
                ],
              ),
            const SizedBox(height: AppTokens.spacing12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ParentDailyLogScreen(),
                    ),
                  );
                },
                child: const Text('Detay'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySummaryRow(DailyLogType type, DailyLogItem? log) {
    return Row(
      children: [
        Icon(
          _getDailyIcon(type),
          color: log != null ? _getStatusColor(log.status) : Colors.grey,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getTypeLabel(type),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              if (log != null)
                Text(
                  '${_getStatusLabel(log.status)}${log.details != null ? ' - ${log.details}' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getStatusColor(log.status),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              else
                Text(
                  'Giriş yok',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTokens.textSecondaryLight,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLatestFeedCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Son Paylaşımlar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTokens.primaryLight.withOpacity(0.1),
                          child: Icon(
                            _getFeedIcon(item.type),
                            color: AppTokens.primaryLight,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getFeedTypeLabel(item.type),
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              if (item.textContent != null)
                                Text(
                                  item.textContent!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTokens.textSecondaryLight,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: AppTokens.spacing8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  // Navigate to feed tab (index 1)
                  // Parent shell tab değiştir - bu basit bir workaround
                  Navigator.pop(context); // Close if nested
                },
                child: const Text('Tümünü Gör'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeworkCard(BuildContext context) {
    return Card(
      color: Colors.blue.withOpacity(0.1),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ParentHomeworkListScreen(),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spacing16),
          child: Row(
            children: [
              const Icon(Icons.assignment, color: Colors.blue, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Ödevler',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ödevleri görüntüle ve gönder',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExamCard(BuildContext context) {
    return Card(
      color: Colors.purple.withOpacity(0.1),
      child: InkWell(
        onTap: () {
          final parentId = TEST_LAB_MODE ? 'mock_parent_id' : FirebaseAuth.instance.currentUser?.uid ?? '';
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExamListScreen(
                studentId: _childId ?? 'mock_student_id',
                parentId: parentId,
                classId: 'global',
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spacing16),
          child: Row(
            children: [
              const Icon(Icons.quiz, color: Colors.purple, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Sınavlar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Sınavları görüntüle ve çöz',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.purple),
            ],
          ),
        ),
      ),
    );
  }
}
