import 'package:flutter/material.dart';
import 'package:kresai/models/registrations.dart';
import 'package:kresai/app.dart'; // For TEST_LAB_MODE
import 'package:kresai/services/registration_store.dart';
import 'package:kresai/navigation/admin_shell.dart';
import 'package:kresai/navigation/teacher_shell.dart';
import 'package:kresai/navigation/parent_shell.dart';
import 'package:kresai/screens/teacher/enter_code_screen.dart';
import 'package:kresai/screens/teacher/pending_approval_screen.dart';
import 'package:kresai/screens/parent/enter_code_screen.dart';
import 'package:kresai/screens/parent/pending_approval_screen.dart';
import 'package:kresai/screens/common/rejected_screen.dart';

/// Auth Role
enum AuthRole {
  admin,
  teacher,
  parent,
}

/// Auth Gate - Role ve kayıt durumuna göre yönlendirme
class AuthGate extends StatefulWidget {
  final AuthRole role;

  const AuthGate({
    super.key,
    required this.role,
  });

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _store = RegistrationStore();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAndRoute();
  }

  Future<void> _loadAndRoute() async {
    await _store.load();
    
    if (!mounted) return;
    
    setState(() => _isLoading = false);
    _route();
  }

  void _route() {
    Widget destination;

    if (TEST_LAB_MODE) {
      switch (widget.role) {
        case AuthRole.admin:
          destination = const AdminShell();
          break;
        case AuthRole.teacher:
          destination = const TeacherShell();
          break;
        case AuthRole.parent:
          destination = const ParentShell();
          break;
      }
       Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destination),
      );
      return;
    }

    switch (widget.role) {
      case AuthRole.admin:
        // Admin direkt girer
        destination = const AdminShell();
        break;

      case AuthRole.teacher:
        final registration = _store.getCurrentTeacherRegistration();
        
        if (registration == null) {
          // Kayıt yok -> Kod gir
          destination = const TeacherEnterCodeScreen();
        } else if (registration.status == RegistrationStatus.pending) {
          // Pending -> Bekle
          destination = const TeacherPendingApprovalScreen();
        } else if (registration.status == RegistrationStatus.approved) {
          // Approved -> Shell'e gir
          destination = const TeacherShell();
        } else {
          // Rejected -> Rejected ekranı
          destination = const RejectedScreen(role: 'teacher');
        }
        break;

      case AuthRole.parent:
        final registration = _store.getCurrentParentRegistration();
        
        if (registration == null) {
          // Kayıt yok -> Kod gir
          destination = const ParentEnterCodeScreen();
        } else if (registration.status == RegistrationStatus.pending) {
          // Pending -> Bekle
          destination = const ParentPendingApprovalScreen();
        } else if (registration.status == RegistrationStatus.approved) {
          // Approved -> Shell'e gir
          destination = const ParentShell();
        } else {
          // Rejected -> Rejected ekranı
          destination = const RejectedScreen(role: 'parent');
        }
        break;
    }

    // Navigate
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : const SizedBox.shrink(),
      ),
    );
  }
}
