import 'package:flutter/material.dart';
import 'package:kresai/services/registration_store.dart';
import 'package:kresai/services/app_config_store.dart';
import 'package:kresai/services/auth_service.dart';
import 'package:kresai/screens/parent/profile_screen.dart';
import 'package:kresai/screens/common/notification_preferences_screen.dart';
import 'package:kresai/screens/common/about_screen.dart';
import 'package:kresai/app.dart';
import 'package:kresai/theme/tokens.dart';

/// Parent Settings Screen
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
      setState(() => _isLoading = false);
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
            content: Text(
              value
                  ? 'Foto/Video izni açıldı'
                  : 'Foto/Video izni kapatıldı',
            ),
            backgroundColor: value ? Colors.green : Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Güncelleme başarısız'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
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
                          builder: (_) => const ParentProfileScreen(),
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
                const SizedBox(height: AppTokens.spacing16),
                
                // Foto/Video İzni Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTokens.spacing16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.photo_camera,
                              color: AppTokens.primaryLight,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Foto/Video İzni',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTokens.spacing16),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Foto/video paylaşımlarını görmek ve canlı yayına katılmak için izin veriyorum',
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _photoConsent
                                  ? 'Aktif: Foto/video içeriklerini ve canlı yayınları görebilirsiniz'
                                  : 'Kapalı: Foto/video içerikleri ve canlı yayın engellenecek',
                              style: TextStyle(
                                fontSize: 12,
                                color: _photoConsent
                                    ? Colors.green
                                    : AppTokens.textSecondaryLight,
                              ),
                            ),
                          ),
                          value: _photoConsent,
                          onChanged: _isSaving ? null : _updateConsent,
                        ),
                        if (!_photoConsent) ...[
                          const SizedBox(height: AppTokens.spacing12),
                          Container(
                            padding: const EdgeInsets.all(AppTokens.spacing12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'İzin kapalıyken feed\'de foto/video içerikleri ve canlı yayınlar görüntülenemez',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                // About Card
                const SizedBox(height: AppTokens.spacing16),
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
                
                // Logout Section
                const SizedBox(height: AppTokens.spacing24),
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
                              
                              if (confirm == true && mounted) {
                                try {
                                  final authService = AuthService();
                                  await authService.signOut();
                                  // Auth state change will automatically navigate to Login
                                } catch (e) {
                                  if (mounted) {
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
                
                // Debug reset (kDebugMode only)
                const SizedBox(height: AppTokens.spacing24),
                if (const bool.fromEnvironment('dart.vm.product') == false)
                  Card(
                    color: Colors.orange.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTokens.spacing16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.bug_report, color: Colors.orange),
                              SizedBox(width: 12),
                              Text(
                                'Debug Tools',
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
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Okul Tipini Sıfırla?'),
                                    content: const Text('Bu işlem sonrası okul tipi seçim ekranına döneceksiniz.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('İptal'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Sıfırla'),
                                      ),
                                    ],
                                  ),
                                );
                                
                                if (confirm == true && mounted) {
                                  final configStore = AppConfigStore();
                                  await configStore.resetConfigForDev();
                                  
                                  if (mounted) {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(builder: (_) => const App()),
                                      (_) => false,
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Okul Tipini Sıfırla (Debug)'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange,
                                side: const BorderSide(color: Colors.orange),
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
