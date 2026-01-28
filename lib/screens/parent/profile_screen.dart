import 'package:flutter/material.dart';
import 'package:kresai/services/auth_service.dart';
import 'package:kresai/services/registration_store.dart';
import 'package:kresai/theme/tokens.dart';

/// Parent Profile Settings Screen
class ParentProfileScreen extends StatefulWidget {
  const ParentProfileScreen({super.key});

  @override
  State<ParentProfileScreen> createState() => _ParentProfileScreenState();
}

class _ParentProfileScreenState extends State<ParentProfileScreen> {
  final _registrationStore = RegistrationStore();
  final _authService = AuthService();
  
  String? _fullName;
  String? _email;
  String? _studentName;
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
    final registration = _registrationStore.getCurrentParentRegistration();
    
    if (mounted) {
      setState(() {
        _fullName = registration?.parentName;
        _email = currentUser?.email;
        _studentName = registration?.studentName;
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
                                _fullName?.substring(0, 1).toUpperCase() ?? 'V',
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
                                    _fullName ?? 'Veli',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _studentName ?? 'Öğrenci atanmadı',
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
                        _buildInfoRow(Icons.child_care, 'Öğrenci', _studentName ?? 'Atanmadı'),
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
