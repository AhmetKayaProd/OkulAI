import 'package:flutter/material.dart';
import 'package:kresai/services/registration_store.dart';
import 'package:kresai/theme/tokens.dart';
import 'package:kresai/screens/teacher/parent_approval_detail_screen.dart';

/// Teacher - Parent Approvals List Screen
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
    setState(() => _isLoading = false);
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final pendingParents = _store.getPendingParents();

    return Scaffold(
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
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: AppTokens.textSecondaryLight,
                      ),
                      const SizedBox(height: AppTokens.spacing16),
                      Text(
                        'Bekleyen Başvuru Yok',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppTokens.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppTokens.spacing16),
                  itemCount: pendingParents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppTokens.spacing12),
                  itemBuilder: (context, index) {
                    final registration = pendingParents[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTokens.primaryLight.withOpacity(0.1),
                          child: const Icon(
                            Icons.family_restroom,
                            color: AppTokens.primaryLight,
                          ),
                        ),
                        title: Text(
                          registration.parentName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${registration.studentName} • ${_formatDate(registration.createdAt)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (registration.photoConsent)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Foto ✓',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TeacherParentApprovalDetailScreen(
                                registrationId: registration.id,
                              ),
                            ),
                          );

                          if (result == true && mounted) {
                            _loadData();
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
