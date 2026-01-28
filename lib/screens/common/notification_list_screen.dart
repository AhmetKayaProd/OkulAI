import 'package:flutter/material.dart';
import 'package:kresai/services/notification_store.dart';
import 'package:kresai/models/notification_item.dart';
import 'package:kresai/theme/tokens.dart';
import 'package:kresai/navigation/auth_gate.dart';

/// Notification List Screen
class NotificationListScreen extends StatefulWidget {
  final String role; // 'teacher' or 'parent'
  final String targetId;

  const NotificationListScreen({
    super.key,
    required this.role,
    required this.targetId,
  });

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  final _store = NotificationStore();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _store.load();
    setState(() => _isLoading = false);
  }

  Future<void> _onNotificationTap(NotificationItem notification) async {
    // Görüldü olarak işaretle
    await _store.markAsSeen(notification.id);

    if (!mounted) return;

    // Bildirime göre yönlendir
    if (notification.type == NotificationType.approved) {
      // Approved -> AuthGate tetikle (shell'e götürecek)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AuthGate(
            role: notification.targetRole == 'teacher'
                ? AuthRole.teacher
                : AuthRole.parent,
          ),
        ),
      );
    } else {
      // Rejected -> Rejected ekranı
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AuthGate(
            role: notification.targetRole == 'teacher'
                ? AuthRole.teacher
                : AuthRole.parent,
          ),
        ),
      );
    }
  }

  IconData _getIcon(NotificationType type) {
    return type == NotificationType.approved ? Icons.check_circle : Icons.cancel;
  }

  Color _getColor(NotificationType type) {
    return type == NotificationType.approved ? Colors.green : Colors.red;
  }

  String _getMessage(NotificationItem notification) {
    if (notification.type == NotificationType.approved) {
      return notification.targetRole == 'teacher'
          ? 'Öğretmen başvurunuz onaylandı! Sisteme giriş yapabilirsiniz.'
          : 'Veli başvurunuz onaylandı! Sisteme giriş yapabilirsiniz.';
    } else {
      return notification.targetRole == 'teacher'
          ? 'Öğretmen başvurunuz reddedildi.'
          : 'Veli başvurunuz reddedildi.';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'Az önce';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} dakika önce';
    } else if (diff.inDays < 1) {
      return '${diff.inHours} saat önce';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} gün önce';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _store.listFor(
      targetRole: widget.role,
      targetId: widget.targetId,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: AppTokens.textSecondaryLight,
                      ),
                      const SizedBox(height: AppTokens.spacing16),
                      Text(
                        'Henüz bildirimin yok',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppTokens.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppTokens.spacing16),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppTokens.spacing12),
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return Card(
                      color: notification.seen ? null : AppTokens.primaryLight.withOpacity(0.05),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getColor(notification.type).withOpacity(0.1),
                          child: Icon(
                            _getIcon(notification.type),
                            color: _getColor(notification.type),
                          ),
                        ),
                        title: Text(
                          _getMessage(notification),
                          style: TextStyle(
                            fontWeight: notification.seen ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(_formatDate(notification.createdAt)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _onNotificationTap(notification),
                      ),
                    );
                  },
                ),
    );
  }
}
