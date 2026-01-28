import 'package:flutter/material.dart';
import 'package:kresai/services/registration_store.dart';
import 'package:kresai/theme/tokens.dart';

/// Admin - Teacher Approval Detail Screen
class AdminTeacherApprovalDetailScreen extends StatefulWidget {
  final String registrationId;

  const AdminTeacherApprovalDetailScreen({
    super.key,
    required this.registrationId,
  });

  @override
  State<AdminTeacherApprovalDetailScreen> createState() =>
      _AdminTeacherApprovalDetailScreenState();
}

class _AdminTeacherApprovalDetailScreenState
    extends State<AdminTeacherApprovalDetailScreen> {
  final _store = RegistrationStore();
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _store.load();
    setState(() => _isLoading = false);
  }

  Future<void> _approve() async {
    setState(() => _isProcessing = true);

    final success = await _store.approveTeacher(widget.registrationId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Öğretmen başvurusu onaylandı'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hata oluştu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _reject() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Başvuruyu Reddet'),
        content: const Text('Bu başvuruyu reddetmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reddet'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    final success = await _store.rejectTeacherRegistration(widget.registrationId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Başvuru reddedildi'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.pop(context, true);
    } else {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hata oluştu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final registration = _store.getTeacherRegistrationById(widget.registrationId);

    if (registration == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hata')),
        body: const Center(child: Text('Başvuru bulunamadı')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Başvuru Detayı'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTokens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.spacing24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: AppTokens.primaryLight.withOpacity(0.1),
                        child: const Icon(
                          Icons.person,
                          size: 40,
                          color: AppTokens.primaryLight,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTokens.spacing24),
                    _DetailRow(label: 'Ad Soyad', value: registration.fullName),
                    _DetailRow(label: 'Sınıf Adı', value: registration.className),
                    _DetailRow(label: 'Sınıf Mevcudu', value: registration.classSize.toString()),
                    _DetailRow(label: 'Kullanılan Kod', value: registration.codeUsed),
                    _DetailRow(label: 'Başvuru Tarihi', value: _formatDate(registration.createdAt)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTokens.spacing24),
            ElevatedButton(
              onPressed: _isProcessing ? null : _approve,
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Onayla'),
            ),
            const SizedBox(height: AppTokens.spacing12),
            OutlinedButton(
              onPressed: _isProcessing ? null : _reject,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Reddet'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: AppTokens.textSecondaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppTokens.textPrimaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
