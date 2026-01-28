import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kresai/models/invite_code.dart';
import 'package:kresai/services/code_service.dart';
import 'package:kresai/services/registration_store.dart';
import 'package:kresai/theme/tokens.dart';

/// Teacher - Veli Davet Kodu Yönetimi
class TeacherParentCodeScreen extends StatefulWidget {
  const TeacherParentCodeScreen({super.key});

  @override
  State<TeacherParentCodeScreen> createState() => _TeacherParentCodeScreenState();
}

class _TeacherParentCodeScreenState extends State<TeacherParentCodeScreen> {
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
      type: InviteCodeType.parent,
      code: CodeService.generateCode(),
      isActive: true,
      createdAt: DateTime.now(),
    );

    final success = await _store.saveParentCode(newCode);
    if (!mounted) return;

    if (success) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yeni veli kodu oluşturuldu')),
      );
    }
  }

  Future<void> _deactivateCode() async {
    if (_store.parentCode == null) return;

    final updated = _store.parentCode!.copyWith(isActive: false);
    final success = await _store.saveParentCode(updated);

    if (!mounted) return;

    if (success) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kod iptal edildi')),
      );
    }
  }

  Future<void> _copyCode() async {
    if (_store.parentCode == null) return;

    await Clipboard.setData(ClipboardData(text: _store.parentCode!.code));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kod kopyalandı')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Veli Davet Kodu'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTokens.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_store.parentCode == null || !_store.parentCode!.isActive) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTokens.spacing24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.family_restroom,
                              size: 64,
                              color: AppTokens.textSecondaryLight,
                            ),
                            const SizedBox(height: AppTokens.spacing16),
                            Text(
                              'Aktif Veli Kodu Yok',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTokens.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: AppTokens.spacing8),
                            Text(
                              'Velilerin kayıt olabilmesi için bir davet kodu oluşturun.',
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
                                    _store.parentCode!.code,
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
                            '• Bu kod sınıfınızdaki tüm veliler tarafından kullanılabilir\n'
                            '• Veli başvurularını onaylamak sizin sorumluluğunuzdadır\n'
                            '• İptal ettiğinizde kod geçersiz olur',
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
