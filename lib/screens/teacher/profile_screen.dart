import 'package:flutter/material.dart';
import 'package:kresai/services/auth_service.dart';
import 'package:kresai/services/registration_store.dart';
import 'package:kresai/theme/tokens.dart';

/// Teacher Profile Settings Screen
class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  final _registrationStore = RegistrationStore();
  final _authService = AuthService();
  
  String? _fullName;
  String? _email;
  String? _className;
  int? _classSize;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    await _registrationStore.load();
    final currentUser = _authService.getCurrentUser();
    final registration = _registrationStore.getCurrentTeacherRegistration();
    
    if (mounted) {
      setState(() {
        _fullName = registration?.fullName;
        _email = currentUser?.email;
        _className = registration?.className;
        _classSize = registration?.classSize;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppTokens.spacing16),
              children: [
                // Profile Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTokens.spacing16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: AppTokens.primaryLight,
                              child: Text(
                                _fullName?.substring(0, 1).toUpperCase() ?? 'Ö',
                                style: const TextStyle(
                                  fontSize: 32,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _fullName ?? 'Öğretmen',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _className ?? 'Sınıf bilgisi yok',
                                    style: TextStyle(
                                      color: AppTokens.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        _buildInfoRow(Icons.email, 'Email', _email ?? 'Kayıtlı değil'),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.school, 'Sınıf', _className ?? 'Atanmadı'),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.people, 'Öğrenci Sayısı', _classSize?.toString() ?? '0'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTokens.primaryLight),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTokens.textSecondaryLight,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
