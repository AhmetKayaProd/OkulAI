import 'package:flutter/material.dart';
import 'package:kresai/services/daily_log_store.dart';
import 'package:kresai/services/registration_store.dart';
import 'package:kresai/services/app_config_store.dart';
import 'package:kresai/models/daily_log.dart';
import 'package:kresai/models/app_config.dart';
import 'package:kresai/theme/tokens.dart';

/// Teacher Daily Log Screen
class TeacherDailyLogScreen extends StatefulWidget {
  const TeacherDailyLogScreen({super.key});

  @override
  State<TeacherDailyLogScreen> createState() => _TeacherDailyLogScreenState();
}

class _TeacherDailyLogScreenState extends State<TeacherDailyLogScreen> {
  final _dailyLogStore = DailyLogStore();
  final _registrationStore = RegistrationStore();

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  List<Child> _children = [];
  Map<String, List<DailyLogItem>> _logs = {};
  String? _teacherId;
  String? _classId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    await _dailyLogStore.load();
    await _registrationStore.load();

    final teacherReg = _registrationStore.getCurrentTeacherRegistration();
    if (teacherReg != null && mounted) {
      _teacherId = teacherReg.id;
      _classId = teacherReg.className;

      // Children from class roster (demo: roster'dan child oluştur)
      await _ensureChildrenFromRoster();

      setState(() {
        _children = _dailyLogStore.getChildrenByClass(_classId!);
        _logs = _dailyLogStore.listByClassAndDate(
          _classId!,
          _getDateKey(_selectedDate),
        );
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _ensureChildrenFromRoster() async {
    // Class roster'dan children oluştur (demo)
    final roster = _registrationStore.classRoster;
    for (final item in roster) {
      final childId = '${item.studentName.toLowerCase().replaceAll(' ', '_')}_$_classId';
      final existingChild = _dailyLogStore.getChildById(childId);
      if (existingChild == null) {
        await _dailyLogStore.upsertChild(Child(
          id: childId,
          name: item.studentName,
          classId: _classId!,
        ));
      }
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
        _logs = _dailyLogStore.listByClassAndDate(
          _classId!,
          _getDateKey(_selectedDate),
        );
      });
    }
  }

  Future<void> _showLogEntry(Child child, DailyLogType type) async {
    // Mevcut log var mı?
    final childLogs = _logs[child.id] ?? [];
    final existingLog = childLogs.where((l) => l.type == type).firstOrNull;

    DailyLogStatus? selectedStatus = existingLog?.status;
    final detailsController = TextEditingController(text: existingLog?.details ?? '');

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppTokens.spacing16,
                right: AppTokens.spacing16,
                top: AppTokens.spacing16,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppTokens.spacing16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${child.name} - ${_getTypeLabel(type)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTokens.spacing16),
                  const Text(
                    'Durum:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppTokens.spacing8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Tamamlandı'),
                        selected: selectedStatus == DailyLogStatus.done,
                        onSelected: (selected) {
                          setModalState(() => selectedStatus = DailyLogStatus.done);
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Kısmi'),
                        selected: selectedStatus == DailyLogStatus.partial,
                        onSelected: (selected) {
                          setModalState(() => selectedStatus = DailyLogStatus.partial);
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Atlandı'),
                        selected: selectedStatus == DailyLogStatus.skipped,
                        onSelected: (selected) {
                          setModalState(() => selectedStatus = DailyLogStatus.skipped);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.spacing16),
                  TextField(
                    controller: detailsController,
                    decoration: const InputDecoration(
                      labelText: 'Detaylar (opsiyonel)',
                      hintText: 'Örn: "Az yedi", "1 saat", vs.',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppTokens.spacing16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selectedStatus == null
                          ? null
                          : () => Navigator.pop(context, true),
                      child: const Text('Kaydet'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result == true && selectedStatus != null) {
      // Log oluştur/güncelle
      final log = DailyLogItem(
        id: '${child.id}_${_getDateKey(_selectedDate)}_${type.name}_${DateTime.now().millisecondsSinceEpoch}',
        classId: _classId!,
        childId: child.id,
        dateKey: _getDateKey(_selectedDate),
        type: type,
        status: selectedStatus!,
        details: detailsController.text.trim().isNotEmpty ? detailsController.text.trim() : null,
        createdByTeacherId: _teacherId!,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await _dailyLogStore.upsertLog(log);
      _loadData();
    }

    detailsController.dispose();
  }

  String _getTypeLabel(DailyLogType type) {
    // Feature flags için schoolType al
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

  Color? _getStatusColor(DailyLogStatus? status) {
    if (status == null) return null;
    switch (status) {
      case DailyLogStatus.done:
        return Colors.green;
      case DailyLogStatus.partial:
        return Colors.orange;
      case DailyLogStatus.skipped:
        return Colors.grey;
    }
  }

  DailyLogStatus? _getChildLogStatus(Child child, DailyLogType type) {
    final childLogs = _logs[child.id] ?? [];
    final log = childLogs.where((l) => l.type == type).firstOrNull;
    return log?.status;
  }

  @override
  Widget build(BuildContext context) {
    final dateKey = _getDateKey(_selectedDate);
    final isToday = dateKey == _getDateKey(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Günlük (Öğretmen)'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Tarih seçici
                Container(
                  padding: const EdgeInsets.all(AppTokens.spacing16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          isToday ? 'Bugün' : dateKey,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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
                ),
                const Divider(height: 1),
                // Children list
                Expanded(
                  child: _children.isEmpty
                      ? Center(
                          child: Text(
                            'Sınıf listesi boş',
                            style: TextStyle(
                              color: AppTokens.textSecondaryLight,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(AppTokens.spacing16),
                          itemCount: _children.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppTokens.spacing12),
                          itemBuilder: (context, index) {
                            final child = _children[index];
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(AppTokens.spacing12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      child.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: AppTokens.spacing12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildQuickButton(
                                          child,
                                          DailyLogType.meal,
                                          Icons.restaurant,
                                        ),
                                        _buildQuickButton(
                                          child,
                                          DailyLogType.nap,
                                          Icons.bed,
                                        ),
                                        _buildQuickButton(
                                          child,
                                          DailyLogType.toilet,
                                          Icons.wc,
                                        ),
                                        _buildQuickButton(
                                          child,
                                          DailyLogType.activity,
                                          Icons.palette,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildQuickButton(Child child, DailyLogType type, IconData icon) {
    final status = _getChildLogStatus(child, type);
    final color = _getStatusColor(status);

    return Column(
      children: [
        IconButton(
          onPressed: () => _showLogEntry(child, type),
          icon: Icon(icon),
          iconSize: 32,
          color: color,
          style: IconButton.styleFrom(
            backgroundColor: color?.withOpacity(0.1),
          ),
        ),
        if (status != null)
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}
