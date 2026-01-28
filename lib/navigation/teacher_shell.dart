import 'package:flutter/material.dart';
import 'package:kresai/screens/teacher_screens.dart';
import 'package:kresai/screens/teacher/parent_code_screen.dart';
import 'package:kresai/screens/teacher/parent_approvals_screen.dart';
import 'package:kresai/screens/teacher/share_screen.dart';
import 'package:kresai/screens/teacher/daily_log_screen.dart';
import 'package:kresai/screens/teacher/live_screen.dart';
import 'package:kresai/screens/teacher/program_upload_screen.dart';
import 'package:kresai/screens/teacher/today_plan_screen.dart';
import 'package:kresai/screens/teacher/ai_settings_screen.dart';
import 'package:kresai/screens/teacher/settings_screen.dart';
import 'package:kresai/screens/teacher/homework_management_screen.dart'; // ÖdevAI
import 'package:kresai/screens/teacher/exam_management_screen.dart'; // SınavAI
import 'package:kresai/services/notification_store.dart';
import 'package:kresai/services/registration_store.dart';
import 'package:kresai/models/notification_item.dart';
import 'package:kresai/screens/common/notification_list_screen.dart';

/// Teacher Shell - 5 Tab Bottom Navigation
/// Bugün, Akış, ÖdevAI, Duyuru, Mesajlar
class TeacherShell extends StatefulWidget {
  const TeacherShell({super.key});

  @override
  State<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends State<TeacherShell> {
  int _currentIndex = 0;
  final _notificationStore = NotificationStore();
  final _registrationStore = RegistrationStore();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    await _notificationStore.load();
    await _registrationStore.load();
    
    final registration = _registrationStore.getCurrentTeacherRegistration();
    if (registration != null && mounted) {
      setState(() {
        _unreadCount = _notificationStore.unreadCount(
          targetRole: 'teacher',
          targetId: registration.id,
        );
      });
    }
  }

  final _feedScreenKey = GlobalKey<TeacherFeedScreenState>();

  late final List<Widget> _screens = [
    const TeacherDailyLogScreen(), // Bugün yerine Günlük
    TeacherFeedScreen(key: _feedScreenKey),
    const TeacherLiveScreen(), // Canlı
    const TeacherAnnouncementsScreen(),
    const TeacherMessagesScreen(),
  ];

  void _showAiProgramMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // SınavAI - NEW!
            ListTile(
              leading: const Icon(Icons.quiz, color: Colors.blue),
              title: const Text('SınavAI'),
              subtitle: const Text('AI destekli sınav oluştur ve yönet'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ExamManagementScreen(),
                  ),
                );
              },
            ),
            // ÖdevAI - Placeholder (not implemented yet)
            ListTile(
              leading: const Icon(Icons.assignment, color: Colors.orange),
              title: const Text('ÖdevAI'),
              subtitle: const Text('AI destekli ödev oluştur ve yönet'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HomeworkManagementScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Program Yükle'),
              subtitle: const Text('Haftalık/Aylık program yükle'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProgramUploadScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.today),
              title: const Text('Bugünkü Plan'),
              subtitle: const Text('Günlük planı görüntüle/onayla'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TodayPlanScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('AI Ayarları'),
              subtitle: const Text('Gemini API key ayarla'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AiSettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 0
          ? AppBar(
              title: const Text('Bugün'),
              actions: [
                IconButton(
                  icon: Badge(
                    isLabelVisible: _unreadCount > 0,
                    label: Text(_unreadCount.toString()),
                    child: const Icon(Icons.notifications),
                  ),
                  tooltip: 'Bildirimler',
                  onPressed: () async {
                    final registration = _registrationStore.getCurrentTeacherRegistration();
                    if (registration != null) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NotificationListScreen(
                            role: 'teacher',
                            targetId: registration.id,
                          ),
                        ),
                      );
                      _loadUnreadCount(); // Reload after returning
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.how_to_reg),
                  tooltip: 'Veli Onayları',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TeacherParentApprovalsScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.vpn_key),
                  tooltip: 'Veli Kodu',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TeacherParentCodeScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.auto_awesome),
                  tooltip: 'AI Program',
                  onPressed: () => _showAiProgramMenu(context),
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: 'Ayarlar',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TeacherSettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            )
          : _currentIndex == 1  // Feed tab
              ? AppBar(
                  title: const Text('Akış'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'Paylaş',
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TeacherShareScreen(),
                          ),
                        );
                        if (result == true && mounted) {
                          // Feed refresh için direkt refreshFeed çağır
                          _feedScreenKey.currentState?.refreshFeed();
                        }
                      },
                    ),
                  ],
                )
              : null,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Bugün',
          ),
          NavigationDestination(
            icon: Icon(Icons.dynamic_feed_outlined),
            selectedIcon: Icon(Icons.dynamic_feed),
            label: 'Akış',
          ),
          NavigationDestination(
            icon: Icon(Icons.videocam_outlined),
            selectedIcon: Icon(Icons.videocam),
            label: 'Canlı',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign),
            label: 'Duyuru',
          ),
          NavigationDestination(
            icon: Icon(Icons.message_outlined),
            selectedIcon: Icon(Icons.message),
            label: 'Mesajlar',
          ),
        ],
      ),
    );
  }
}
