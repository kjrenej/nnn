import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

// NOTE: Remove `package:geocoding` from pubspec.yaml if nothing else uses it.

class MapLocationPicker extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final Function(
    double lat,
    double lng,
    String address,
    String city,
    String state,
  ) onLocationSelected;

  const MapLocationPicker({
    super.key,
    this.initialLat,
    this.initialLng,
    required this.onLocationSelected,
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  // ── Map ──────────────────────────────────────────────────────────
  final Completer<GoogleMapController> _controller = Completer();
  GoogleMapController? _mapController;
  late CameraPosition _currentCameraPos;
  bool _isMapIdle = true;

  // ── Search ────────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _placePredictions = [];
  bool _isSearching = false;

  // ── Pending camera move (map not ready yet) ───────────────────────
  LatLng? _pendingCameraTarget;
  double? _pendingCameraZoom;

  // ── Debounces ─────────────────────────────────────────────────────
  Timer? _autocompleteDebounce;
  Timer? _idleDebounce; // prevents geocode firing mid-drag

  @override
  void initState() {
    super.initState();
    _currentCameraPos = CameraPosition(
      target: LatLng(
        widget.initialLat ?? 22.5937,
        widget.initialLng ?? 78.9629,
      ),
      zoom: widget.initialLat != null ? 15 : 5,
    );

    if (widget.initialLat != null) {
      _updateAddressFromCamera(_currentCameraPos.target);
    }

    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _autocompleteDebounce?.cancel();
    _idleDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ── Autocomplete ──────────────────────────────────────────────────

  void _onSearchChanged(String input) {
    _autocompleteDebounce?.cancel();
    if (input.trim().isEmpty) {
      setState(() => _placePredictions = []);
      return;
    }
    _autocompleteDebounce = Timer(const Duration(milliseconds: 400), () {
      _fetchAutocompleteSuggestions(input.trim());
    });
  }

  Future<void> _fetchAutocompleteSuggestions(String input) async {
    final apiKey = AppConfig.googleMapsApiKey;
    if (apiKey.isEmpty) return;

    Uri url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json',
    ).replace(queryParameters: {'input': input, 'key': apiKey});

    if (kIsWeb) {
      url = Uri.parse(
        'https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(url.toString())}',
      );
    }

    try {
      final response = await http.get(url);
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['status'] == 'OK') {
          setState(() => _placePredictions = data['predictions'] as List);
        }
      }
    } catch (e) {
      debugPrint('Autocomplete error: $e');
    }
  }

  Future<void> _getPlaceDetails(String placeId, String description) async {
    setState(() {
      _placePredictions = [];
      _searchController.text = description;
      _isSearching = true;
    });

    final apiKey = AppConfig.googleMapsApiKey;
    if (apiKey.isEmpty) {
      setState(() => _isSearching = false);
      return;
    }

    Uri url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json',
    ).replace(queryParameters: {'place_id': placeId, 'key': apiKey});

    if (kIsWeb) {
      url = Uri.parse(
        'https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(url.toString())}',
      );
    }

    try {
      final response = await http.get(url);
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['status'] == 'OK') {
          final location = data['result']['geometry']['location'];
          final lat = (location['lat'] as num).toDouble();
          final lng = (location['lng'] as num).toDouble();
          final target = LatLng(lat, lng);

          if (_mapController != null) {
            await _mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(target, 16),
            );
          } else {
            _pendingCameraTarget = target;
            _pendingCameraZoom = 16;
            _currentCameraPos = CameraPosition(target: target, zoom: 16);
          }

          await _updateAddressFromCamera(target);
        }
      }
    } catch (e) {
      debugPrint('Place details error: $e');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  // ── Reverse geocoding — Google Geocoding API ──────────────────────
  //
  // Uses the same API key already in AppConfig. Returns structured
  // address_components so city/state extraction is always null-safe.
  //
  // IMPORTANT: Enable "Geocoding API" in Google Cloud Console for the
  // same key you use for Maps SDK and Places API.

  Future<void> _updateAddressFromCamera(LatLng target) async {
    final apiKey = AppConfig.googleMapsApiKey;
    if (apiKey.isEmpty) return;

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json',
    ).replace(queryParameters: {
      'latlng': '${target.latitude},${target.longitude}',
      'key': apiKey,
    });

    try {
      final response = await http.get(url);
      if (!mounted) return;

      if (response.statusCode != 200) return;

      final data = json.decode(response.body) as Map<String, dynamic>;
      final status = data['status'] as String?;

      if (status != 'OK') {
        debugPrint('Geocoding API status: $status');
        return;
      }

      final results = data['results'] as List?;
      if (results == null || results.isEmpty) return;

      // results[0] is always the most specific result for the pin location.
      final formattedAddress =
          results[0]['formatted_address'] as String? ?? '';

      // Walk address_components to extract city and state reliably.
      // Google guarantees these keys exist when the type matches — no nulls.
      String city = '';
      String state = '';

      final components = results[0]['address_components'] as List? ?? [];
      for (final component in components) {
        final types = (component['types'] as List).cast<String>();
        final longName = component['long_name'] as String? ?? '';

        if (types.contains('locality') && city.isEmpty) {
          city = longName;
        }
        // Fallback if no locality (e.g. rural areas).
        if (types.contains('sublocality_level_1') && city.isEmpty) {
          city = longName;
        }
        if (types.contains('administrative_area_level_1')) {
          state = longName;
        }
      }

      // Last resort: check the next result's components for locality.
      if (city.isEmpty && results.length > 1) {
        final fallback = results[1]['address_components'] as List? ?? [];
        for (final component in fallback) {
          final types = (component['types'] as List).cast<String>();
          if (types.contains('locality')) {
            city = component['long_name'] as String? ?? '';
            break;
          }
        }
      }

      setState(() => _searchController.text = formattedAddress);

      widget.onLocationSelected(
        target.latitude,
        target.longitude,
        formattedAddress,
        city,
        state,
      );
    } catch (e) {
      // Do not rethrow — a failed geocode should never crash the map.
      debugPrint('Reverse geocoding error: $e');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Search bar ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              TextFormField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search Address',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _placePredictions = []);
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: _onSearchChanged,
              ),

              // ── Predictions dropdown ──────────────────────────────
              if (_placePredictions.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _placePredictions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final pred =
                          _placePredictions[index] as Map<String, dynamic>;
                      return ListTile(
                        leading: const Icon(
                          Icons.location_on,
                          color: Colors.grey,
                        ),
                        title: Text(pred['description'] as String? ?? ''),
                        onTap: () => _getPlaceDetails(
                          pred['place_id'] as String,
                          pred['description'] as String,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),

        // ── Map ─────────────────────────────────────────────────────
        Flexible(
          child: Stack(
            alignment: Alignment.center,
            children: [
              GoogleMap(
                initialCameraPosition: _currentCameraPos,
                onMapCreated: (controller) async {
                  _mapController = controller;
                  if (!_controller.isCompleted) {
                    _controller.complete(controller);
                  }
                  final target = _pendingCameraTarget;
                  if (target != null) {
                    final zoom = _pendingCameraZoom ?? 16;
                    _pendingCameraTarget = null;
                    _pendingCameraZoom = null;
                    await controller.animateCamera(
                      CameraUpdate.newLatLngZoom(target, zoom),
                    );
                  }
                },
                onCameraMoveStarted: () {
                  // Cancel any pending geocode the moment the user drags again.
                  _idleDebounce?.cancel();
                  setState(() => _isMapIdle = false);
                },
                onCameraMove: (pos) {
                  _currentCameraPos = pos;
                },
                onCameraIdle: () {
                  setState(() => _isMapIdle = true);
                  // Wait 500 ms after the camera fully settles before calling
                  // the Geocoding API. Prevents spamming the API mid-animation.
                  _idleDebounce?.cancel();
                  _idleDebounce = Timer(
                    const Duration(milliseconds: 500),
                    () => _updateAddressFromCamera(_currentCameraPos.target),
                  );
                },
                myLocationEnabled: !kIsWeb,
                myLocationButtonEnabled: !kIsWeb,
                zoomControlsEnabled: false,
              ),

              // Centre pin that lifts slightly while the map is moving.
              IgnorePointer(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    transform: Matrix4.translationValues(
                      0,
                      _isMapIdle ? 0 : -10,
                      0,
                    ),
                    child: const Icon(
                      Icons.location_pin,
                      size: 48,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),

              if (_isSearching)
                const Center(child: CircularProgressIndicator()),

              // Instruction chip.
              Positioned(
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Drag map to position pin exactly',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}