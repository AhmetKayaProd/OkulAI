import 'package:flutter/material.dart';
import 'package:kresai/services/code_service.dart';
import 'package:kresai/services/registration_store.dart';
import 'package:kresai/theme/tokens.dart';
import 'package:kresai/screens/parent/register_screen.dart';

/// Parent - Kod Giriş Ekranı
class ParentEnterCodeScreen extends StatefulWidget {
  const ParentEnterCodeScreen({super.key});

  @override
  State<ParentEnterCodeScreen> createState() => _ParentEnterCodeScreenState();
}

class _ParentEnterCodeScreenState extends State<ParentEnterCodeScreen> {
  final _codeController = TextEditingController();
  final _store = RegistrationStore();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _store.load();
  }

  Future<void> _validateAndContinue() async {
    final code = CodeService.normalizeCode(_codeController.text);

    if (!CodeService.validateFormat(code)) {
      _showError('Geçersiz kod formatı. Format: XXXX-9999');
      return;
    }

    setState(() => _isLoading = true);

    final isValid = _store.validateParentCode(code);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (isValid) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ParentRegisterScreen(codeUsed: code),
        ),
      );
    } else {
      _showError('Geçersiz veya iptal edilmiş kod');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.family_restroom,
              size: 80,
              color: AppTokens.primaryLight,
            ),
            const SizedBox(height: AppTokens.spacing24),
            Text(
              'Davet Kodunuzu Girin',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTokens.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.spacing8),
            Text(
              'Öğretmeninizden aldığınız davet kodunu girin',
              style: TextStyle(
                color: AppTokens.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.spacing32),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Davet Kodu',
                hintText: 'ZKTR-8841',
                prefixIcon: const Icon(Icons.vpn_key),
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                fontFamily: 'Courier',
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 9,
            ),
            const SizedBox(height: AppTokens.spacing24),
            ElevatedButton(
              onPressed: _isLoading ? null : _validateAndContinue,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Devam Et'),
            ),
          ],
        ),
      ),
    );
  }
}
