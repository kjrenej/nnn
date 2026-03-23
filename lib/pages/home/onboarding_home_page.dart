import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../auth/auth_service.dart';
import '../../backend/database_service.dart';
import '../../backend/models/listing_row.dart';
import '../../backend/models/view_room_card_row.dart';
import '../../components/common_widgets.dart';
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
    if (!mounted) return;
    setState(() => _loading = true);

    final uid = AuthService.instance.currentUserUid;
    final isLandlord = AppState.instance.isLandlord;

    List<ListingRow> featured = [];
    try {
      featured = await DatabaseService.instance.getListings(limit: 20);
    } catch (e) {
      debugPrint('Error fetching listings: $e');
    }

    List<ViewRoomCardRow> roomCards = [];
    try {
      if (uid.isNotEmpty) {
        roomCards = await DatabaseService.instance.getViewRoomCards(uid);
      }
    } catch (e) {
      debugPrint('Error fetching room cards: $e');
    }

    List<ListingRow> landlordListings = [];
    try {
      if (isLandlord && uid.isNotEmpty) {
        landlordListings =
            await DatabaseService.instance.getListingsByOwner(uid);
      }
    } catch (e) {
      debugPrint('Error fetching landlord listings: $e');
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLandlord = AppState.instance.isLandlord;
    final l = RentoLocalizations.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _load,
            color: RentoTheme.primaryColor,
            child: Column(
              children: [
                // ── Top Header ──────────────────────────────
                _buildHeader(context, l, isDark),
                const SizedBox(height: 10),

                // ── Scrollable body ──────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Role-based overview card
                        if (!_loading)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                            child: isLandlord
                                ? _buildLandlordCard(context)
                                : _buildRenteeCard(context),
                          ),

                        // Recent label
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: Text(
                            'Recent',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        // Property list
                        if (_loading)
                          Column(
                            children: List.generate(
                              3,
                              (_) => const Padding(
                                padding: EdgeInsets.only(bottom: 10),
                                child: PropertyCardShimmer(),
                              ),
                            ),
                          )
                        else if (_featured.isEmpty)
                          const EmptyState(
                            icon: Icons.home_outlined,
                            title: 'No properties yet',
                            subtitle: 'Check back later',
                          )
                        else
                          ListView.separated(
                            padding:
                                const EdgeInsets.only(bottom: 40),
                            primary: false,
                            shrinkWrap: true,
                            itemCount: _featured.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) =>
                                _PropertyListCard(
                              key: ValueKey(_featured[index].id),
                              listing: _featured[index],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────

  Widget _buildHeader(
      BuildContext context, RentoLocalizations l, bool isDark) {
    final theme = Theme.of(context);
    final altColor = isDark ? Colors.grey[700]! : const Color(0xFFE0E3E7);

    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: isDark
            ? RentoTheme.cardDark
            : theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 4,
            color: Colors.black.withValues(alpha: 0.2),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Search row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Search bar
              Container(
                width: 300,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: altColor),
                ),
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onSubmitted: (_) => context.push('/search'),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Search',
                          hintStyle: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                                const BorderSide(color: Colors.transparent),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                const BorderSide(color: Colors.transparent),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          filled: true,
                          fillColor: theme.scaffoldBackgroundColor,
                          suffixIcon: Icon(
                            Icons.search_rounded,
                            color: RentoTheme.primaryColor,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Notification bell
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? RentoTheme.cardDark
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.notifications_none_rounded,
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  size: 24,
                ),
              ),
            ],
          ),

          // Category buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['House', 'Hostel', 'PG', 'Flat']
                .map(
                  (label) => _CategoryButton(
                    label: label,
                    onTap: () =>
                        context.push('/categories?category=$label'),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── Rentee card ──────────────────────────────────────────

  Widget _buildRenteeCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_roomCards.isEmpty) return const SizedBox.shrink();

    final room = _roomCards.first;

    return Container(
      decoration: BoxDecoration(
        color:
            isDark ? RentoTheme.cardDark : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 4,
            color: Colors.black.withValues(alpha: 0.2),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('My Home',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
              Container(
                width: 80,
                height: 30,
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text('Active',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: RentoTheme.primaryColor)),
              ),
            ],
          ),
          Divider(color: theme.dividerColor, height: 20),
          Text(room.propertyName ?? 'Property',
              style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                    text: 'Unit: ',
                    style: theme.textTheme.bodyMedium),
                TextSpan(
                    text: room.roomType ?? '',
                    style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Next payment due on  30 Dec 2025',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.6)),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text:
                          '${room.rentAmount ?? 0}',
                      style: theme.textTheme.titleMedium?.copyWith(
                          color: RentoTheme.errorColor,
                          fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: ' /month',
                      style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(color: theme.dividerColor, height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/messages'),
                  icon: const Icon(Icons.message_outlined, size: 15),
                  label: const Text('Contact Landlord'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        theme.colorScheme.onSurface,
                    side: BorderSide(
                        color: theme.colorScheme.onSurface),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    minimumSize: const Size(0, 44),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final encoded =
                        Uri.encodeComponent(room.propertyName ?? '');
                    context.push(
                        '/rent-payment?propertyName=$encoded&rentAmount=${room.rentAmount ?? 0}&cardId=${room.id}');
                  },
                  icon: const Icon(Icons.currency_rupee, size: 18),
                  label: const Text('Pay Rent'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RentoTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    minimumSize: const Size(0, 44),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Landlord card ────────────────────────────────────────

  Widget _buildLandlordCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_landlordListings.isEmpty) return const SizedBox.shrink();

    final listing = _landlordListings.first;
    final isHostelOrPG = listing.propertyType == 'Hostel' ||
        listing.propertyType == 'PG';
    final occupied =
        (listing.totalRoom ?? 0) - (listing.roomAvailable ?? 0);

    return Container(
      decoration: BoxDecoration(
        color:
            isDark ? RentoTheme.cardDark : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 4,
            color: Colors.black.withValues(alpha: 0.2),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(listing.propertyName ?? 'Property',
                    style: theme.textTheme.titleLarge),
              ),
              Container(
                width: 80,
                height: 30,
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text('Active',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: RentoTheme.primaryColor)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Location
          Row(
            children: [
              Icon(Icons.location_pin,
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: 0.5),
                  size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${listing.propertyAddress ?? ''}, ${listing.city ?? ''}, ${listing.state ?? ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.5)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Divider(color: theme.dividerColor),

          // Total earnings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text('0',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: RentoTheme.primaryColor)),
                      Text('Total Earnings',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Room stats (hostel/PG only)
          if (isHostelOrPG) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _StatBox(
                    value: '${listing.roomAvailable ?? 0}',
                    label: 'Available\nRoom'),
                const SizedBox(width: 8),
                _StatBox(
                    value: '${listing.totalRoom ?? 0}',
                    label: 'Total\nRoom'),
                const SizedBox(width: 8),
                _StatBox(
                    value: '$occupied',
                    label: 'Occupied\nRoom'),
              ],
            ),
          ],

          Divider(color: theme.dividerColor),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push('/messages'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface,
                    side: BorderSide(
                        color: theme.colorScheme.onSurface),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    minimumSize: const Size(0, 44),
                  ),
                  child: const Text('Enquiries'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      context.push('/landlord-profile'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface,
                    side: BorderSide(
                        color: theme.colorScheme.onSurface),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    minimumSize: const Size(0, 44),
                  ),
                  child: const Text('Manage'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Stat box widget ────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(value, style: theme.textTheme.bodyMedium),
            Text(label,
                textAlign: TextAlign.center,
                style:
                    theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ── Category button ────────────────────────────────────────

class _CategoryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _CategoryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return SizedBox(
      width: 80,
      height: 56,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurface,
          backgroundColor: theme.scaffoldBackgroundColor,
          side: BorderSide(
              color:
                  isDark ? Colors.grey[700]! : const Color(0xFFE0E3E7)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          elevation: 0,
        ),
        child: Text(label,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── Property list card ─────────────────────────────────────

class _PropertyListCard extends StatefulWidget {
  final ListingRow listing;
  const _PropertyListCard({super.key, required this.listing});

  @override
  State<_PropertyListCard> createState() => _PropertyListCardState();
}

class _PropertyListCardState extends State<_PropertyListCard> {
  final PageController _pageCtrl = PageController();
  int _currentImage = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  bool get _isHouseOrFlat =>
      widget.listing.propertyType == 'House' ||
      widget.listing.propertyType == 'Flat';

  bool get _isPGOrHostel =>
      widget.listing.propertyType == 'PG' ||
      widget.listing.propertyType == 'Hostel';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final listing = widget.listing;
    final images = listing.images;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color:
            isDark ? RentoTheme.cardDark : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(0),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Image slider ──
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey[800]
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: isDark
                        ? Colors.grey[700]!
                        : const Color(0xFFE0E3E7)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // Images
                  images.isEmpty
                      ? Center(
                          child: Icon(Icons.home_outlined,
                              size: 64,
                              color: Colors.grey[400]))
                      : PageView.builder(
                          controller: _pageCtrl,
                          itemCount: images.length,
                          onPageChanged: (i) =>
                              setState(() => _currentImage = i),
                          itemBuilder: (_, i) => CachedNetworkImage(
                            imageUrl: images[i],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (ctx, _) => Container(
                                color: isDark
                                    ? Colors.grey[800]
                                    : Colors.grey[200]),
                            errorWidget: (ctx, _, __) => Center(
                              child: Icon(Icons.broken_image,
                                  color: Colors.grey[400], size: 48),
                            ),
                          ),
                        ),

                  // "Available" badge top-right
                  Positioned(
                    top: 10,
                    right: 12,
                    child: Text(
                      listing.status == 'active'
                          ? 'Available'
                          : listing.status,
                      style: TextStyle(
                        color: listing.status == 'active'
                            ? RentoTheme.primaryColor
                            : Colors.orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  // Page indicator dots (bottom center)
                  if (images.length > 1)
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          images.length,
                          (i) => AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 3),
                            width:
                                i == _currentImage ? 16 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _currentImage
                                  ? Colors.white
                                  : Colors.white
                                      .withValues(alpha: 0.5),
                              borderRadius:
                                  BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Property info ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type badge + room/for label + price
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: type + room label + name + location
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            // Type badge + secondary label
                            Row(
                              children: [
                                if (listing.propertyType != null)
                                  Container(
                                    height: 30,
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 8),
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      border: Border.all(
                                          color:
                                              RentoTheme.primaryColor),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      listing.propertyType!,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                              color: RentoTheme
                                                  .primaryColor),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                Text(
                                  _isHouseOrFlat
                                      ? (listing.roomType ?? '')
                                      : (listing.propertyFor ?? ''),
                                  style: theme.textTheme.labelSmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),

                            // Property name
                            Text(
                              listing.propertyName ??
                                  'property_name',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(
                                      fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),

                            // Location
                            Row(
                              children: [
                                Icon(Icons.location_on_rounded,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                    size: 16),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    [
                                      listing.propertyAddress,
                                      listing.city,
                                      listing.state,
                                    ]
                                        .where((e) =>
                                            e != null && e.isNotEmpty)
                                        .join(', '),
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(
                                            color: theme
                                                .colorScheme.onSurface
                                                .withValues(
                                                    alpha: 0.5)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Right: price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            listing.price?.toString() ?? '0',
                            style: theme.textTheme.titleLarge
                                ?.copyWith(
                                    color: RentoTheme.primaryColor,
                                    fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '/ month',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Features row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (_isHouseOrFlat) ...[
                          _FeatureChip(
                              icon: Icons.bed_rounded,
                              label:
                                  '${listing.beds ?? 0} bedroom'),
                          const SizedBox(width: 16),
                          _FeatureChip(
                              icon: Icons.bathtub_rounded,
                              label:
                                  '${listing.washrooms ?? ''} bathroom'),
                          const SizedBox(width: 16),
                          _FeatureChip(
                              icon: Icons.square_foot_rounded,
                              label:
                                  '${listing.area ?? ''} ${listing.areaMeasuringUnit ?? ''}'),
                        ],
                        if (_isPGOrHostel) ...[
                          _FeatureChip(
                              icon: Icons.bed_rounded,
                              label: listing.roomType ?? ''),
                          const SizedBox(width: 16),
                          _FeatureChip(
                              icon: Icons.bathtub_rounded,
                              label:
                                  '${listing.washrooms ?? ''} Washroom'),
                          const SizedBox(width: 16),
                          _FeatureChip(
                              icon: Icons.ac_unit,
                              label: listing.conditioning ?? ''),
                          const SizedBox(width: 16),
                          _FeatureChip(
                              icon: Icons.restaurant,
                              label: listing.mealOption ?? ''),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── View Details button ──
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
              child: OutlinedButton(
                onPressed: () => context
                    .push('/property-detail?id=${listing.id}'),
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  side: BorderSide(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.6)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  minimumSize: const Size(double.infinity, 40),
                ),
                child: Text(
                  'View Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Feature chip ───────────────────────────────────────────

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            color:
                theme.colorScheme.onSurface.withValues(alpha: 0.5),
            size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
              color:
                  theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        ),
      ],
    );
  }
}