import 'package:flutter/material.dart';
import 'package:kresai/theme/tokens.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// About Screen - App information and credits
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _packageInfo = info);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hakkında'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.spacing16),
        children: [
          // App Logo & Name
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.spacing24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTokens.primaryLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.school,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'KresAI',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Yapay Zeka Destekli Okul Yönetimi',
                    style: TextStyle(
                      color: AppTokens.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  if (_packageInfo != null)
                    Text(
                      'Versiyon ${_packageInfo!.version} (${_packageInfo!.buildNumber})',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTokens.textSecondaryLight,
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppTokens.spacing16),
          
          // Features
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppTokens.spacing16),
                  child: Text(
                    'Özellikler',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTokens.primaryLight,
                    ),
                  ),
                ),
                _buildFeatureTile(Icons.auto_awesome, 'AI Program Planlama'),
                _buildFeatureTile(Icons.camera_alt, 'Görsel Program Yükleme'),
                _buildFeatureTile(Icons.videocam, 'Canlı Yayın'),
                _buildFeatureTile(Icons.message, 'Mesajlaşma'),
                _buildFeatureTile(Icons.campaign, 'Duyurular'),
                _buildFeatureTile(Icons.people, 'Veli-Öğretmen Bağlantısı'),
              ],
            ),
          ),
          
          const SizedBox(height: AppTokens.spacing16),
          
          // Tech Stack
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Teknoloji',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTokens.primaryLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTechRow('Framework', 'Flutter'),
                  _buildTechRow('Backend', 'Firebase'),
                  _buildTechRow('AI Model', 'Google Gemini 2.0'),
                  _buildTechRow('Design', 'Material 3'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppTokens.spacing16),
          
          // Credits
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Geliştirici',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTokens.primaryLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'KresAI Development Team',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '© 2026 Tüm hakları saklıdır',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTokens.textSecondaryLight,
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

  Widget _buildFeatureTile(IconData icon, String title) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacing16,
        vertical: 4,
      ),
      leading: Icon(icon, color: AppTokens.primaryLight, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      dense: true,
    );
  }

  Widget _buildTechRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTokens.textSecondaryLight,
              ),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}
