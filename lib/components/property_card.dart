import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../backend/models/listing_row.dart';
import '../../theme/rento_theme.dart';

/// A card displaying a property listing summary matching the app design.
class PropertyCard extends StatelessWidget {
  final ListingRow listing;
  final VoidCallback? onFavourite;
  final bool isFavourite;

  const PropertyCard({
    super.key,
    required this.listing,
    this.onFavourite,
    this.isFavourite = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final imageUrl = listing.images.isNotEmpty ? listing.images.first : null;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? RentoTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image with status badge ──
          Stack(
            children: [
              Hero(
                tag: 'property-image-${listing.id}',
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, _, _) => Container(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            child: const Icon(Icons.home, size: 48),
                          ),
                        )
                      : Container(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.home_outlined, size: 48),
                          ),
                        ),
                ),
              ),
              // Status badge
              if (listing.status.isNotEmpty)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Text(
                    listing.status,
                    style: TextStyle(
                      color: RentoTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),

          // ── Info section ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type & for chips
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (listing.propertyType != null)
                      _tag(listing.propertyType!, isDark),
                    if (listing.propertyFor != null)
                      _tag(listing.propertyFor!, isDark),
                  ],
                ),
                const SizedBox(height: 10),

                // Name + Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        listing.propertyName ?? 'Property',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (listing.price != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${listing.price}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: RentoTheme.primaryColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '/ month',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 6),

                // Location
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: RentoTheme.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        [
                          listing.propertyAddress,
                          listing.city,
                          listing.state,
                        ].where((e) => e != null && e.isNotEmpty).join(', '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Features
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    if (listing.roomType != null)
                      _feature(Icons.bed_rounded, listing.roomType!),
                    if (listing.beds != null && listing.roomType == null)
                      _feature(Icons.bed_rounded, '${listing.beds} Beds'),
                    if (listing.washrooms != null)
                      _feature(Icons.bathtub_outlined, listing.washrooms!),
                    if (listing.conditioning != null)
                      _feature(Icons.ac_unit, listing.conditioning!),
                    if (listing.mealOption != null)
                      _feature(Icons.restaurant, listing.mealOption!),
                  ],
                ),
                const SizedBox(height: 14),

                // View Details button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () =>
                        context.push('/property-detail?id=${listing.id}'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? Colors.white70
                          : Colors.grey[700],
                      side: BorderSide(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white70 : Colors.grey[700],
        ),
      ),
    );
  }

  Widget _feature(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
