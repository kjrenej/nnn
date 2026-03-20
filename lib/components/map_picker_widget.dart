import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart' as geo;

import '../config/app_config.dart';

class MapLocationPicker extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final Function(
    double lat,
    double lng,
    String address,
    String city,
    String state,
  )
  onLocationSelected;

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
  final Completer<GoogleMapController> _controller = Completer();
  GoogleMapController? _mapController;
  late CameraPosition _currentCameraPos;

  bool _isMapIdle = true;
  bool _isSearching = false;

  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _placePredictions = [];

  String _currentAddress = '';
  String _currentCity = '';
  String _currentState = '';

  LatLng? _pendingCameraTarget;
  double? _pendingCameraZoom;

  @override
  void initState() {
    super.initState();
    // Default to center of India if no initial coords
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
      if (!mounted) return;
      // Keep suffixIcon visibility in sync with controller text.
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAutocompleteSuggestions(String input) async {
    if (input.isEmpty) {
      setState(() => _placePredictions = []);
      return;
    }

    final apiKey = AppConfig.googleMapsApiKey;
    if (apiKey.isEmpty) return; // Cannot fetch without API key

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
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          setState(() {
            _placePredictions = data['predictions'];
          });
        }
      }
    } catch (e) {
      debugPrint('Autocomplete error: $e');
    }
  }

  Future<void> _getPlaceDetails(String placeId, String description) async {
    // Clear predictions
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
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final location = data['result']['geometry']['location'];
          final lat = (location['lat'] as num).toDouble();
          final lng = (location['lng'] as num).toDouble();

          final target = LatLng(lat, lng);

          // Move camera (or queue if map isn't ready yet)
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
      setState(() => _isSearching = false);
    }
  }

  Future<void> _updateAddressFromCamera(LatLng target) async {
    try {
      final placemarks = await geo.placemarkFromCoordinates(
        target.latitude,
        target.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _currentAddress =
              '${place.street}, ${place.subLocality}, ${place.locality}';
          _currentCity = place.locality ?? place.subAdministrativeArea ?? '';
          _currentState = place.administrativeArea ?? '';
          _searchController.text = _currentAddress; // Update search field
        });

        // Notify parent
        widget.onLocationSelected(
          target.latitude,
          target.longitude,
          _currentAddress,
          _currentCity,
          _currentState,
        );
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Header
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
                onChanged: _fetchAutocompleteSuggestions,
              ),
              if (_placePredictions.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  margin: const EdgeInsets.only(top: 8),
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
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _placePredictions.length,
                    itemBuilder: (context, index) {
                      final pred = _placePredictions[index];
                      return ListTile(
                        leading: const Icon(
                          Icons.location_on,
                          color: Colors.grey,
                        ),
                        title: Text(pred['description']),
                        onTap: () => _getPlaceDetails(
                          pred['place_id'],
                          pred['description'],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),

        // Map Area
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
                  setState(() => _isMapIdle = false);
                },
                onCameraMove: (pos) {
                  _currentCameraPos = pos;
                },
                onCameraIdle: () {
                  setState(() => _isMapIdle = true);
                  // Update address when map stops moving
                  _updateAddressFromCamera(_currentCameraPos.target);
                },
                myLocationEnabled: !kIsWeb,
                myLocationButtonEnabled: !kIsWeb,
                zoomControlsEnabled: false,
              ),

              // Center Marker (Fixed in center while map moves)
              IgnorePointer(
                child: Padding(
                  padding: const EdgeInsets.only(
                    bottom: 40.0,
                  ), // Adjust to point to center
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

              // Floating instructions
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
