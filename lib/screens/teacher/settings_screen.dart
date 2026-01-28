import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/modern_card.dart';
import '../../widgets/common/modern_button.dart';
import 'ai_settings_screen.dart';
import 'profile_screen.dart';
import '../common/notification_preferences_screen.dart';
import '../common/about_screen.dart';

class TeacherSettingsScreen extends StatelessWidget {
  const TeacherSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.backgroundLight,
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.spacing20),
        children: [
          const Text(
            'Hesap',
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
                  subtitle: 'Ad, email ve sınıf bilgisi',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherProfileScreen())),
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
            'Uygulama',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTokens.textTertiaryLight, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          ModernCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildSettingItem(
                  context,
                  icon: Icons.auto_awesome_outlined,
                  title: 'AI Ayarları',
                  subtitle: 'Gemini API ayarlarını yapılandır',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiSettingsScreen())),
                ),
                const Divider(height: 1),
                _buildSettingItem(
                  context,
                  icon: Icons.info_outline_rounded,
                  title: 'Hakkında',
                  subtitle: 'Uygulama bilgileri ve versiyon',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
                ),
              ],
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
