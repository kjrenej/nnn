import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../auth/auth_service.dart';
import '../../backend/database_service.dart';
import '../../backend/models/listing_row.dart';
import '../../backend/models/view_room_card_row.dart';
import '../../components/common_widgets.dart';
import '../../components/property_card.dart';
import '../../components/room_card.dart';
import '../../l10n/localizations.dart';
import '../../state/app_state.dart';
import '../../theme/rento_theme.dart';

class OnboardingHomePage extends StatefulWidget {
  const OnboardingHomePage({super.key});

  @override
  State<OnboardingHomePage> createState() => _OnboardingHomePageState();
}

class _OnboardingHomePageState extends State<OnboardingHomePage> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  List<ListingRow> _featured = [];
  List<ListingRow> _landlordListings = [];
  List<ViewRoomCardRow> _roomCards = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final uid = AuthService.instance.currentUserUid;
    final isLandlord = AppState.instance.isLandlord;

    // Fetch listings (main content) — isolated so other failures don't block it
    List<ListingRow> featured = [];
    try {
      featured = await DatabaseService.instance.getListings(limit: 10);
    } catch (e, s) {
      debugPrint('Error fetching listings: $e\n$s');
    }

    // Fetch room cards (rentee overview) — allowed to fail gracefully
    List<ViewRoomCardRow> roomCards = [];
    try {
      if (uid.isNotEmpty) {
        roomCards = await DatabaseService.instance.getViewRoomCards(uid);
      }
    } catch (e, s) {
      debugPrint('Error fetching room cards: $e\n$s');
    }

    // Fetch landlord listings — allowed to fail gracefully
    List<ListingRow> landlordListings = [];
    try {
      if (isLandlord && uid.isNotEmpty) {
        landlordListings = await DatabaseService.instance.getListingsByOwner(
          uid,
        );
      }
    } catch (e, s) {
      debugPrint('Error fetching landlord listings: $e\n$s');
    }

    if (mounted) {
      setState(() {
        _featured = featured;
        _roomCards = roomCards;
        _landlordListings = landlordListings;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = RentoLocalizations.of(context);
    final theme = Theme.of(context);
    final isLandlord = AppState.instance.isLandlord;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _load,
            color: RentoTheme.primaryColor,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context, l, isDark)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    child: isLandlord
                        ? _buildLandlordOverview(context)
                        : _buildRenteeOverview(context),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text(
                      'Recent',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ).animate().fadeIn(delay: 250.ms, duration: 350.ms),
                  ),
                ),
                if (_loading)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, _) => const PropertyCardShimmer(),
                        childCount: 3,
                      ),
                    ),
                  )
                else if (_featured.isEmpty)
                  const SliverToBoxAdapter(
                    child: EmptyState(
                      icon: Icons.home_outlined,
                      title: 'No properties yet',
                      subtitle: 'Check back later for new listings',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: PropertyCard(listing: _featured[index])
                              .animate()
                              .fadeIn(
                                delay: (300 + index * 100).ms,
                                duration: 350.ms,
                              ),
                        );
                      }, childCount: _featured.length),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, RentoLocalizations l, bool isDark) {
    final theme = Theme.of(context);
    final altColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? RentoTheme.cardDark : theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.08),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: altColor),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => context.push('/search'),
                    decoration: InputDecoration(
                      hintText: l.get('search'),
                      hintStyle: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.55,
                        ),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      prefixIcon: IconButton(
                        onPressed: () => context.push('/search'),
                        icon: const Icon(Icons.search_rounded, size: 24),
                        color: RentoTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => context.push('/notifications'),
                child: Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryButton(context, 'House'),
                const SizedBox(width: 10),
                _buildCategoryButton(context, 'Hostel'),
                const SizedBox(width: 10),
                _buildCategoryButton(context, 'PG'),
                const SizedBox(width: 10),
                _buildCategoryButton(context, 'Flat'),
              ],
            ).animate().fadeIn(delay: 120.ms, duration: 300.ms),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(BuildContext context, String label) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return OutlinedButton(
      onPressed: () => context.push('/categories?category=$label'),
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.colorScheme.onSurface,
        backgroundColor: theme.scaffoldBackgroundColor,
        side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      child: Text(
        label,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRenteeOverview(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: PropertyCardShimmer(),
      );
    }

    if (_roomCards.isEmpty) {
      return _buildSummaryShell(
        context,
        title: 'My Home',
        statusLabel: 'Ready',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No active booking yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Browse recent listings below and book the place that fits you.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push('/search'),
                child: const Text('Explore Properties'),
              ),
            ),
          ],
        ),
      );
    }

    final room = _roomCards.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Home',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        RoomCard(
          card: room,
          onPayRent: () {
            context.push(
              '/rent-payment?propertyName=${Uri.encodeComponent(room.propertyName ?? '')}&rentAmount=${room.rentAmount ?? 0}&cardId=${room.id}',
            );
          },
        ),
      ],
    ).animate().fadeIn(delay: 180.ms, duration: 320.ms);
  }

  Widget _buildLandlordOverview(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: PropertyCardShimmer(),
      );
    }

    if (_landlordListings.isEmpty) {
      return _buildSummaryShell(
        context,
        title: 'Property Overview',
        statusLabel: 'Setup',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No property added yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first property to start managing listings from this shared home page.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push('/landlord-profile'),
                    child: const Text('Manage'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.push('/add-listing'),
                    child: const Text('Add Property'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(delay: 180.ms, duration: 320.ms);
    }

    final listing = _landlordListings.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Property Overview',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton.icon(
              onPressed: () => context.push('/edit-listing?id=${listing.id}'),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit Property'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        PropertyCard(listing: listing),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.push('/messages'),
                child: const Text('Enquiries'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => context.push('/landlord-profile'),
                child: const Text('Manage Tenants'),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 180.ms, duration: 320.ms);
  }

  Widget _buildSummaryShell(
    BuildContext context, {
    required String title,
    required String statusLabel,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? RentoTheme.cardDark : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.08),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel.isNotEmpty
                        ? statusLabel[0].toUpperCase() +
                              statusLabel.substring(1)
                        : 'Active',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: RentoTheme.successColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
