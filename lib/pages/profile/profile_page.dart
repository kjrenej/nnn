import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../auth/auth_service.dart';
import '../../backend/database_service.dart';
import '../../backend/models/user_row.dart';
import '../../state/app_state.dart';
import '../../theme/rento_theme.dart';
import '../../components/custom_alert.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserRow? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _user = await DatabaseService.instance.getUser(
        AuthService.instance.currentUserUid,
      );
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _logout() async {
    CustomAlert.showConfirmationDialog(
      context,
      title: 'Sign Out',
      description: 'Are you sure you want to sign out?',
      confirmText: 'Sign Out',
      isDestructive: true,
      onConfirm: () async {
        await AuthService.instance.signOut();
        if (!mounted) return;
        await context.read<AppState>().reset();
        if (mounted) context.go('/login');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appState = context.watch<AppState>();

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => RotationTransition(
                turns: Tween(begin: 0.75, end: 1.0).animate(anim),
                child: ScaleTransition(scale: anim, child: child),
              ),
              child: Icon(
                appState.isDarkMode
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                key: ValueKey(appState.isDarkMode),
              ),
            ),
            onPressed: () => appState.toggleDarkMode(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar & name
          Center(
            child: Column(
              children: [
                Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RentoTheme.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: RentoTheme.primaryColor.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: isDark
                            ? RentoTheme.cardDark
                            : Colors.white,
                        child: Text(
                          (_user?.displayName ?? 'U')
                              .substring(0, 1)
                              .toUpperCase(),
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: RentoTheme.primaryColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1, 1),
                      duration: 500.ms,
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(height: 16),
                Text(
                      _user?.displayName ?? 'User',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms)
                    .slideY(
                      begin: 0.2,
                      end: 0,
                      delay: 200.ms,
                      duration: 400.ms,
                    ),
                const SizedBox(height: 4),
                Text(
                  AuthService.instance.currentUserEmail,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                const SizedBox(height: 8),
                Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: RentoTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _user?.role?.toUpperCase() ?? 'RENTEE',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 400.ms)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1, 1),
                      delay: 400.ms,
                      duration: 400.ms,
                      curve: Curves.easeOutBack,
                    ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Menu items with staggered animations
          ..._buildMenuItems(context, isDark),
        ],
      ),
    );
  }

  List<Widget> _buildMenuItems(BuildContext context, bool isDark) {
    final items = <Widget>[];
    var delay = 500;

    Widget animatedTile(
      IconData icon,
      String label,
      VoidCallback onTap, {
      Color? textColor,
      Color? iconColor,
    }) {
      final w =
          _tile(
                icon,
                label,
                onTap,
                isDark: isDark,
                textColor: textColor,
                iconColor: iconColor,
              )
              .animate()
              .fadeIn(delay: delay.ms, duration: 300.ms)
              .slideX(
                begin: 0.05,
                end: 0,
                delay: delay.ms,
                duration: 300.ms,
                curve: Curves.easeOut,
              );
      delay += 60;
      return w;
    }

    items.add(
      animatedTile(Icons.person_outline_rounded, 'Edit Profile', () {
        context.push('/edit-profile');
      }),
    );
    items.add(
      animatedTile(Icons.lock_outline_rounded, 'Update Password', () {
        context.push('/update-password');
      }),
    );
    items.add(
      animatedTile(Icons.receipt_long_rounded, 'Payment History', () {
        context.push('/payment-history');
      }),
    );
    items.add(
      animatedTile(Icons.favorite_border_rounded, 'My Favourites', () {
        context.push('/favourites');
      }),
    );

    items.add(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Divider(color: Colors.grey.withValues(alpha: 0.2)),
      ).animate().fadeIn(delay: delay.ms, duration: 300.ms),
    );
    delay += 60;

    items.add(
      animatedTile(Icons.language_rounded, 'Language', () {
        context.push('/language');
      }),
    );
    items.add(
      animatedTile(Icons.notifications_outlined, 'Notifications', () {
        context.push('/notifications');
      }),
    );
    items.add(
      animatedTile(Icons.headset_mic_outlined, 'Support', () {
        context.push('/support');
      }),
    );

    items.add(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Divider(color: Colors.grey.withValues(alpha: 0.2)),
      ).animate().fadeIn(delay: delay.ms, duration: 300.ms),
    );
    delay += 60;

    items.add(
      animatedTile(
        Icons.logout_rounded,
        'Sign Out',
        _logout,
        textColor: RentoTheme.accentColor,
        iconColor: RentoTheme.accentColor,
      ),
    );

    return items;
  }

  Widget _tile(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isDark = false,
    Color? textColor,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? RentoTheme.primaryColor).withValues(
              alpha: 0.1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: iconColor ?? RentoTheme.primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: Colors.grey[400],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: onTap,
      ),
    );
  }
}
