import 'package:flutter/material.dart';
import 'package:kresai/services/auth_service.dart';
import 'package:kresai/theme/tokens.dart';
import 'package:kresai/screens/teacher/ai_settings_screen.dart';
import 'package:kresai/screens/teacher/profile_screen.dart';
import 'package:kresai/screens/common/notification_preferences_screen.dart';
import 'package:kresai/screens/common/about_screen.dart';

/// Teacher Settings Screen
class TeacherSettingsScreen extends StatelessWidget {
  const TeacherSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.spacing16),
        children: [
          // Profile Card
          Card(
            child: ListTile(
              leading: Icon(
                Icons.person,
                color: AppTokens.primaryLight,
              ),
              title: const Text('Profil Bilgilerim'),
              subtitle: const Text('Ad, email ve sınıf bilgisi'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const TeacherProfileScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppTokens.spacing16),
          
          // Notification Preferences Card
          Card(
            child: ListTile(
              leading: Icon(
                Icons.notifications,
                color: AppTokens.primaryLight,
              ),
              title: const Text('Bildirim Tercihleri'),
              subtitle: const Text('Hangi bildirimleri almak istediğinizi seçin'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationPreferencesScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppTokens.spacing24),
          
          // AI Settings Card
          Card(
            child: ListTile(
              leading: Icon(
                Icons.auto_awesome,
                color: AppTokens.primaryLight,
              ),
              title: const Text('AI Ayarları'),
              subtitle: const Text('Gemini API ayarlarını yapılandır'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AiSettingsScreen(),
                  ),
                );
              },
            ),
          ),
          
          // About Card
          Card(
            child: ListTile(
              leading: Icon(
                Icons.info,
                color: AppTokens.primaryLight,
              ),
              title: const Text('Hakkında'),
              subtitle: const Text('Uygulama bilgileri ve versiyon'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AboutScreen(),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: AppTokens.spacing24),
          
          // Logout Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.logout,
                        color: AppTokens.errorLight,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Hesap',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.spacing16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
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
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTokens.errorLight,
                                ),
                                child: const Text('Çıkış Yap'),
                              ),
                            ],
                          ),
                        );
                        
                        if (confirm == true && context.mounted) {
                          try {
                            final authService = AuthService();
                            await authService.signOut();
                            // Auth state change will automatically navigate to Login
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Çıkış yapılamadı: ${e.toString()}'),
                                  backgroundColor: AppTokens.errorLight,
                                ),
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Çıkış Yap'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTokens.errorLight,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
