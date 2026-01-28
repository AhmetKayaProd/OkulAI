import 'package:flutter/material.dart';
import 'package:kresai/services/registration_store.dart';
import 'package:kresai/theme/tokens.dart';
import 'package:kresai/screens/admin/teacher_approval_detail_screen.dart';

/// Admin - Teacher Approvals List Screen
class AdminTeacherApprovalsScreen extends StatefulWidget {
  const AdminTeacherApprovalsScreen({super.key});

  @override
  State<AdminTeacherApprovalsScreen> createState() => _AdminTeacherApprovalsScreenState();
}

class _AdminTeacherApprovalsScreenState extends State<AdminTeacherApprovalsScreen> {
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
    final pendingTeachers = _store.getPendingTeachers();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Öğretmen Onayları'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : pendingTeachers.isEmpty
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
                  itemCount: pendingTeachers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppTokens.spacing12),
                  itemBuilder: (context, index) {
                    final registration = pendingTeachers[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTokens.primaryLight.withOpacity(0.1),
                          child: const Icon(
                            Icons.person,
                            color: AppTokens.primaryLight,
                          ),
                        ),
                        title: Text(
                          registration.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${registration.className} • ${_formatDate(registration.createdAt)}',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminTeacherApprovalDetailScreen(
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
