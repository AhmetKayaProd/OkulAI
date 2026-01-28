import 'package:flutter/material.dart';
import '../../services/registration_store.dart';
import '../../services/auth_service.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/modern_card.dart';
import '../../widgets/common/modern_button.dart';
import 'profile_screen.dart';
import '../common/notification_preferences_screen.dart';
import '../common/about_screen.dart';

class ParentSettingsScreen extends StatefulWidget {
  const ParentSettingsScreen({super.key});

  @override
  State<ParentSettingsScreen> createState() => _ParentSettingsScreenState();
}

class _ParentSettingsScreenState extends State<ParentSettingsScreen> {
  final _registrationStore = RegistrationStore();

  bool _isLoading = true;
  bool _photoConsent = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    await _registrationStore.load();

    final parentReg = _registrationStore.getCurrentParentRegistration();
    if (parentReg != null && mounted) {
      setState(() {
        _photoConsent = parentReg.photoConsent;
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateConsent(bool value) async {
    setState(() => _isSaving = true);

    final success = await _registrationStore.updateParentConsent(value);

    if (mounted) {
      setState(() {
        if (success) _photoConsent = value;
        _isSaving = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? '✅ Foto/Video izni açıldı' : '⚠️ Foto/Video izni kapatıldı'),
            backgroundColor: value ? AppTokens.successLight : AppTokens.warningLight,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Güncelleme başarısız'),
            backgroundColor: AppTokens.errorLight,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.backgroundLight,
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppTokens.spacing20),
              children: [
                const Text(
                  'HESAP',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTokens.textTertiaryLight, letterSpacing: 1),
                ),
                const SizedBox(height: 12),
                ModernCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _buildSettingItem(
                        context,
                        icon: Icons.person_outline_rounded,
                        title: 'Profil Bilgilerim',
                        subtitle: 'Ad, email ve öğrenci bilgisi',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentProfileScreen())),
                      ),
                      const Divider(height: 1),
                      _buildSettingItem(
                        context,
                        icon: Icons.notifications_none_rounded,
                        title: 'Bildirim Tercihleri',
                        subtitle: 'Hangi bildirimleri almak istediğinizi seçin',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationPreferencesScreen())),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.spacing32),
                const Text(
                  'GİZLİLİK',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTokens.textTertiaryLight, letterSpacing: 1),
                ),
                const SizedBox(height: 12),
                ModernCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.photo_camera_rounded, color: AppTokens.primaryLight, size: 20),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Foto/Video İzni',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Switch(
                            value: _photoConsent,
                            onChanged: _isSaving ? null : _updateConsent,
                            activeColor: AppTokens.successLight,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _photoConsent
                            ? 'Foto/video içeriklerini ve canlı yayınları görebilirsiniz.'
                            : 'Foto/video içerikleri ve canlı yayın engellenecek.',
                        style: TextStyle(
                          fontSize: 13,
                          color: _photoConsent ? AppTokens.successLight : AppTokens.textSecondaryLight,
                        ),
                      ),
                      if (!_photoConsent) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTokens.warningLight.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                            border: Border.all(color: AppTokens.warningLight.withOpacity(0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: AppTokens.warningLight, size: 18),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'İzin kapalıyken feed\'de foto/video içerikleri görüntülenemez',
                                  style: TextStyle(fontSize: 12, color: AppTokens.warningLight),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.spacing32),
                const Text(
                  'UYGULAMA',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTokens.textTertiaryLight, letterSpacing: 1),
                ),
                const SizedBox(height: 12),
                ModernCard(
                  padding: EdgeInsets.zero,
                  child: _buildSettingItem(
                    context,
                    icon: Icons.info_outline_rounded,
                    title: 'Hakkında',
                    subtitle: 'Uygulama bilgileri ve versiyon',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
                  ),
                ),
                const SizedBox(height: AppTokens.spacing48),
                ModernButton(
                  label: 'Çıkış Yap',
                  icon: Icons.logout_rounded,
                  style: ModernButtonStyle.outline,
                  color: AppTokens.errorLight,
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Çıkış Yap?'),
                        content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('İptal'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(foregroundColor: AppTokens.errorLight),
                            child: const Text('Çıkış Yap'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      try {
                        final authService = AuthService();
                        await authService.signOut();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Çıkış yapılamadı: ${e.toString()}'),
                              backgroundColor: AppTokens.errorLight,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTokens.primaryLight),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13, color: AppTokens.textSecondaryLight)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppTokens.textTertiaryLight),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
