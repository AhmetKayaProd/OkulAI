import 'package:flutter/material.dart';
import 'package:kresai/services/ai_schedule_service.dart';
import 'package:kresai/services/app_config_store.dart';
import 'package:kresai/services/program_store.dart';
import 'package:kresai/services/daily_plan_store.dart';
import 'package:kresai/services/registration_store.dart';
import 'package:kresai/services/activity_log_store.dart';
import 'package:kresai/models/program.dart';
import 'package:kresai/models/app_config.dart';
import 'package:kresai/models/activity_event.dart';
import 'package:kresai/theme/tokens.dart';
import 'package:kresai/screens/teacher/program_upload_screen.dart';

/// Today Plan Screen - Teacher views, edits, and approves daily instructional plans
class TodayPlanScreen extends StatefulWidget {
  const TodayPlanScreen({super.key});

  @override
  State<TodayPlanScreen> createState() => _TodayPlanScreenState();
}

class _TodayPlanScreenState extends State<TodayPlanScreen> {
  final _aiService = AiScheduleService();
  final _programStore = ProgramStore();
  final _dailyPlanStore = DailyPlanStore();
  final _registrationStore = RegistrationStore();
  final _activityLogStore = ActivityLogStore();

  bool _isLoading = true;
  bool _isGenerating = false;
  bool _isApproving = false;
  SchoolType _schoolType = SchoolType.preschool;
  String? _classId;
  String _dateKey = '';
  int _dayOfWeek = 1;
  DailyPlan? _currentPlan;
  List<ProgramBlock> _todayBlocks = [];
  List<DailyPlanBlock> _editedBlocks = [];

  @override
  void initState() {
    super.initState();
    _initializeDate();
    _loadData();
  }

  void _initializeDate() {
    final now = DateTime.now();
    _dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _dayOfWeek = now.weekday;
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    await _programStore.load();
    await _dailyPlanStore.load();
    await _registrationStore.load();
    await _activityLogStore.load();

    final config = AppConfigStore().config;
    final teacherReg = _registrationStore.getCurrentTeacherRegistration();

    if (mounted) {
      setState(() {
        _schoolType = config?.schoolType ?? SchoolType.preschool;
        _classId = teacherReg?.className;
      });

      if (_classId != null) {
        // Load today's blocks from program
        _todayBlocks = _programStore.getBlocksForDate(
          _classId!,
          dayOfWeek: _dayOfWeek,
          dateKey: _dateKey,
        );

        // Check if plan exists
        _currentPlan = _dailyPlanStore.getDraftPlan(_classId!, _dateKey);
        _currentPlan ??= _dailyPlanStore.getApprovedPlan(_classId!, _dateKey);

        if (_currentPlan != null) {
          _editedBlocks = List.from(_currentPlan!.blocks);
        }
      }

      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateDailyPlan() async {
    if (_todayBlocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bugün için program bloğu bulunamadı'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final planBlocks = await _aiService.generateDailyPlan(
        blocks: _todayBlocks,
        dateKey: _dateKey,
        schoolType: _schoolType,
      );

      if (mounted) {
        // Create draft plan
        final template = _programStore.getTemplate(_classId!);
        final plan = await _dailyPlanStore.getOrGenerateDraft(
          classId: _classId!,
          dateKey: _dateKey,
          blocks: planBlocks,
          templateVersion: template?.version ?? 1,
        );

        setState(() {
          _currentPlan = plan;
          _editedBlocks = planBlocks;
          _isGenerating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Günlük plan oluşturuldu'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _approvePlan() async {
    if (_currentPlan == null) return;

    setState(() => _isApproving = true);

    try {
      // Save edited blocks first
      final success = await _dailyPlanStore.updatePlanBlocks(
        _currentPlan!.id,
        _editedBlocks,
      );

      if (success) {
        final teacherReg = _registrationStore.getCurrentTeacherRegistration();
        await _dailyPlanStore.approvePlan(
          _currentPlan!.id,
          teacherReg?.id ?? 'unknown',
        );

        // Log activity
        await _activityLogStore.addEvent(ActivityEvent(
          id: 'event_${DateTime.now().millisecondsSinceEpoch}',
          createdAt: DateTime.now().millisecondsSinceEpoch,
          type: ActivityEventType.dailyUpdated,
          description: 'Günlük plan onaylandı: $_dateKey',
          actorRole: ActorRole.teacher,
          actorId: teacherReg?.id ?? 'unknown',
          classId: _classId,
        ));

        // Reload to get approved plan
        await _loadData();
      }

      if (mounted) {
        setState(() => _isApproving = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Plan onaylandı'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Onaylama başarısız'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isApproving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateTeacherSteps(int index, List<String> steps) {
    setState(() {
      _editedBlocks[index] = DailyPlanBlock(
        startTime: _editedBlocks[index].startTime,
        endTime: _editedBlocks[index].endTime,
        label: _editedBlocks[index].label,
        teacherSteps: steps,
        parentSummary: _editedBlocks[index].parentSummary,
      );
    });
  }

  void _updateParentSummary(int index, String summary) {
    setState(() {
      _editedBlocks[index] = DailyPlanBlock(
        startTime: _editedBlocks[index].startTime,
        endTime: _editedBlocks[index].endTime,
        label: _editedBlocks[index].label,
        teacherSteps: _editedBlocks[index].teacherSteps,
        parentSummary: summary,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bugünkü Plan'),
            Text(
              _formatDate(_dateKey),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: _currentPlan != null &&
              _currentPlan!.status == DailyPlanStatus.draft
          ? FloatingActionButton.extended(
              onPressed: _isApproving ? null : _approvePlan,
              icon: _isApproving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle),
              label: const Text('Onayla'),
            )
          : null,
    );
  }

  Widget _buildBody() {
    // Empty state: No program
    if (_todayBlocks.isEmpty && _currentPlan == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spacing24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today,
                size: 64,
                color: AppTokens.textSecondaryLight,
              ),
              const SizedBox(height: AppTokens.spacing16),
              const Text(
                'Bugün için program bloğu yok',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTokens.spacing8),
              Text(
                'Önce haftalık veya aylık programınızı yükleyin',
                style: TextStyle(color: AppTokens.textSecondaryLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTokens.spacing24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProgramUploadScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('Program Yükle'),
              ),
            ],
          ),
        ),
      );
    }

    // Program exists but no plan yet
    if (_currentPlan == null && _todayBlocks.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spacing24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 64,
                color: AppTokens.primaryLight,
              ),
              const SizedBox(height: AppTokens.spacing16),
              const Text(
                'Bugünkü planı oluştur',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppTokens.spacing8),
              Text(
                'AI ile ${_todayBlocks.length} program bloğu için detaylı plan oluşturun',
                style: TextStyle(color: AppTokens.textSecondaryLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTokens.spacing24),
              ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateDailyPlan,
                icon: _isGenerating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_isGenerating ? 'Oluşturuluyor...' : 'Plan Oluştur'),
              ),
              const SizedBox(height: AppTokens.spacing16),
              Text(
                'Bugün için ${_todayBlocks.length} program bloğu bulundu',
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

    // Plan exists - show it
    return ListView(
      padding: const EdgeInsets.all(AppTokens.spacing16),
      children: [
        // Status Banner
        _buildStatusBanner(),
        const SizedBox(height: AppTokens.spacing16),

        // Plan Blocks
        ...List.generate(_editedBlocks.length, (index) {
          final block = _editedBlocks[index];
          return _buildBlockCard(index, block);
        }),

        // Bottom padding for FAB
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildStatusBanner() {
    final isApproved = _currentPlan?.status == DailyPlanStatus.approved;
    final color = isApproved ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(AppTokens.spacing16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(
            isApproved ? Icons.check_circle : Icons.edit_note,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isApproved ? 'Onaylandı' : 'Taslak',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (isApproved && _currentPlan?.approvedAt != null)
                  Text(
                    _formatTimestamp(_currentPlan!.approvedAt!),
                    style: TextStyle(fontSize: 12, color: color),
                  ),
              ],
            ),
          ),
          if (!isApproved)
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Düzenlemeleri yapın ve onaylamak için aşağıdaki butona basın'),
                  ),
                );
              },
              child: const Text('Düzenle'),
            ),
        ],
      ),
    );
  }

  Widget _buildBlockCard(int index, DailyPlanBlock block) {
    final isApproved = _currentPlan?.status == DailyPlanStatus.approved;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTokens.spacing12),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTokens.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${block.startTime}-${block.endTime}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  block.label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(AppTokens.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Teacher Steps
                  Row(
                    children: [
                      Icon(Icons.format_list_numbered, size: 20, color: AppTokens.primaryLight),
                      const SizedBox(width: 8),
                      const Text(
                        'Öğretmen Adımları',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.spacing8),
                  if (block.teacherSteps != null)
                    ...List.generate(block.teacherSteps!.length, (stepIndex) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${stepIndex + 1}. ',
                              style: TextStyle(color: AppTokens.textSecondaryLight),
                            ),
                            Expanded(
                              child: isApproved
                                  ? Text(block.teacherSteps![stepIndex])
                                  : TextField(
                                      controller: TextEditingController(
                                        text: block.teacherSteps![stepIndex],
                                      ),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (value) {
                                        final steps = List<String>.from(block.teacherSteps!);
                                        steps[stepIndex] = value;
                                        _updateTeacherSteps(index, steps);
                                      },
                                    ),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: AppTokens.spacing16),

                  // Parent Summary
                  Row(
                    children: [
                      Icon(Icons.family_restroom, size: 20, color: AppTokens.primaryLight),
                      const SizedBox(width: 8),
                      const Text(
                        'Veli Özeti',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.spacing8),
                  isApproved
                      ? Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTokens.backgroundLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(block.parentSummary ?? 'Özet yok'),
                        )
                      : TextField(
                          controller: TextEditingController(text: block.parentSummary),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Veliler için kısa özet',
                          ),
                          maxLines: 2,
                          onChanged: (value) {
                            _updateParentSummary(index, value);
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateKey) {
    try {
      final parts = dateKey.split('-');
      final year = parts[0];
      final month = parts[1];
      final day = parts[2];
      return '$day.$month.$year ${_getDayName(_dayOfWeek)}';
    } catch (e) {
      return dateKey;
    }
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getDayName(int dayOfWeek) {
    const days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    return days[dayOfWeek - 1];
  }
}
