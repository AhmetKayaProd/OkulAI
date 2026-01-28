import 'package:flutter/material.dart';
import 'package:kresai/services/live_store.dart';
import 'package:kresai/services/registration_store.dart';
import 'package:kresai/models/live_session.dart';
import 'package:kresai/theme/tokens.dart';

/// Teacher Live Screen
class TeacherLiveScreen extends StatefulWidget {
  const TeacherLiveScreen({super.key});

  @override
  State<TeacherLiveScreen> createState() => _TeacherLiveScreenState();
}

class _TeacherLiveScreenState extends State<TeacherLiveScreen> {
  final _liveStore = LiveStore();
  final _registrationStore = RegistrationStore();

  bool _isLoading = true;
  bool _isStarting = false;
  bool _isEnding = false;
  LiveSession? _activeSession;
  String? _teacherId;
  String? _classId;
  final _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    await _liveStore.load();
    await _registrationStore.load();

    final teacherReg = _registrationStore.getCurrentTeacherRegistration();
    if (teacherReg != null && mounted) {
      _teacherId = teacherReg.id;
      _classId = teacherReg.className;

      setState(() {
        _activeSession = _liveStore.getActiveSession(_classId!);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startSession() async {
    if (_teacherId == null || _classId == null) return;

    setState(() => _isStarting = true);

    final session = await _liveStore.startSession(
      classId: _classId!,
      teacherId: _teacherId!,
      title: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : null,
      requiresConsent: true,
    );

    if (mounted) {
      setState(() {
        _activeSession = session;
        _isStarting = false;
        _titleController.clear();
      });

      if (session != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Canlı yayın başlatıldı'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _endSession() async {
    if (_activeSession == null) return;

    setState(() => _isEnding = true);

    final success = await _liveStore.endSession(_activeSession!.id);

    if (mounted) {
      setState(() {
        if (success) _activeSession = null;
        _isEnding = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Canlı yayın sonlandı'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
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
        title: const Text('Canlı (Öğretmen)'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(AppTokens.spacing16),
              child: _activeSession == null
                  ? _buildStartView()
                  : _buildActiveView(),
            ),
    );
  }

  Widget _buildStartView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.videocam_off,
          size: 64,
          color: AppTokens.textSecondaryLight,
        ),
        const SizedBox(height: AppTokens.spacing24),
        const Text(
          'Canlı yayın aktif değil',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTokens.spacing32),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Başlık (opsiyonel)',
            hintText: 'Örn: Oyun Zamanı, Kahvaltı',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppTokens.spacing24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isStarting ? null : _startSession,
            icon: _isStarting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.play_circle_filled),
            label: const Text('Canlı Yayın Başlat'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(AppTokens.spacing24),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red, width: 2),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.videocam,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: AppTokens.spacing16),
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
                  fontSize: 18,
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
        const SizedBox(height: AppTokens.spacing32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isEnding ? null : _endSession,
            icon: _isEnding
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.stop_circle),
            label: const Text('Canlıyı Bitir'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
