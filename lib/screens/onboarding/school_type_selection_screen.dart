import 'package:flutter/material.dart';
import 'package:kresai/models/app_config.dart';
import 'package:kresai/services/app_config_store.dart';
import 'package:kresai/navigation/role_switcher.dart';
import 'package:kresai/theme/tokens.dart';

/// School Type Selection Screen (Onboarding)
class SchoolTypeSelectionScreen extends StatefulWidget {
  const SchoolTypeSelectionScreen({super.key});

  @override
  State<SchoolTypeSelectionScreen> createState() => _SchoolTypeSelectionScreenState();
}

class _SchoolTypeSelectionScreenState extends State<SchoolTypeSelectionScreen> {
  final _configStore = AppConfigStore();
  SchoolType? _selectedType;
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_selectedType == null) return;

    setState(() => _isSubmitting = true);

    final success = await _configStore.setSchoolTypeOnce(_selectedType!);

    if (mounted) {
      if (success) {
        // RoleSwitcher'a yönlendir (back ile dönülemesin)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const RoleSwitcherScreen(),
          ),
        );
      } else {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bir hata oluştu'),
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
        title: const Text('OkulAI Kurulumu'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTokens.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Okul Türünü Seçin',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.spacing8),
            Text(
              'Bu seçim sonradan değiştirilemez',
              style: TextStyle(
                fontSize: 14,
                color: AppTokens.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.spacing32),
            Expanded(
              child: ListView(
                children: [
                  _buildSchoolTypeCard(
                    type: SchoolType.preschool,
                    title: 'Kreş',
                    description: '0-3 yaş kreş yönetimi için optimize edilmiştir',
                    icon: Icons.child_care,
                  ),
                  const SizedBox(height: AppTokens.spacing16),
                  _buildSchoolTypeCard(
                    type: SchoolType.kindergarten,
                    title: 'Anaokulu',
                    description: '3-6 yaş anaokulu yönetimi için optimize edilmiştir',
                    icon: Icons.school,
                  ),
                  const SizedBox(height: AppTokens.spacing16),
                  _buildSchoolTypeCard(
                    type: SchoolType.primaryPrivate,
                    title: 'Özel İlkokul',
                    description: '6-10 yaş özel ilkokul yönetimi için optimize edilmiştir',
                    icon: Icons.menu_book,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.spacing24),
            ElevatedButton(
              onPressed: (_selectedType != null && !_isSubmitting) ? _submit : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Devam'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolTypeCard({
    required SchoolType type,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedType == type;

    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? AppTokens.primaryLight.withOpacity(0.1) : null,
      child: InkWell(
        onTap: _isSubmitting
            ? null
            : () {
                setState(() => _selectedType = type);
              },
        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spacing16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTokens.primaryLight
                      : AppTokens.primaryLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: isSelected ? Colors.white : AppTokens.primaryLight,
                ),
              ),
              const SizedBox(width: AppTokens.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppTokens.primaryLight : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTokens.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AppTokens.primaryLight,
                  size: 32,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
