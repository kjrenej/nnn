import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../auth/auth_service.dart';
import '../../backend/database_service.dart';
import '../../config/constants.dart';
import '../../state/app_state.dart';
import '../../theme/rento_theme.dart';
import '../../l10n/localizations.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  String? _selectedRole;
  bool _loading = false;

  Future<void> _continue() async {
    if (_selectedRole == null) return;
    setState(() => _loading = true);
    try {
      final uid = AuthService.instance.currentUserUid;
      await DatabaseService.instance.updateUser(uid, {
        'role': _selectedRole,
        'onboarding_step': 2,
      });

      final appState = AppState.instance;
      if (_selectedRole == AppConstants.roleRentee) {
        appState.isRentee = true;
        appState.isLandlord = false;
      } else {
        appState.isLandlord = true;
        appState.isRentee = false;
      }

      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = RentoLocalizations.of(context);
    final theme = Theme.of(context);
    final altColor = Colors.grey[300]!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'I am a...',
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontFamily: 'Source Sans Pro',
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Please select your role to personalize your experience',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  letterSpacing: 0,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Role cards
            // Rentee
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _RoleCard(
                title: l.get('rentee'),
                subtitle: l.get('renteeDesc'),
                icon: Icons.person_search,
                selected: _selectedRole == AppConstants.roleRentee,
                selectedColor: RentoTheme.successColor,
                defaultColor: altColor,
                onTap: () =>
                    setState(() => _selectedRole = AppConstants.roleRentee),
              ),
            ),
            const SizedBox(height: 16),

            // Landlord
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _RoleCard(
                title: l.get('landlord'),
                subtitle: l.get('landlordDesc'),
                icon: Icons.home,
                selected: _selectedRole == AppConstants.roleLandlord,
                selectedColor: RentoTheme.successColor,
                defaultColor: altColor,
                onTap: () =>
                    setState(() => _selectedRole = AppConstants.roleLandlord),
              ),
            ),
            const SizedBox(height: 20),

            // Continue button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedRole != null && !_loading
                      ? _continue
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.onSurface,
                    foregroundColor: theme.colorScheme.surface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    textStyle: theme.textTheme.titleLarge?.copyWith(
                      letterSpacing: 0,
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l.get('continue_')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final Color selectedColor;
  final Color defaultColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.selectedColor,
    required this.defaultColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = selected ? selectedColor : defaultColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(100),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: theme.colorScheme.onSurface, size: 30),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 0),
            ),
            const SizedBox(height: 20),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(letterSpacing: 0),
            ),
          ],
        ),
      ),
    );
  }
}
