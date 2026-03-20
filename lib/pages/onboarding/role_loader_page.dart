import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../auth/auth_service.dart';
import '../../backend/database_service.dart';
import '../../config/constants.dart';
import '../../state/app_state.dart';

/// Loading screen that determines user role and routes accordingly.
class RoleLoaderPage extends StatefulWidget {
  const RoleLoaderPage({super.key});

  @override
  State<RoleLoaderPage> createState() => _RoleLoaderPageState();
}

class _RoleLoaderPageState extends State<RoleLoaderPage> {
  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    try {
      final uid = AuthService.instance.currentUserUid;
      final user = await DatabaseService.instance.getUser(uid);
      if (user == null || user.role == null) {
        if (mounted) context.go('/role-selection');
        return;
      }

      final appState = AppState.instance;
      appState.isRentee = user.role == AppConstants.roleRentee;
      appState.isLandlord = user.role == AppConstants.roleLandlord;

      if (mounted) context.go('/');
    } catch (_) {
      if (mounted) context.go('/role-selection');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
