import 'package:flutter/material.dart';
import 'package:kresai/services/live_store.dart';
import 'package:kresai/services/registration_store.dart';
import 'package:kresai/models/live_session.dart';
import 'package:kresai/theme/tokens.dart';

/// Parent Live Screen
class ParentLiveScreen extends StatefulWidget {
  const ParentLiveScreen({super.key});

  @override
  State<ParentLiveScreen> createState() => _ParentLiveScreenState();
}

class _ParentLiveScreenState extends State<ParentLiveScreen> {
  final _liveStore = LiveStore();
  final _registrationStore = RegistrationStore();

  bool _isLoading = true;
  LiveSession? _activeSession;
  bool _hasConsent = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    await _liveStore.load();
    await _registrationStore.load();

    final parentReg = _registrationStore.getCurrentParentRegistration();
    if (parentReg != null && mounted) {
      // Parent consent
      _hasConsent = parentReg.photoConsent;

      // Active session (demo: 'global' classId)
      setState(() {
        _activeSession = _liveStore.getActiveSession('global');
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _watchLive() {
    if (_activeSession == null) return;

    // Consent check
    if (_activeSession!.requiresConsent && !_hasConsent) {
      // Consent yoksa placeholder göster
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const _ConsentRequiredScreen(),
        ),
      );
      return;
    }

    // Stub player ekranı
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LivePlayerStubScreen(session: _activeSession!),
      ),
    );
  }

  String _formatDuration(int startedAt) {
    final duration = DateTime.now().millisecondsSinceEpoch - startedAt;
    final seconds = duration ~/ 1000;
    final minutes = seconds ~/ 60;
    final hours = minutes ~/ 60;

    if (hours > 0) {
      return '${hours}sa ${minutes % 60}dk';
    } else if (minutes > 0) {
      return '${minutes}dk';
    } else {
      return '${seconds}sn';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Canlı (Veli)'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activeSession == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.videocam_off,
                        size: 64,
                        color: AppTokens.textSecondaryLight,
                      ),
                      const SizedBox(height: AppTokens.spacing24),
                      Text(
                        'Şu an canlı yayın yok',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppTokens.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(AppTokens.spacing16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(AppTokens.spacing24),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'CANLI',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTokens.spacing16),
                              Text(
                                _activeSession!.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppTokens.spacing8),
                              Text(
                                'Süre: ${_formatDuration(_activeSession!.startedAt)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTokens.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTokens.spacing32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _watchLive,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Canlıyı İzle'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

/// Live Player Stub Screen (V1 - placeholder only)
class LivePlayerStubScreen extends StatelessWidget {
  final LiveSession session;

  const LivePlayerStubScreen({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Canlı İzleniyor'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.videocam,
                          size: 80,
                          color: Colors.red,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'CANLI (V1 Stub)',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Gerçek video yakında...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppTokens.spacing16),
            color: Colors.black87,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'CANLI',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.spacing16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                    ),
                    child: const Text('Çık'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Consent Required Screen
class _ConsentRequiredScreen extends StatelessWidget {
  const _ConsentRequiredScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İzin Gerekli'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spacing24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: AppTokens.textSecondaryLight,
              ),
              const SizedBox(height: AppTokens.spacing24),
              const Text(
                'Canlı Yayın İçin İzin Gerekli',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTokens.spacing16),
              Text(
                'Canlı yayınları izleyebilmek için fotoğraf/video izni gereklidir.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTokens.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTokens.spacing32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tamam'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
