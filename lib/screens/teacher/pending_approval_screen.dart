import 'package:flutter/material.dart';
import 'package:kresai/services/registration_store.dart';
import 'package:kresai/theme/tokens.dart';
import 'package:kresai/navigation/auth_gate.dart';

/// Teacher - Onay Bekleme Ekranı
class TeacherPendingApprovalScreen extends StatefulWidget {
  const TeacherPendingApprovalScreen({super.key});

  @override
  State<TeacherPendingApprovalScreen> createState() => _TeacherPendingApprovalScreenState();
}

class _TeacherPendingApprovalScreenState extends State<TeacherPendingApprovalScreen> {
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

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    await _store.load();
    
    if (!mounted) return;
    
    // AuthGate'i tetikle
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const AuthGate(role: AuthRole.teacher),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final registration = _store.getCurrentTeacherRegistration();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kayıt Durumu'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTokens.spacing24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.hourglass_empty,
                        size: 60,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: AppTokens.spacing24),
                    Text(
                      'Yönetici Onayı Bekleniyor',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTokens.textPrimaryLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTokens.spacing16),
                    Text(
                      'Başvurunuz alındı. Okul yöneticisi başvurunuzu '
                      'inceledikten sonra sisteme giriş yapabileceksiniz.',
                      style: TextStyle(
                        color: AppTokens.textSecondaryLight,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTokens.spacing32),
                    if (registration != null) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppTokens.spacing16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Başvuru Bilgileri',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTokens.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: AppTokens.spacing12),
                              _InfoRow(label: 'Ad Soyad', value: registration.fullName),
                              _InfoRow(label: 'Sınıf', value: registration.className),
                              _InfoRow(label: 'Mevcüt', value: registration.classSize.toString()),
                              _InfoRow(
                                label: 'Tarih',
                                value: _formatDate(registration.createdAt),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppTokens.spacing24),
                    ElevatedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Durumu Yenile'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTokens.textSecondaryLight,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTokens.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
