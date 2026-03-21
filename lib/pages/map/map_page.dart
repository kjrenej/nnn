import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../backend/database_service.dart';
import '../../backend/models/listing_row.dart';
import '../../config/constants.dart';
import '../../l10n/localizations.dart';
import '../../components/places_search_bar.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _mapController = Completer();

  List<ListingRow> _allListings = [];
  List<ListingRow> _filteredListings = [];
  Set<Marker> _markers = {};
  bool _loading = true;

  String? _selectedType;
  ListingRow? _selectedListing;

  static const _defaultCamera = CameraPosition(
    target: LatLng(22.5937, 78.9629),
    zoom: 5,
  );

  static final _markerHues = <String, double>{
    'House': BitmapDescriptor.hueBlue,
    'Flat': BitmapDescriptor.hueViolet,
    'Hostel': BitmapDescriptor.hueOrange,
    'PG': BitmapDescriptor.hueGreen,
  };

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  Future<void> _loadListings() async {
    try {
      final listings = await DatabaseService.instance.getListings(limit: 200);
      if (mounted) {
        setState(() {
          _allListings = listings;
          _loading = false;
        });
        _applyFilter();
      }
    } catch (e, s) {
      debugPrint('MapPage._loadListings error: $e\n$s');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final filtered = _allListings.where((l) {
      final hasCoords = l.latitude != null && l.longitude != null;
      final matchesType =
          _selectedType == null || l.propertyType == _selectedType;
      return hasCoords && matchesType;
    }).toList();

    final markers = <Marker>{};
    for (final listing in filtered) {
      markers.add(
        Marker(
          markerId: MarkerId(listing.id),
          position: LatLng(listing.latitude!, listing.longitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _markerHues[listing.propertyType] ?? BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: listing.propertyName ?? 'Property',
            snippet: listing.price != null ? '₹${listing.price}/mo' : '',
          ),
          onTap: () => _onMarkerTapped(listing),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _filteredListings = filtered;
        _markers = markers;
        _selectedListing = null;
      });
    }

    _fitBounds(filtered);
  }

  Future<void> _loadRadiusListings(
    double lat,
    double lng,
    String address,
  ) async {
    if (mounted) setState(() => _loading = true);
    try {
      final listings = await DatabaseService.instance.getListingsInRadius(
        lat,
        lng,
        radiusKm: 10.0,
      );
      if (mounted) {
        setState(() {
          _allListings = listings;
          _loading = false;
        });
        _applyFilter();
      }

      if (_mapController.isCompleted) {
        final controller = await _mapController.future;
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(lat, lng), 12),
        );
      }
    } catch (e, s) {
      debugPrint('MapPage._loadRadiusListings error: $e\n$s');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fitBounds(List<ListingRow> listings) async {
    // FIX: Guard against calling future before map is created.
    // Previously this could hang indefinitely if called before onMapCreated.
    if (listings.isEmpty || !mounted || !_mapController.isCompleted) return;

    final controller = await _mapController.future;

    if (listings.length == 1) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(listings.first.latitude!, listings.first.longitude!),
          14,
        ),
      );
      return;
    }

    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    for (final l in listings) {
      if (l.latitude! < minLat) minLat = l.latitude!;
      if (l.latitude! > maxLat) maxLat = l.latitude!;
      if (l.longitude! < minLng) minLng = l.longitude!;
      if (l.longitude! > maxLng) maxLng = l.longitude!;
    }

    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        60,
      ),
    );
  }

  void _onMarkerTapped(ListingRow listing) {
    if (mounted) setState(() => _selectedListing = listing);
  }

  void _onTypeSelected(String? type) {
    if (mounted) setState(() => _selectedType = type);
    _applyFilter();
  }

  @override
  Widget build(BuildContext context) {
    final l = RentoLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: _defaultCamera,
                  markers: _markers,
                  onMapCreated: (controller) {
                    if (!_mapController.isCompleted) {
                      _mapController.complete(controller);
                    }
                    // FIX: After map is created, fit bounds if listings are available
                    if (_filteredListings.isNotEmpty) {
                      _fitBounds(_filteredListings);
                    }
                  },
                  onTap: (_) {
                    if (mounted) setState(() => _selectedListing = null);
                  },
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),

                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 12,
                  right: 12,
                  child: Column(
                    children: [
                      PlacesSearchBar(
                        onPlaceSelected: _loadRadiusListings,
                        onCleared: _loadListings,
                      ),
                      const SizedBox(height: 8),
                      _buildTypeChips(theme),
                      const SizedBox(height: 8),
                      if (_filteredListings.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_filteredListings.length} properties found',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                Positioned(
                  right: 12,
                  bottom: _selectedListing != null ? 290 : 24,
                  child: Column(
                    children: [
                      _mapButton(Icons.add, () async {
                        if (!_mapController.isCompleted) return;
                        final c = await _mapController.future;
                        c.animateCamera(CameraUpdate.zoomIn());
                      }),
                      const SizedBox(height: 8),
                      _mapButton(Icons.remove, () async {
                        if (!_mapController.isCompleted) return;
                        final c = await _mapController.future;
                        c.animateCamera(CameraUpdate.zoomOut());
                      }),
                      const SizedBox(height: 8),
                      _mapButton(Icons.my_location, () {
                        _fitBounds(_filteredListings);
                      }),
                    ],
                  ),
                ),

                if (_selectedListing != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _buildPropertyCard(theme, _selectedListing!),
                  ),

                if (!_loading && _filteredListings.isEmpty)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: theme.cardColor.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selectedType != null
                                ? 'No $_selectedType properties found in this area'
                                : 'No properties found in this area',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildTypeChips(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: const Text('All'),
                selected: _selectedType == null,
                onSelected: (_) => _onTypeSelected(null),
                selectedColor: theme.colorScheme.primary,
                labelStyle: TextStyle(
                  color: _selectedType == null ? Colors.white : null,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            ...AppConstants.propertyTypes.map((type) {
              final isSelected = _selectedType == type;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (_) =>
                      _onTypeSelected(isSelected ? null : type),
                  selectedColor: theme.colorScheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : null,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  avatar: isSelected ? null : Icon(_typeIcon(type), size: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'House':
        return Icons.house;
      case 'Flat':
        return Icons.apartment;
      case 'Hostel':
        return Icons.domain;
      case 'PG':
        return Icons.people;
      default:
        return Icons.home;
    }
  }

  Widget _mapButton(IconData icon, VoidCallback onTap) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }

  Widget _buildPropertyCard(ThemeData theme, ListingRow listing) {
    final imageUrl = listing.images.isNotEmpty ? listing.images.first : null;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (ctx, url) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (ctx, url, err) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.home, size: 40),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child:
                                const Icon(Icons.home_outlined, size: 40),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.propertyName ?? 'Property',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        children: [
                          if (listing.propertyType != null)
                            _miniTag(listing.propertyType!, theme),
                          if (listing.furnishing != null)
                            _miniTag(listing.furnishing!, theme),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              [listing.city, listing.state]
                                  .where((e) => e != null && e.isNotEmpty)
                                  .join(', '),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[500],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (listing.price != null)
                            Text(
                              '₹${listing.price}/mo',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          const Spacer(),
                          if (listing.beds != null)
                            _featureIcon(Icons.bed, '${listing.beds}'),
                          if (listing.washrooms != null) ...[
                            const SizedBox(width: 10),
                            _featureIcon(
                              Icons.bathtub_outlined,
                              listing.washrooms!,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    context.push('/property-detail?id=${listing.id}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'View Details',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniTag(String label, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _featureIcon(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
    );
  }
}