import 'package:flutter/material.dart';
import 'package:kresai/models/registrations.dart';
import 'package:kresai/services/registration_store.dart';
import 'package:kresai/theme/tokens.dart';
import 'package:kresai/screens/parent/pending_approval_screen.dart';

/// Parent - Kayıt Formu Ekranı
class ParentRegisterScreen extends StatefulWidget {
  final String codeUsed;

  const ParentRegisterScreen({
    super.key,
    required this.codeUsed,
  });

  @override
  State<ParentRegisterScreen> createState() => _ParentRegisterScreenState();
}

class _ParentRegisterScreenState extends State<ParentRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _parentNameController = TextEditingController();
  final _studentNameController = TextEditingController();
  final _store = RegistrationStore();
  bool _photoConsent = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _store.load();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final registration = ParentRegistration(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      parentName: _parentNameController.text.trim(),
      studentName: _studentNameController.text.trim(),
      className: 'Papatyalar Sınıfı', // TODO: Kod üzerinden sınıf bilgisini al
      photoConsent: _photoConsent,
      codeUsed: widget.codeUsed,
      status: RegistrationStatus.pending,
      createdAt: DateTime.now(),
    );

    final error = await _store.addParentRegistration(registration);

    if (!mounted) return;

    if (error == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const ParentPendingApprovalScreen(),
        ),
      );
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _parentNameController.dispose();
    _studentNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Veli Kaydı'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTokens.spacing24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Kayıt Bilgilerinizi Girin',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTokens.textPrimaryLight,
                ),
              ),
              const SizedBox(height: AppTokens.spacing8),
              Text(
                'Öğretmen onayından sonra sisteme giriş yapabileceksiniz',
                style: TextStyle(
                  color: AppTokens.textSecondaryLight,
                ),
              ),
              const SizedBox(height: AppTokens.spacing32),
              TextFormField(
                controller: _parentNameController,
                decoration: const InputDecoration(
                  labelText: 'Veli Ad Soyad *',
                  hintText: 'Örn: Mehmet Demir',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veli adı gereklidir';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTokens.spacing16),
              TextFormField(
                controller: _studentNameController,
                decoration: const InputDecoration(
                  labelText: 'Öğrenci Ad Soyad *',
                  hintText: 'Örn: Zeynep Demir',
                  prefixIcon: Icon(Icons.child_care),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Öğrenci adı gereklidir';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTokens.spacing24),
              Card(
                child: SwitchListTile(
                  title: const Text('Fotoğraf İzni'),
                  subtitle: const Text(
                    'Çocuğumun okul etkinliklerinde çekilen fotoğraflarının '
                    'paylaşılmasına izin veriyorum',
                  ),
                  value: _photoConsent,
                  onChanged: (value) {
                    setState(() {
                      _photoConsent = value;
                    });
                  },
                ),
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
