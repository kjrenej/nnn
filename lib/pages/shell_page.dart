import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../components/animated_nav_bar.dart';
import '../l10n/localizations.dart';

/// Main scaffold with animated floating bottom navigation bar.
class ShellPage extends StatelessWidget {
  final Widget child;
  const ShellPage({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/map') return 1;
    if (location == '/add-listing') return 2;
    if (location == '/messages') return 3;
    if (location == '/profile') return 4;
    if (location == '/landlord-profile') return 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final l = RentoLocalizations.of(context);
    final index = _currentIndex(context);

    return Scaffold(
      // FIX: Removed KeyedSubtree(key: ValueKey(index)) wrapper.
      // Using a ValueKey tied to the tab index forces the ENTIRE child subtree
      // to rebuild and lose state every time the tab changes. ShellRoute already
      // handles state preservation correctly — let it do its job.
      body: child,
      bottomNavigationBar: AnimatedNavBar(
        currentIndex: index,
        onTap: (i) {
          switch (i) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/map');
              break;
            case 2:
              context.go('/add-listing');
              break;
            case 3:
              context.go('/messages');
              break;
            case 4:
              context.go('/profile');
              break;
          }
        },
        items: [
          AnimatedNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: l.get('home'),
          ),
          AnimatedNavItem(
            icon: Icons.location_on_outlined,
            activeIcon: Icons.location_on_rounded,
            label: l.get('map'),
          ),
          AnimatedNavItem(
            icon: Icons.add_home_outlined,
            activeIcon: Icons.add_home_rounded,
            label: l.get('addProperty'),
          ),
          AnimatedNavItem(
            icon: Icons.forum_outlined,
            activeIcon: Icons.forum_rounded,
            label: l.get('messages'),
          ),
          AnimatedNavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: l.get('profile'),
          ),
        ],
      ),
    );
  }
}