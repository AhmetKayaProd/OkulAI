import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kresai/models/invite_code.dart';
import 'package:kresai/services/code_service.dart';
import 'package:kresai/services/registration_store.dart';
import 'package:kresai/theme/tokens.dart';

/// Admin - Teacher Invite Code Yönetimi
class AdminTeacherCodeScreen extends StatefulWidget {
  const AdminTeacherCodeScreen({super.key});

  @override
  State<AdminTeacherCodeScreen> createState() => _AdminTeacherCodeScreenState();
}

class _AdminTeacherCodeScreenState extends State<AdminTeacherCodeScreen> {
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

  Future<void> _generateCode() async {
    final newCode = InviteCode(
      type: InviteCodeType.teacher,
      code: CodeService.generateCode(),
      isActive: true,
      createdAt: DateTime.now(),
    );

    final success = await _store.saveTeacherCode(newCode);
    if (!mounted) return;

    if (success) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yeni kod oluşturuldu')),
      );
    }
  }

  Future<void> _deactivateCode() async {
    if (_store.teacherCode == null) return;

    final updated = _store.teacherCode!.copyWith(isActive: false);
    final success = await _store.saveTeacherCode(updated);

    if (!mounted) return;

    if (success) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kod iptal edildi')),
      );
    }
  }

  Future<void> _copyCode() async {
    if (_store.teacherCode == null) return;

    await Clipboard.setData(ClipboardData(text: _store.teacherCode!.code));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kod kopyalandı')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Öğretmen Davet Kodu'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTokens.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_store.teacherCode == null || !_store.teacherCode!.isActive) ...[
                    // Kod yok veya iptal edilmiş
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTokens.spacing24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.vpn_key,
                              size: 64,
                              color: AppTokens.textSecondaryLight,
                            ),
                            const SizedBox(height: AppTokens.spacing16),
                            Text(
                              'Aktif Öğretmen Kodu Yok',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTokens.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: AppTokens.spacing8),
                            Text(
                              'Yeni öğretmenlerin kayıt olabilmesi için bir davet kodu oluşturun.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTokens.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: AppTokens.spacing24),
                            ElevatedButton.icon(
                              onPressed: _generateCode,
                              icon: const Icon(Icons.add),
                              label: const Text('Kod Üret'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    // Aktif kod var
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTokens.spacing24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Aktif Davet Kodu',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTokens.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: AppTokens.spacing16),
                            Container(
                              padding: const EdgeInsets.all(AppTokens.spacing16),
                              decoration: BoxDecoration(
                                color: AppTokens.backgroundLight,
                                borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                                border: Border.all(color: AppTokens.primaryLight, width: 2),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _store.teacherCode!.code,
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Courier',
                                      color: AppTokens.primaryLight,
                                      letterSpacing: 4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppTokens.spacing24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _copyCode,
                                    icon: const Icon(Icons.copy),
                                    label: const Text('Kopyala'),
                                  ),
                                ),
                                const SizedBox(width: AppTokens.spacing8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _generateCode,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Yenile'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTokens.spacing8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _deactivateCode,
                                icon: const Icon(Icons.block),
                                label: const Text('İptal Et'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: AppTokens.spacing16),
                  
                  // Bilgilendirme
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTokens.spacing16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppTokens.primaryLight,
                                size: 20,
                              ),
                              const SizedBox(width: AppTokens.spacing8),
                              Text(
                                'Bilgi',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTokens.textPrimaryLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTokens.spacing8),
                          Text(
                            '• Bu kod tüm öğretmenler tarafından kullanılabilir\n'
                            '• Kodu paylaştığınız herkes öğretmen kaydı yapabilir\n'
                            '• İptal ettiğinizde kod geçersiz olur\n'
                            '• Yenilediğinizde eski kod iptal olur, yeni kod oluşur',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTokens.textSecondaryLight,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
