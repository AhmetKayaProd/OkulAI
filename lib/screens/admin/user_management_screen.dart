import 'package:flutter/material.dart';
import 'package:kresai/models/registrations.dart';
import 'package:kresai/services/registration_store.dart';
import 'package:kresai/theme/tokens.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _registrationStore = RegistrationStore();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    await _registrationStore.load();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanıcı Yönetimi'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Öğretmenler'),
            Tab(text: 'Veliler'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTeacherList(),
                _buildParentList(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add manual user creation
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Manuel kullanıcı ekleme yakında...')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTeacherList() {
    final teachers = _registrationStore.teacherRegistrations;
    if (teachers.isEmpty) {
      return const Center(child: Text('Kayıtlı öğretmen yok'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTokens.spacing16),
      itemCount: teachers.length,
      itemBuilder: (context, index) {
        final teacher = teachers[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTokens.primaryLight.withOpacity(0.1),
              child: Text(teacher.fullName[0].toUpperCase()),
            ),
            title: Text(teacher.fullName),
            subtitle: Text('${teacher.className} (${teacher.classSize} öğrenci)'),
            trailing: _buildStatusChip(teacher.status, teacher.id, true),
          ),
        );
      },
    );
  }

  Widget _buildParentList() {
    final parents = _registrationStore.parentRegistrations;
    if (parents.isEmpty) {
      return const Center(child: Text('Kayıtlı veli yok'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTokens.spacing16),
      itemCount: parents.length,
      itemBuilder: (context, index) {
        final parent = parents[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.withOpacity(0.1),
              child: Text(parent.parentName[0].toUpperCase()),
            ),
            title: Text(parent.parentName),
            subtitle: Text('Öğrenci: ${parent.studentName}'),
            trailing: _buildStatusChip(parent.status, parent.id, false),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(RegistrationStatus status, String id, bool isTeacher) {
    Color color;
    String label;

    switch (status) {
      case RegistrationStatus.pending:
        color = Colors.orange;
        label = 'Bekliyor';
        break;
      case RegistrationStatus.approved:
        color = Colors.green;
        label = 'Onaylı';
        break;
      case RegistrationStatus.rejected:
        color = Colors.red;
        label = 'Red';
        break;
    }

    if (status == RegistrationStatus.pending) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.green),
            onPressed: () => _approveUser(id, isTeacher),
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red),
            onPressed: () => _rejectUser(id, isTeacher),
          ),
        ],
      );
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }

  Future<void> _approveUser(String id, bool isTeacher) async {
    bool success;
    if (isTeacher) {
      success = await _registrationStore.approveTeacher(id);
    } else {
      success = await _registrationStore.approveParentRegistration(id);
    }

    if (success && mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı onaylandı')),
      );
    }
  }

  Future<void> _rejectUser(String id, bool isTeacher) async {
    bool success;
    if (isTeacher) {
      success = await _registrationStore.rejectTeacherRegistration(id);
    } else {
      success = await _registrationStore.rejectParentRegistration(id);
    }

    if (success && mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı reddedildi')),
      );
    }
  }
}
