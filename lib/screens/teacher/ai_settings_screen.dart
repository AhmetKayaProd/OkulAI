import 'package:flutter/material.dart';
import 'package:kresai/services/ai_config_store.dart';
import 'package:kresai/services/ai_schedule_service.dart';
import 'package:kresai/theme/tokens.dart';

/// AI Settings Screen - Gemini API key configuration
class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  final _configStore = AiConfigStore();
  final _aiService = AiScheduleService();
  final _apiKeyController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    await _configStore.load();
    if (mounted) {
      _apiKeyController.text = _configStore.config?.geminiApiKey ?? '';
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    final key = _apiKeyController.text.trim();
    
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API key boş olamaz'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final success = await _configStore.setApiKey(key);

    if (mounted) {
      setState(() => _isSaving = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API key kaydedildi'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kayıt başarısız'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _test() async {
    if (!_aiService.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Önce API key kaydedin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('API test: Minimal program parsing denemesi yapılacak'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Ayarları'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTokens.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTokens.spacing16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gemini API Key',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppTokens.spacing8),
                          Text(
                            'Google AI Studio\'dan ücretsiz API key alabilirsiniz:\naistudio.google.com',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTokens.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: AppTokens.spacing16),
                          TextField(
                            controller: _apiKeyController,
                            decoration: InputDecoration(
                              labelText: 'API Key',
                              hintText: 'AIza...',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureKey ? Icons.visibility : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() => _obscureKey = !_obscureKey);
                                },
                              ),
                            ),
                            obscureText: _obscureKey,
                            maxLines: 1,
                          ),
                          const SizedBox(height: AppTokens.spacing16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _save,
                                  child: _isSaving
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Kaydet'),
                                ),
                              ),
                              const SizedBox(width: AppTokens.spacing12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _test,
                                  child: const Text('Test Et'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTokens.spacing16),
                  Card(
                    color: Colors.blue.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTokens.spacing16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue),
                              SizedBox(width: 12),
                              Text(
                                'Nasıl Kullanılır?',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTokens.spacing12),
                          Text(
                            '1. aistudio.google.com adresine gidin\n'
                            '2. "Get API Key" butonuna tıklayın\n'
                            '3. API key\'i kopyalayın\n'
                            '4. Buraya yapıştırıp kaydedin\n'
                            '5. Program yükleme ekranından haftalık/aylık programınızı yükleyin',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTokens.textSecondaryLight,
                            ),
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

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }
}
