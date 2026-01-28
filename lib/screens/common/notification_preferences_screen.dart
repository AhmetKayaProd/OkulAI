import 'package:flutter/material.dart';
import 'package:kresai/theme/tokens.dart';

/// Notification Preferences Screen
class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  // Notification toggles (to be persisted in Firebase later)
  bool _announcementsEnabled = true;
  bool _messagesEnabled = true;
  bool _approvalsEnabled = true;
  bool _dailyPlanEnabled = true;
  bool _liveSessionEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirim Tercihleri'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.spacing16),
        children: [
          // Info Card
          Card(
            color: AppTokens.primaryLight.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.spacing16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTokens.primaryLight,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Bildirim tercihlerinizi yönetin. Kapalı kategorilerde bildirim almayacaksınız.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTokens.spacing24),
          
          // Notification Categories
          Card(
            child: Column(
              children: [
                _buildToggleTile(
                  icon: Icons.campaign,
                  title: 'Duyurular',
                  subtitle: 'Yeni duyuru bildirimlerini al',
                  value: _announcementsEnabled,
                  onChanged: (value) => setState(() => _announcementsEnabled = value),
                ),
                const Divider(height: 1),
                _buildToggleTile(
                  icon: Icons.message,
                  title: 'Mesajlar',
                  subtitle: 'Yeni mesaj bildirimlerini al',
                  value: _messagesEnabled,
                  onChanged: (value) => setState(() => _messagesEnabled = value),
                ),
                const Divider(height: 1),
                _buildToggleTile(
                  icon: Icons.check_circle,
                  title: 'Onaylar',
                  subtitle: 'Onay durumu değişikliklerini al',
                  value: _approvalsEnabled,
                  onChanged: (value) => setState(() => _approvalsEnabled = value),
                ),
                const Divider(height: 1),
                _buildToggleTile(
                  icon: Icons.calendar_today,
                  title: 'Günlük Plan',
                  subtitle: 'Günlük plan paylaşımlarını al',
                  value: _dailyPlanEnabled,
                  onChanged: (value) => setState(() => _dailyPlanEnabled = value),
                ),
                const Divider(height: 1),
                _buildToggleTile(
                  icon: Icons.videocam,
                  title: 'Canlı Yayın',
                  subtitle: 'Canlı yayın başladığında bildirim al',
                  value: _liveSessionEnabled,
                  onChanged: (value) => setState(() => _liveSessionEnabled = value),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppTokens.spacing24),
          
          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Save to Firebase/SharedPreferences
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Bildirim tercihleri kaydedildi'),
                    backgroundColor: AppTokens.successLight,
                  ),
                );
                Navigator.pop(context);
              },
              icon: const Icon(Icons.save),
              label: const Text('Kaydet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTokens.primaryLight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacing16,
        vertical: 8,
      ),
      secondary: Icon(icon, color: AppTokens.primaryLight),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}
