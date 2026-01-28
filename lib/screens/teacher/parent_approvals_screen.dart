import 'package:flutter/material.dart';
import '../../services/registration_store.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/modern_card.dart';
import 'parent_approval_detail_screen.dart';

class TeacherParentApprovalsScreen extends StatefulWidget {
  const TeacherParentApprovalsScreen({super.key});

  @override
  State<TeacherParentApprovalsScreen> createState() => _TeacherParentApprovalsScreenState();
}

class _TeacherParentApprovalsScreenState extends State<TeacherParentApprovalsScreen> {
  final _store = RegistrationStore();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _store.load();
    if (mounted) setState(() => _isLoading = false);
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final pendingParents = _store.getPendingParents();

    return Scaffold(
      backgroundColor: AppTokens.backgroundLight,
      appBar: AppBar(
        title: const Text('Veli Onayları'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : pendingParents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTokens.spacing24),
                        decoration: const BoxDecoration(
                          color: AppTokens.primaryLightSoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_outline_rounded, size: 64, color: AppTokens.primaryLight),
                      ),
                      const SizedBox(height: AppTokens.spacing24),
                      const Text(
                        'Bekleyen Başvuru Yok',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTokens.textPrimaryLight),
                      ),
                      const SizedBox(height: AppTokens.spacing8),
                      const Text(
                        'Tüm veli başvuruları işlenmiş durumda.',
                        style: TextStyle(color: AppTokens.textSecondaryLight),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTokens.spacing16),
                      color: AppTokens.warningLight.withOpacity(0.1),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppTokens.warningLight, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${pendingParents.length} veli başvurusu onay bekliyor',
                              style: const TextStyle(fontWeight: FontWeight.w600, color: AppTokens.textPrimaryLight),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppTokens.spacing20),
                        itemCount: pendingParents.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppTokens.spacing16),
                        itemBuilder: (context, index) {
                          final registration = pendingParents[index];
                          return ModernCard(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TeacherParentApprovalDetailScreen(registration: registration),
                                ),
                              );
                              _loadData();
                            },
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: const BoxDecoration(
                                    color: AppTokens.primaryLightSoft,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.family_restroom_rounded, color: AppTokens.primaryLight, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        registration.parentName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.child_care_rounded, size: 14, color: AppTokens.textTertiaryLight),
                                          const SizedBox(width: 4),
                                          Text(
                                            registration.studentName,
                                            style: const TextStyle(color: AppTokens.textSecondaryLight, fontSize: 13),
                                          ),
                                          const SizedBox(width: 12),
                                          const Icon(Icons.calendar_today_rounded, size: 14, color: AppTokens.textTertiaryLight),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatDate(registration.createdAt),
                                            style: const TextStyle(color: AppTokens.textSecondaryLight, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (registration.photoConsent)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTokens.successLight.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.photo_camera_rounded, size: 12, color: AppTokens.successLight),
                                        SizedBox(width: 4),
                                        Text('İzin', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTokens.successLight)),
                                      ],
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right_rounded, color: AppTokens.textTertiaryLight),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
