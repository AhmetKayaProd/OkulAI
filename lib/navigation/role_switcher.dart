import 'package:flutter/material.dart';
import 'package:kresai/theme/tokens.dart';
import 'package:kresai/navigation/auth_gate.dart';
import 'package:kresai/services/auth_service.dart'; // For Test Lab auto-login
import 'package:kresai/app.dart'; // For TEST_LAB_MODE

/// Rol seçim kartı widget'ı
class RoleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const RoleCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spacing24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 64,
                color: AppTokens.primaryLight,
              ),
              const SizedBox(height: AppTokens.spacing16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTokens.textPrimaryLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rol seçim ekranı - Veli / Öğretmen / Yönetici
class RoleSwitcherScreen extends StatelessWidget {
  const RoleSwitcherScreen({super.key});

  Future<void> _selectRole(BuildContext context, AuthRole role) async {
    // ⚠️ Auto-login for Test Lab Mode to ensure Firestore permissions
    if (TEST_LAB_MODE) {
      try {
        await AuthService().signInAnonymously();
      } catch (e) {
        debugPrint('Test Lab Auth Error: $e');
      }
    }

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AuthGate(role: role),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spacing24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'KresAI',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTokens.textPrimaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTokens.spacing8),
              const Text(
                'Rolünüzü Seçin',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTokens.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTokens.spacing32 * 2),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 1,
                  mainAxisSpacing: AppTokens.spacing16,
                  childAspectRatio: 2,
                  children: [
                    RoleCard(
                      title: 'Veli',
                      icon: Icons.family_restroom,
                      onTap: () => _selectRole(context, AuthRole.parent),
                    ),
                    RoleCard(
                      title: 'Öğretmen',
                      icon: Icons.school,
                      onTap: () => _selectRole(context, AuthRole.teacher),
                    ),
                    RoleCard(
                      title: 'Yönetici',
                      icon: Icons.admin_panel_settings,
                      onTap: () => _selectRole(context, AuthRole.admin),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
