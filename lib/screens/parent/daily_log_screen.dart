import 'package:flutter/material.dart';
import 'package:kresai/services/daily_log_store.dart';
import 'package:kresai/services/registration_store.dart';
import 'package:kresai/services/app_config_store.dart';
import 'package:kresai/models/daily_log.dart';
import 'package:kresai/models/app_config.dart';
import 'package:kresai/theme/tokens.dart';

/// Parent Daily Log Screen
class ParentDailyLogScreen extends StatefulWidget {
  const ParentDailyLogScreen({super.key});

  @override
  State<ParentDailyLogScreen> createState() => _ParentDailyLogScreenState();
}

class _ParentDailyLogScreenState extends State<ParentDailyLogScreen> {
  final _dailyLogStore = DailyLogStore();
  final _registrationStore = RegistrationStore();

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  Child? _child;
  Map<DailyLogType, DailyLogItem?> _summary = {};
  List<DailyLogItem> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    await _dailyLogStore.load();
    await _registrationStore.load();

    final parentReg = _registrationStore.getCurrentParentRegistration();
    if (parentReg != null && mounted) {
      // Child oluştur/al (demo: student name'den)
      final childId = '${parentReg.studentName.toLowerCase().replaceAll(' ', '_')}_global';
      _child = Child(
        id: childId,
        name: parentReg.studentName,
        classId: 'global',
      );

      setState(() {
        _summary = _dailyLogStore.summaryForParent(
          _child!.id,
          _getDateKey(_selectedDate),
        );
        _notes = _dailyLogStore.getNotesForDay(
          _child!.id,
          _getDateKey(_selectedDate),
        );
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        _summary = _dailyLogStore.summaryForParent(
          _child!.id,
          _getDateKey(_selectedDate),
        );
        _notes = _dailyLogStore.getNotesForDay(
          _child!.id,
          _getDateKey(_selectedDate),
        );
      });
    }
  }

  String _getTypeLabel(DailyLogType type) {
    final config = AppConfigStore().config;
    final flags = config != null ? FeatureFlags(config.schoolType) : null;
    
    switch (type) {
      case DailyLogType.meal:
        return 'Yemek';
      case DailyLogType.nap:
        return 'Uyku';
      case DailyLogType.toilet:
        return 'Tuvalet';
      case DailyLogType.activity:
        return flags?.dailyActivityLabel ?? 'Etkinlik';
      case DailyLogType.note:
        return 'Not';
    }
  }

  IconData _getTypeIcon(DailyLogType type) {
    final config = AppConfigStore().config;
    final flags = config != null ? FeatureFlags(config.schoolType) : null;
    
    switch (type) {
      case DailyLogType.meal:
        return Icons.restaurant;
      case DailyLogType.nap:
        return Icons.bed;
      case DailyLogType.toilet:
        return Icons.wc;
      case DailyLogType.activity:
        return flags?.dailyActivityIcon ?? Icons.palette;
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

  @override
  Widget build(BuildContext context) {
    final dateKey = _getDateKey(_selectedDate);
    final isToday = dateKey == _getDateKey(DateTime.now());
    final hasAnyLog = _summary.values.any((log) => log != null) || _notes.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Günlük (Veli)'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Child ve Tarih bilgisi
                Container(
                  padding: const EdgeInsets.all(AppTokens.spacing16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _child?.name ?? 'Çocuk',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isToday ? 'Bugün' : dateKey,
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTokens.textSecondaryLight,
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _selectDate,
                            icon: const Icon(Icons.calendar_today),
                            label: const Text('Tarih Seç'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Logs
                Expanded(
                  child: !hasAnyLog
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment_outlined,
                                size: 64,
                                color: AppTokens.textSecondaryLight,
                              ),
                              const SizedBox(height: AppTokens.spacing16),
                              Text(
                                'Bugün henüz giriş yok',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppTokens.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(AppTokens.spacing16),
                          children: [
                            // Summary cards
                            _buildSummaryCard(DailyLogType.meal, _summary[DailyLogType.meal]),
                            const SizedBox(height: AppTokens.spacing12),
                            _buildSummaryCard(DailyLogType.nap, _summary[DailyLogType.nap]),
                            const SizedBox(height: AppTokens.spacing12),
                            _buildSummaryCard(DailyLogType.toilet, _summary[DailyLogType.toilet]),
                            const SizedBox(height: AppTokens.spacing12),
                            _buildSummaryCard(DailyLogType.activity, _summary[DailyLogType.activity]),
                            
                            // Notes
                            if (_notes.isNotEmpty) ...[
                              const SizedBox(height: AppTokens.spacing24),
                              const Text(
                                'Notlar',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppTokens.spacing12),
                              ..._notes.map((note) => Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: const Icon(Icons.note),
                                      title: Text(note.details ?? ''),
                                    ),
                                  )),
                            ],
                          ],
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryCard(DailyLogType type, DailyLogItem? log) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacing16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: log != null
                  ? _getStatusColor(log.status).withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              child: Icon(
                _getTypeIcon(type),
                color: log != null ? _getStatusColor(log.status) : Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getTypeLabel(type),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  if (log != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _getStatusLabel(log.status),
                      style: TextStyle(
                        color: _getStatusColor(log.status),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (log.details != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        log.details!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTokens.textSecondaryLight,
                        ),
                      ),
                    ],
                  ] else
                    Text(
                      'Henüz giriş yok',
                      style: TextStyle(
                        color: AppTokens.textSecondaryLight,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
