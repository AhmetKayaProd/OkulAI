import 'package:flutter/material.dart';
import 'package:kresai/theme/tokens.dart';

/// Rejected Screen - Başvuru Reddedildi
class RejectedScreen extends StatelessWidget {
  final String role; // 'teacher' veya 'parent'

  const RejectedScreen({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final isTeacher = role == 'teacher';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Başvuru Sonucu'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTokens.spacing24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 60,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: AppTokens.spacing24),
              Text(
                'Başvurunuz Reddedildi',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTokens.textPrimaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTokens.spacing16),
              Text(
                isTeacher
                    ? 'Öğretmen başvurunuz yönetici tarafından reddedildi. '
                        'Detaylı bilgi için lütfen okul yönetimiyle iletişime geçin.'
                    : 'Veli başvurunuz öğretmen tarafından reddedildi. '
                        'Detaylı bilgi için lütfen sınıf öğretmeniyle iletişime geçin.',
                style: TextStyle(
                  color: AppTokens.textSecondaryLight,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTokens.spacing32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  );
                },
                child: const Text('Ana Sayfaya Dön'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
