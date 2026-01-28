import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/invite_code.dart';
import '../../services/code_service.dart';
import '../../services/registration_store.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/modern_card.dart';
import '../../widgets/common/modern_button.dart';

class AdminTeacherCodeScreen extends StatefulWidget {
  const AdminTeacherCodeScreen({super.key});

  @override
  State<AdminTeacherCodeScreen> createState() => _AdminTeacherCodeScreenState();
}

class _AdminTeacherCodeScreenState extends State<AdminTeacherCodeScreen> {
  final _store = RegistrationStore();
  bool _isLoading = true;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _store.load();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _generateCode() async {
    setState(() => _isGenerating = true);
    
    final newCode = InviteCode(
      type: InviteCodeType.teacher,
      code: CodeService.generateCode(),
      schoolId: 'admin_school',
      isActive: true,
      createdAt: DateTime.now(),
    );

    final success = await _store.saveTeacherCode(newCode);
    
    if (mounted) {
      setState(() => _isGenerating = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Yeni öğretmen kodu oluşturuldu'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTokens.successLight,
          ),
        );
      }
    }
  }

  Future<void> _deactivateCode() async {
    if (_store.teacherCode == null) return;

    final updated = _store.teacherCode!.copyWith(isActive: false);
    final success = await _store.saveTeacherCode(updated);

    if (mounted && success) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Kod iptal edildi'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _copyCode() async {
    if (_store.teacherCode == null) return;

    await Clipboard.setData(ClipboardData(text: _store.teacherCode!.code));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Kod kopyalandı'),
        behavior: SnackBarBehavior.floating,
      ),
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
              padding: const EdgeInsets.all(AppTokens.spacing20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusHeader(),
                  const SizedBox(height: AppTokens.spacing24),
                  if (_store.teacherCode == null || !_store.teacherCode!.isActive)
                    _buildEmptyState()
                  else
                    _buildActiveCodeCard(),
                  const SizedBox(height: AppTokens.spacing24),
                  _buildInfoCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusHeader() {
    final isActive = _store.teacherCode != null && _store.teacherCode!.isActive;
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isActive ? AppTokens.successLight : AppTokens.textTertiaryLight,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppTokens.spacing8),
        Text(
          isActive ? 'Aktif Kod Mevcut' : 'Aktif Kod Yok',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTokens.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return ModernCard(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.spacing48, horizontal: AppTokens.spacing24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTokens.spacing20),
            decoration: const BoxDecoration(
              color: AppTokens.primaryLightSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.vpn_key_outlined, size: 40, color: AppTokens.primaryLight),
          ),
          const SizedBox(height: AppTokens.spacing24),
          const Text(
            'Yeni Kod Gerekli',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTokens.spacing8),
          const Text(
            'Öğretmenlerin sisteme kayıt olabilmesi için bir davet kodu oluşturmanız gerekmektedir.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTokens.textSecondaryLight),
          ),
          const SizedBox(height: AppTokens.spacing32),
          ModernButton(
            label: 'Davet Kodu Oluştur',
            icon: Icons.add,
            isLoading: _isGenerating,
            onPressed: _generateCode,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCodeCard() {
    return Column(
      children: [
        ModernCard(
          padding: const EdgeInsets.all(AppTokens.spacing24),
          child: Column(
            children: [
              const Text(
                'GÜNCEL DAVET KODU',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: AppTokens.textTertiaryLight,
                ),
              ),
              const SizedBox(height: AppTokens.spacing16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppTokens.spacing20),
                decoration: BoxDecoration(
                  color: AppTokens.backgroundLight,
                  borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                ),
                child: Center(
                  child: Text(
                    _store.teacherCode!.code,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      color: AppTokens.primaryLight,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.spacing24),
              Row(
                children: [
                  Expanded(
                    child: ModernButton(
                      label: 'Kopyala',
                      icon: Icons.copy_rounded,
                      style: ModernButtonStyle.secondary,
                      onPressed: _copyCode,
                    ),
                  ),
                  const SizedBox(width: AppTokens.spacing12),
                  Expanded(
                    child: ModernButton(
                      label: 'Yenile',
                      icon: Icons.refresh_rounded,
                      style: ModernButtonStyle.outline,
                      onPressed: _generateCode,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.spacing16),
        ModernButton(
          label: 'Kodu İptal Et',
          icon: Icons.block_flipped,
          style: ModernButtonStyle.ghost,
          color: AppTokens.errorLight,
          onPressed: _deactivateCode,
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return ModernCard(
      color: AppTokens.primaryLightSoft.withOpacity(0.5),
      border: const BorderSide(color: AppTokens.primaryLightSoft),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppTokens.primaryLight, size: 20),
          const SizedBox(width: AppTokens.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Güvenlik Notu',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTokens.primaryLight),
                ),
                SizedBox(height: AppTokens.spacing4),
                Text(
                  'Bu kod paylaşıldığı sürece tüm öğretmenler tarafından kullanılabilir. Yeni bir kod oluşturduğunuzda eski kod otomatik olarak geçersiz sayılır.',
                  style: TextStyle(fontSize: 13, color: AppTokens.textSecondaryLight, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
