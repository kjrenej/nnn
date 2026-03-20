import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../auth/auth_service.dart';
import '../../backend/database_service.dart';
import '../../backend/models/listing_row.dart';
import '../../l10n/localizations.dart';
import '../../theme/rento_theme.dart';

class PropertyDetailPage extends StatefulWidget {
  final String listingId;
  const PropertyDetailPage({super.key, required this.listingId});

  @override
  State<PropertyDetailPage> createState() => _PropertyDetailPageState();
}

class _PropertyDetailPageState extends State<PropertyDetailPage> {
  ListingRow? _listing;
  bool _loading = true;
  int _currentImage = 0;
  final _pageCtrl = PageController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final listing = await DatabaseService.instance.getListing(
        widget.listingId,
      );
      setState(() {
        _listing = listing;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = RentoLocalizations.of(context);
    final theme = Theme.of(context);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_listing == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Property not found')),
      );
    }

    final listing = _listing!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Image Slider ────────────────────────────────
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            stretch: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              background: listing.images.isNotEmpty
                  ? Stack(
                      children: [
                        Hero(
                          tag: 'property-image-${listing.id}',
                          child: PageView.builder(
                            controller: _pageCtrl,
                            itemCount: listing.images.length,
                            onPageChanged: (i) =>
                                setState(() => _currentImage = i),
                            itemBuilder: (_, i) => GestureDetector(
                              onTap: () => context.push(
                                '/explore-images?images=${listing.images.join(',')}',
                              ),
                              child: CachedNetworkImage(
                                imageUrl: listing.images[i],
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          ),
                        ),
                        // Gradient overlay
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.4),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              listing.images.length,
                              (i) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                width: i == _currentImage ? 28 : 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: i == _currentImage
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.home, size: 80)),
                    ),
            ),
          ),

          // ── Details ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name & type
                  Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              listing.propertyName ?? 'Property',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          if (listing.propertyType != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                gradient: RentoTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                listing.propertyType!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                      )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(
                        begin: 0.1,
                        end: 0,
                        duration: 400.ms,
                        curve: Curves.easeOut,
                      ),
                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          [
                            listing.propertyAddress,
                            listing.city,
                            listing.state,
                          ].where((e) => e != null && e.isNotEmpty).join(', '),
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                  const SizedBox(height: 16),

                  // Price container
                  Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              RentoTheme.primaryColor.withValues(alpha: 0.08),
                              RentoTheme.primaryColor.withValues(alpha: 0.03),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: RentoTheme.primaryColor.withValues(
                              alpha: 0.1,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _priceItem(
                              l.get('rentAmount'),
                              listing.price != null
                                  ? '₹${listing.price}/mo'
                                  : 'N/A',
                              theme,
                            ),
                            Container(
                              height: 36,
                              width: 1,
                              color: RentoTheme.primaryColor.withValues(
                                alpha: 0.2,
                              ),
                            ),
                            _priceItem(
                              l.get('securityDeposit'),
                              listing.securityDeposit != null
                                  ? '₹${listing.securityDeposit}'
                                  : 'N/A',
                              theme,
                            ),
                            Container(
                              height: 36,
                              width: 1,
                              color: RentoTheme.primaryColor.withValues(
                                alpha: 0.2,
                              ),
                            ),
                            _priceItem(
                              'Maintenance',
                              listing.monthlyMaintenance != null
                                  ? '₹${listing.monthlyMaintenance}'
                                  : 'N/A',
                              theme,
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms)
                      .slideY(
                        begin: 0.08,
                        end: 0,
                        delay: 200.ms,
                        duration: 400.ms,
                        curve: Curves.easeOut,
                      ),
                  const SizedBox(height: 24),

                  // Quick info chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (listing.roomType != null)
                        _infoChip(Icons.bed, listing.roomType!, theme),
                      if (listing.beds != null)
                        _infoChip(
                          Icons.king_bed,
                          '${listing.beds} Beds',
                          theme,
                        ),
                      if (listing.washrooms != null)
                        _infoChip(
                          Icons.bathtub_outlined,
                          listing.washrooms!,
                          theme,
                        ),
                      if (listing.furnishing != null)
                        _infoChip(Icons.chair, listing.furnishing!, theme),
                      if (listing.conditioning != null)
                        _infoChip(Icons.ac_unit, listing.conditioning!, theme),
                      if (listing.area != null)
                        _infoChip(
                          Icons.square_foot,
                          '${listing.area} ${listing.areaMeasuringUnit ?? ''}',
                          theme,
                        ),
                      if (listing.totalFloor != null)
                        _infoChip(
                          Icons.layers,
                          '${listing.totalFloor} Floors',
                          theme,
                        ),
                      if (listing.parkingFee == true)
                        _infoChip(Icons.local_parking, 'Parking', theme),
                      if (listing.utilitiesIncluded == true)
                        _infoChip(Icons.bolt, 'Utilities Incl.', theme),
                      if (listing.mealOption != null)
                        _infoChip(Icons.restaurant, listing.mealOption!, theme),
                    ],
                  ).animate().fadeIn(delay: 350.ms, duration: 400.ms),
                  const SizedBox(height: 24),

                  // Description
                  if (listing.description != null &&
                      listing.description!.isNotEmpty) ...[
                    Text(
                      l.get('description'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ).animate().fadeIn(delay: 450.ms, duration: 400.ms),
                    const SizedBox(height: 8),
                    Text(
                      listing.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.6,
                        color: Colors.grey[600],
                      ),
                    ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
                    const SizedBox(height: 24),
                  ],

                  // Amenities
                  if (listing.amenities.isNotEmpty) ...[
                    Text(
                      l.get('amenities'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ).animate().fadeIn(delay: 550.ms, duration: 400.ms),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: listing.amenities
                          .map(
                            (a) => Chip(
                              label: Text(a),
                              avatar: const Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                                color: Colors.green,
                              ),
                            ),
                          )
                          .toList(),
                    ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
                    const SizedBox(height: 24),
                  ],

                  // Room availability
                  if (listing.totalRoom != null ||
                      listing.roomAvailable != null) ...[
                    Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              if (listing.totalRoom != null)
                                _statItem(
                                  'Total Rooms',
                                  '${listing.totalRoom}',
                                  theme,
                                ),
                              if (listing.roomAvailable != null)
                                _statItem(
                                  'Available',
                                  '${listing.roomAvailable}',
                                  theme,
                                ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 650.ms, duration: 400.ms)
                        .slideY(
                          begin: 0.05,
                          end: 0,
                          delay: 650.ms,
                          duration: 400.ms,
                        ),
                    const SizedBox(height: 24),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child:
              Container(
                    decoration: BoxDecoration(
                      gradient: RentoTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: RentoTheme.primaryColor.withValues(
                            alpha: 0.35,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          final uid = AuthService.instance.currentUserUid;
                          if (listing.id == uid) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'You cannot book your own property!',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          context.push(
                            '/payment-option?listingId=${listing.id}',
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                l.get('bookNow'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 500.ms)
                  .slideY(
                    begin: 0.3,
                    end: 0,
                    delay: 300.ms,
                    duration: 500.ms,
                    curve: Curves.easeOut,
                  ),
        ),
      ),
    );
  }

  Widget _priceItem(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: RentoTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _infoChip(IconData icon, String label, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey[100],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: RentoTheme.primaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: RentoTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
        ),
      ],
    );
  }
}
