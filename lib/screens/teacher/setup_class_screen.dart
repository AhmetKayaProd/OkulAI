import 'package:flutter/material.dart';
import 'package:kresai/models/registrations.dart';
import 'package:kresai/services/registration_store.dart';
import 'package:kresai/theme/tokens.dart';
import 'package:kresai/screens/teacher/pending_approval_screen.dart';

/// Teacher - Sınıf Bilgileri Kurulum Ekranı
class TeacherSetupClassScreen extends StatefulWidget {
  final String codeUsed;

  const TeacherSetupClassScreen({
    super.key,
    required this.codeUsed,
  });

  @override
  State<TeacherSetupClassScreen> createState() => _TeacherSetupClassScreenState();
}

class _TeacherSetupClassScreenState extends State<TeacherSetupClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _classNameController = TextEditingController();
  final _classSizeController = TextEditingController();
  final _store = RegistrationStore();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final registration = TeacherRegistration(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fullName: _fullNameController.text.trim(),
      className: _classNameController.text.trim(),
      classSize: int.parse(_classSizeController.text.trim()),
      codeUsed: widget.codeUsed,
      status: RegistrationStatus.pending,
      createdAt: DateTime.now(),
    );

    final success = await _store.addTeacherRegistration(registration);

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const TeacherPendingApprovalScreen(),
        ),
      );
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kayıt hatası'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _classNameController.dispose();
    _classSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sınıf Bilgileri'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTokens.spacing24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sınıf Bilgilerinizi Girin',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTokens.textPrimaryLight,
                ),
              ),
              const SizedBox(height: AppTokens.spacing8),
              Text(
                'Bu bilgiler yönetici onayına gönderilecektir',
                style: TextStyle(
                  color: AppTokens.textSecondaryLight,
                ),
              ),
              const SizedBox(height: AppTokens.spacing32),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad *',
                  hintText: 'Örn: Ayşe Yılmaz',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ad soyad gereklidir';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTokens.spacing16),
              TextFormField(
                controller: _classNameController,
                decoration: const InputDecoration(
                  labelText: 'Sınıf Adı *',
                  hintText: 'Örn: 3-A',
                  prefixIcon: Icon(Icons.class_),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Sınıf adı gereklidir';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTokens.spacing16),
              TextFormField(
                controller: _classSizeController,
                decoration: const InputDecoration(
                  labelText: 'Sınıf Mevcudu *',
                  hintText: 'Örn: 25',
                  prefixIcon: Icon(Icons.people),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Mevcüt sayısı gereklidir';
                  }
                  final number = int.tryParse(value.trim());
                  if (number == null || number <= 0) {
                    return 'Geçerli bir sayı girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTokens.spacing32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Başvuruyu Gönder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
