import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_service.dart';
import '../state/app_state.dart';
import '../pages/auth/login_page.dart';
import '../pages/auth/signup_page.dart';
import '../pages/auth/forgot_password_page.dart';
import '../pages/onboarding/user_details_page.dart';
import '../pages/onboarding/role_selection_page.dart';
import '../pages/onboarding/role_loader_page.dart';
import '../pages/home/onboarding_home_page.dart';
import '../pages/map/map_page.dart';
import '../pages/search/search_page.dart';
import '../pages/categories/categories_page.dart';
import '../pages/categories/categories_list_page.dart';
import '../pages/filter/filter_page.dart';
import '../pages/property/property_detail_page.dart';
import '../pages/property/explore_images_page.dart';
import '../pages/booking/payment_option_page.dart';
import '../pages/booking/book_confirm_page.dart';
import '../pages/booking/rent_payment_page.dart';
import '../pages/booking/payment_history_page.dart';
import '../pages/profile/profile_page.dart';
import '../pages/profile/edit_profile_page.dart';
import '../pages/profile/update_password_page.dart';
import '../pages/profile/favourites_page.dart';
import '../pages/settings/language_page.dart';
import '../pages/settings/notification_page.dart';
import '../pages/settings/support_page.dart';
import '../pages/landlord/add_listing_page.dart';
import '../pages/landlord/landlord_profile_page.dart';
import '../pages/message/message_page.dart';
import '../pages/shell_page.dart';
import '../theme/page_transitions.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  refreshListenable: Listenable.merge([
    AuthService.instance,
    AppState.instance,
  ]),
  redirect: (context, state) {
    final auth = AuthService.instance;
    final loggedIn = auth.loggedIn;
    final loc = state.matchedLocation;

    final onAuthRoute =
        loc == '/login' || loc == '/signup' || loc == '/forgot-password';

    // FIX: '/role-loader' was missing — caused infinite redirect loop where
    // the redirect kept firing while on role-loader, sending user back to it.
    final onOnboardingRoute =
        loc == '/user-details' ||
        loc == '/role-selection' ||
        loc == '/role-loader'; // ← CRITICAL FIX

    // Not logged in → send to login
    if (!loggedIn && !onAuthRoute) return '/login';

    if (loggedIn) {
      // Brand-new user → complete profile first
      if (auth.isNewUser && !onOnboardingRoute) {
        auth.consumeNewUser();
        return '/user-details';
      }

      // Logged-in user hitting an auth page → send home
      if (onAuthRoute) return '/';

      // Logged in but role not yet set → role-loader
      if (!onOnboardingRoute) {
        final appState = AppState.instance;
        if (!appState.isRentee && !appState.isLandlord) {
          return '/role-loader';
        }
      }
    }

    return null;
  },
  routes: [
    // ── Auth routes (no shell) ────────────────────────────
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) =>
          fadeTransition(key: state.pageKey, child: const LoginPage()),
    ),
    GoRoute(
      path: '/signup',
      pageBuilder: (context, state) =>
          slideRightTransition(key: state.pageKey, child: const SignupPage()),
    ),
    GoRoute(
      path: '/forgot-password',
      pageBuilder: (context, state) => slideRightTransition(
        key: state.pageKey,
        child: const ForgotPasswordPage(),
      ),
    ),

    // ── Onboarding (no shell) ─────────────────────────────
    GoRoute(
      path: '/user-details',
      pageBuilder: (context, state) => fadeSlideTransition(
        key: state.pageKey,
        child: const UserDetailsPage(),
      ),
    ),
    GoRoute(
      path: '/role-selection',
      pageBuilder: (context, state) => scaleFadeTransition(
        key: state.pageKey,
        child: const RoleSelectionPage(),
      ),
    ),
    GoRoute(
      path: '/role-loader',
      pageBuilder: (context, state) =>
          fadeTransition(key: state.pageKey, child: const RoleLoaderPage()),
    ),

    // ── Main app with bottom nav ──────────────────────────
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => ShellPage(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: OnboardingHomePage()),
        ),
        GoRoute(
          path: '/landlord-profile',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: LandlordProfilePage()),
        ),
        GoRoute(
          path: '/map',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: MapPage()),
        ),
        GoRoute(
          path: '/add-listing',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: AddListingPage()),
        ),
        GoRoute(
          path: '/edit-listing',
          pageBuilder: (context, state) {
            final id = state.uri.queryParameters['id'];
            return NoTransitionPage(child: AddListingPage(listingId: id));
          },
        ),
        GoRoute(
          path: '/messages',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: MessagePage()),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ProfilePage()),
        ),
      ],
    ),

    // ── Detail / secondary routes ─────────────────────────
    GoRoute(
      path: '/search',
      pageBuilder: (context, state) =>
          fadeSlideTransition(key: state.pageKey, child: const SearchPage()),
    ),
    GoRoute(
      path: '/categories',
      pageBuilder: (context, state) {
        final category = state.uri.queryParameters['category'] ?? '';
        return slideRightTransition(
          key: state.pageKey,
          child: CategoriesPage(category: category),
        );
      },
    ),
    GoRoute(
      path: '/categories-list',
      pageBuilder: (context, state) => slideRightTransition(
        key: state.pageKey,
        child: const CategoriesListPage(),
      ),
    ),
    GoRoute(
      path: '/filter',
      pageBuilder: (context, state) =>
          slideUpTransition(key: state.pageKey, child: const FilterPage()),
    ),
    GoRoute(
      path: '/property-detail',
      pageBuilder: (context, state) {
        final listingId = state.uri.queryParameters['id'] ?? '';
        return fadeSlideTransition(
          key: state.pageKey,
          child: PropertyDetailPage(listingId: listingId),
        );
      },
    ),
    GoRoute(
      path: '/property/:id',
      pageBuilder: (context, state) {
        final listingId = state.pathParameters['id'] ?? '';
        return fadeSlideTransition(
          key: state.pageKey,
          child: PropertyDetailPage(listingId: listingId),
        );
      },
    ),
    GoRoute(
      path: '/explore-images',
      pageBuilder: (context, state) {
        // FIX: URL-decode each image URL to handle special characters in URLs
        final rawImages = state.uri.queryParameters['images'] ?? '';
        final images = rawImages.isEmpty
            ? <String>[]
            : rawImages.split(',').map(Uri.decodeComponent).toList();
        return fadeTransition(
          key: state.pageKey,
          child: ExploreImagesPage(imageUrls: images),
        );
      },
    ),
    GoRoute(
      path: '/payment-option',
      pageBuilder: (context, state) {
        final listingId = state.uri.queryParameters['listingId'] ?? '';
        return slideRightTransition(
          key: state.pageKey,
          child: PaymentOptionPage(listingId: listingId),
        );
      },
    ),
    GoRoute(
      path: '/book-confirm',
      pageBuilder: (context, state) {
        final listingId = state.uri.queryParameters['listingId'] ?? '';
        final totalPaid = state.uri.queryParameters['totalPaid'] ?? '0';
        final paymentId = state.uri.queryParameters['paymentId'] ?? '';
        return scaleFadeTransition(
          key: state.pageKey,
          child: BookConfirmPage(
            listingId: listingId,
            totalPaid: double.tryParse(totalPaid) ?? 0,
            paymentId: paymentId,
          ),
        );
      },
    ),
    GoRoute(
      path: '/rent-payment',
      pageBuilder: (context, state) {
        final propertyName = Uri.decodeComponent(
          state.uri.queryParameters['propertyName'] ?? '',
        );
        final rentAmount = state.uri.queryParameters['rentAmount'] ?? '0';
        final cardId = state.uri.queryParameters['cardId'] ?? '';
        return slideRightTransition(
          key: state.pageKey,
          child: RentPaymentPage(
            propertyName: propertyName,
            rentAmount: int.tryParse(rentAmount) ?? 0,
            cardId: cardId,
          ),
        );
      },
    ),
    GoRoute(
      path: '/payment-history',
      pageBuilder: (context, state) => slideRightTransition(
        key: state.pageKey,
        child: const PaymentHistoryPage(),
      ),
    ),
    GoRoute(
      path: '/edit-profile',
      pageBuilder: (context, state) => slideRightTransition(
        key: state.pageKey,
        child: const EditProfilePage(),
      ),
    ),
    GoRoute(
      path: '/update-password',
      pageBuilder: (context, state) => slideRightTransition(
        key: state.pageKey,
        child: const UpdatePasswordPage(),
      ),
    ),
    GoRoute(
      path: '/language',
      pageBuilder: (context, state) =>
          slideRightTransition(key: state.pageKey, child: const LanguagePage()),
    ),
    GoRoute(
      path: '/notifications',
      pageBuilder: (context, state) => slideRightTransition(
        key: state.pageKey,
        child: const NotificationPage(),
      ),
    ),
    GoRoute(
      path: '/support',
      pageBuilder: (context, state) =>
          slideRightTransition(key: state.pageKey, child: const SupportPage()),
    ),
    GoRoute(
      path: '/favourites',
      pageBuilder: (context, state) => slideRightTransition(
        key: state.pageKey,
        child: const FavouritesPage(),
      ),
    ),
  ],
  // FIX: Show a proper error page instead of silently redirecting to login
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Page Not Found')),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Page not found', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            state.matchedLocation,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text('Go Home'),
          ),
        ],
      ),
    ),
  ),
);
