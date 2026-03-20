import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class PlacesSearchBar extends StatefulWidget {
  final Function(double lat, double lng, String address) onPlaceSelected;
  final VoidCallback? onCleared;

  const PlacesSearchBar({
    super.key,
    required this.onPlaceSelected,
    this.onCleared,
  });

  @override
  State<PlacesSearchBar> createState() => _PlacesSearchBarState();
}

class _PlacesSearchBarState extends State<PlacesSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _placePredictions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
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
      if (widget.onCleared != null) widget.onCleared!();
      return;
    }

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
    setState(() {
      _isLoading = true;
      _placePredictions = [];
      _searchController.text = description;
    });

    final apiKey = AppConfig.googleMapsApiKey;
    if (apiKey.isEmpty) {
      setState(() => _isLoading = false);
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

          widget.onPlaceSelected(lat, lng, description);
        }
      }
    } catch (e) {
      debugPrint('Place details error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search city or neighborhood...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _placePredictions = []);
                        if (widget.onCleared != null) widget.onCleared!();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onChanged: _fetchAutocompleteSuggestions,
          ),
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: LinearProgressIndicator(),
          ),
        if (_placePredictions.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 250),
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
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
                    color: Colors.blueGrey,
                  ),
                  title: Text(pred['description']),
                  onTap: () =>
                      _getPlaceDetails(pred['place_id'], pred['description']),
                );
              },
            ),
          ),
      ],
    );
  }
}
