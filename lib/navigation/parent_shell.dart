import 'package:flutter/material.dart';
import 'package:kresai/screens/parent_screens.dart';
import 'package:kresai/screens/parent/home_screen.dart';
import 'package:kresai/screens/parent/daily_log_screen.dart';
import 'package:kresai/screens/parent/live_screen.dart';
import 'package:kresai/screens/parent/settings_screen.dart';
import 'package:kresai/services/notification_store.dart';
import 'package:kresai/services/registration_store.dart';
import 'package:kresai/models/notification_item.dart';
import 'package:kresai/screens/common/notification_list_screen.dart';

/// Parent Shell - 5 Tab Bottom Navigation
/// Ana Sayfa, Akış, Mesajlar, Canlı, Duyurular
class ParentShell extends StatefulWidget {
  const ParentShell({super.key});

  @override
  State<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends State<ParentShell> {
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
    
    final registration = _registrationStore.getCurrentParentRegistration();
    if (registration != null && mounted) {
      setState(() {
        _unreadCount = _notificationStore.unreadCount(
          targetRole: 'parent',
          targetId: registration.id,
        );
      });
    }
  }

  final List<Widget> _screens = const [
    ParentHomeScreen(), // Ana Sayfa
    ParentFeedScreen(),
    ParentMessagesScreen(),
    ParentLiveScreen(), // Canlı
    ParentAnnouncementsScreen(),
  ];

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
                    final registration = _registrationStore.getCurrentParentRegistration();
                    if (registration != null) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NotificationListScreen(
                            role: 'parent',
                            targetId: registration.id,
                          ),
                        ),
                      );
                      _loadUnreadCount(); // Reload after returning
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: 'Ayarlar',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ParentSettingsScreen(),
                      ),
                    );
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
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.dynamic_feed_outlined),
            selectedIcon: Icon(Icons.dynamic_feed),
            label: 'Akış',
          ),
          NavigationDestination(
            icon: Icon(Icons.message_outlined),
            selectedIcon: Icon(Icons.message),
            label: 'Mesajlar',
          ),
          NavigationDestination(
            icon: Icon(Icons.videocam_outlined),
            selectedIcon: Icon(Icons.videocam),
            label: 'Canlı',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign),
            label: 'Duyurular',
          ),
        ],
      ),
    );
  }
}
