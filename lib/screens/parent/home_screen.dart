import 'package:flutter/material.dart';
import '../../services/live_store.dart';
import '../../services/daily_log_store.dart';
import '../../services/feed_store.dart';
import '../../services/registration_store.dart';
import '../../models/live_session.dart';
import '../../models/daily_log.dart';
import '../../models/feed_item.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/modern_card.dart';
import '../../widgets/common/modern_button.dart';
import 'live_screen.dart';
import 'daily_log_screen.dart';
import 'homework_list_screen.dart';
import 'exam_list_screen.dart';

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
  String? _studentName;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    await _liveStore.load();
    await _dailyLogStore.load();
    await _feedStore.load();
    await _registrationStore.load();

    final parentReg = _registrationStore.getCurrentParentRegistration();
    if (parentReg != null && mounted) {
      _hasConsent = parentReg.photoConsent;
      _studentName = parentReg.studentName;
      _childId = '${parentReg.studentName.toLowerCase().replaceAll(' ', '_')}_global';
      _activeSession = _liveStore.getActiveSession('global');
      
      final dateKey = _getDateKey(DateTime.now());
      _dailySummary = _dailyLogStore.summaryForParent(_childId!, dateKey);

      final allFeed = _feedStore.listForParent(
        parentId: parentReg.id,
        classId: 'global',
        parentConsentGranted: _hasConsent,
      );
      _latestFeed = allFeed.take(3).toList();

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
                  _buildHeader(),
                  const SizedBox(height: AppTokens.spacing24),
                  if (_activeSession != null) ...[
                    _buildLiveAlert(),
                    const SizedBox(height: AppTokens.spacing24),
                  ],
                  _buildQuickActions(),
                  const SizedBox(height: AppTokens.spacing32),
                  _buildSectionHeader('Bugünkü Durum', Icons.child_care_rounded),
                  const SizedBox(height: AppTokens.spacing16),
                  _buildDailyStatusGrid(),
                  const SizedBox(height: AppTokens.spacing32),
                  _buildSectionHeader('Son Paylaşımlar', Icons.auto_awesome_mosaic_rounded),
                  const SizedBox(height: AppTokens.spacing16),
                  _buildFeedList(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Merhaba, ${_studentName ?? "Veli"}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTokens.textPrimaryLight,
            letterSpacing: -0.5,
          ),
        ),
        const Text(
          'Çocuğunuzun bugünkü aktivitelerini buradan takip edebilirsiniz.',
          style: TextStyle(color: AppTokens.textSecondaryLight, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildLiveAlert() {
    return ModernCard(
      color: AppTokens.errorLight.withOpacity(0.05),
      border: const BorderSide(color: AppTokens.errorLight, width: 0.5),
      onTap: () {
        if (_hasConsent) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => LivePlayerStubScreen(session: _activeSession!)));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Canlı yayın için fotoğraf izni gereklidir.')));
        }
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: AppTokens.errorLight, shape: BoxShape.circle),
            child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Canlı Yayın Aktif', style: TextStyle(fontWeight: FontWeight.bold, color: AppTokens.textPrimaryLight)),
                Text('Sınıfı canlı izlemek için tıklayın.', style: TextStyle(fontSize: 12, color: AppTokens.textSecondaryLight)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppTokens.textTertiaryLight),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: ModernCard(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentHomeworkListScreen())),
            child: const Column(
              children: [
                Icon(Icons.edit_calendar_rounded, color: Colors.purple),
                SizedBox(height: 8),
                Text('Ödevler', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ModernCard(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentExamListScreen())),
            child: const Column(
              children: [
                Icon(Icons.quiz_rounded, color: Colors.blue),
                SizedBox(height: 8),
                Text('Sınavlar', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ModernCard(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentDailyLogScreen())),
            child: const Column(
              children: [
                Icon(Icons.history_rounded, color: Colors.green),
                SizedBox(height: 8),
                Text('Geçmiş', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
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

  Widget _buildDailyStatusGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: [
        _buildStatusItem(DailyLogType.meal, Icons.restaurant_rounded, Colors.orange),
        _buildStatusItem(DailyLogType.nap, Icons.bedtime_rounded, Colors.indigo),
        _buildStatusItem(DailyLogType.toilet, Icons.wc_rounded, Colors.teal),
        _buildStatusItem(DailyLogType.activity, Icons.palette_rounded, Colors.pink),
      ],
    );
  }

  Widget _buildStatusItem(DailyLogType type, IconData icon, Color color) {
    final log = _dailySummary[type];
    final isDone = log != null && log.status == DailyLogStatus.done;

    return ModernCard(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: isDone ? color : AppTokens.textTertiaryLight),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getTypeLabel(type),
              style: TextStyle(
                fontWeight: FontWeight.w600, 
                fontSize: 13,
                color: isDone ? AppTokens.textPrimaryLight : AppTokens.textTertiaryLight
              ),
            ),
          ),
          if (isDone) const Icon(Icons.check_circle_rounded, size: 16, color: AppTokens.successLight),
        ],
      ),
    );
  }

  Widget _buildFeedList() {
    if (_latestFeed.isEmpty) {
      return const ModernCard(
        child: Center(child: Text('Henüz paylaşım yok.', style: TextStyle(color: AppTokens.textTertiaryLight))),
      );
    }

    return Column(
      children: _latestFeed.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: ModernCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.type == FeedItemType.photo && item.mediaUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTokens.radiusMedium)),
                  child: Image.network(
                    item.mediaUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 180, 
                      color: AppTokens.backgroundLight,
                      child: const Icon(Icons.image_not_supported_outlined, color: AppTokens.textTertiaryLight),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(radius: 12, backgroundColor: AppTokens.primaryLightSoft, child: Icon(Icons.person, size: 14, color: AppTokens.primaryLight)),
                        const SizedBox(width: 8),
                        const Text('Öğretmen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const Spacer(),
                        Text('2s önce', style: const TextStyle(color: AppTokens.textTertiaryLight, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(item.description, style: const TextStyle(color: AppTokens.textSecondaryLight, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  String _getTypeLabel(DailyLogType type) {
    switch (type) {
      case DailyLogType.meal: return 'Yemek';
      case DailyLogType.nap: return 'Uyku';
      case DailyLogType.toilet: return 'Tuvalet';
      case DailyLogType.activity: return 'Etkinlik';
      case DailyLogType.note: return 'Not';
    }
  }

}
