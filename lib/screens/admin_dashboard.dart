import 'package:flutter/material.dart';
import 'package:kresai/services/settings_store.dart';
import 'package:kresai/theme/tokens.dart';
import 'package:kresai/screens/admin_screens.dart';
import 'package:kresai/services/registration_store.dart';
import 'package:kresai/models/registrations.dart';
import 'package:kresai/screens/admin/user_management_screen.dart';

/// Admin Dashboard Ekranı - Okul Bilgilerini Gösterir
class AdminDashboardScreenImpl extends StatefulWidget {
  const AdminDashboardScreenImpl({super.key});

  @override
  State<AdminDashboardScreenImpl> createState() => _AdminDashboardScreenImplState();
}

class _AdminDashboardScreenImplState extends State<AdminDashboardScreenImpl> {
  final _settingsStore = SettingsStore();
  final _registrationStore = RegistrationStore();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _settingsStore.load();
    await _registrationStore.load();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settingsStore.settings;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard (Yönetici)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              setState(() => _isLoading = true);
              await _loadData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTokens.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Okul Bilgileri Kartı
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTokens.spacing24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: AppTokens.primaryLight.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                                ),
                                child: const Icon(
                                  Icons.school,
                                  size: 32,
                                  color: AppTokens.primaryLight,
                                ),
                              ),
                              const SizedBox(width: AppTokens.spacing16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      settings.schoolName.isEmpty 
                                          ? 'Okul Adı Belirtilmemiş'
                                          : settings.schoolName,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppTokens.textPrimaryLight,
                                      ),
                                    ),
                                    if (settings.slogan.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        settings.slogan,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppTokens.textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: AppTokens.spacing24),
                          
                          const Divider(),
                          
                          const SizedBox(height: AppTokens.spacing16),
                          
                          // Aktif Saat Aralığı
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: AppTokens.primaryLight,
                                size: 20,
                              ),
                              const SizedBox(width: AppTokens.spacing8),
                              Text(
                                'Aktif Saat: ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTokens.textSecondaryLight,
                                ),
                              ),
                              Text(
                                settings.activeHoursFormatted,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTokens.textPrimaryLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: AppTokens.spacing16),
                  
                  // Hızlı Erişim Kartları
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTokens.spacing16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hızlı Erişim',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTokens.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: AppTokens.spacing16),
                          
                          ListTile(
                            leading: const Icon(
                              Icons.settings,
                              color: AppTokens.primaryLight,
                            ),
                            title: const Text('Okul Ayarları'),
                            subtitle: const Text('Okul bilgilerini düzenle'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AdminSchoolSettingsScreen(),
                                ),
                              ).then((_) => _loadData());
                            },
                          ),
                          
                          const Divider(),
                          
                          ListTile(
                            leading: Icon(
                              Icons.people_alt,
                              color: AppTokens.primaryLight,
                            ),
                            title: const Text('Kullanıcı Yönetimi'),
                            subtitle: Text(
                              '${_registrationStore.pendingTeachersCount + _registrationStore.pendingParentsCount} bekleyen onay',
                              style: TextStyle(
                                color: (_registrationStore.pendingTeachersCount + _registrationStore.pendingParentsCount) > 0 
                                    ? Colors.orange 
                                    : AppTokens.textSecondaryLight,
                                fontWeight: (_registrationStore.pendingTeachersCount + _registrationStore.pendingParentsCount) > 0 
                                    ? FontWeight.bold 
                                    : FontWeight.normal,
                              ),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const UserManagementScreen(),
                                ),
                              ).then((_) => _loadData());
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: AppTokens.spacing16),
                  
                  // İstatistikler
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTokens.spacing24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'İstatistikler',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTokens.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: AppTokens.spacing16),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                icon: Icons.child_care,
                                label: 'Öğrenciler',
                                value: '${_registrationStore.classRoster.length}',
                              ),
                              _buildStatItem(
                                icon: Icons.person_outline,
                                label: 'Öğretmenler',
                                value: '${_registrationStore.teacherRegistrations.where((t) => t.status == RegistrationStatus.approved).length}',
                              ),
                              _buildStatItem(
                                icon: Icons.family_restroom,
                                label: 'Veliler',
                                value: '${_registrationStore.parentRegistrations.where((p) => p.status == RegistrationStatus.approved).length}',
                              ),
                            ],
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

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: AppTokens.primaryLight,
        ),
        const SizedBox(height: AppTokens.spacing8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTokens.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTokens.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}
