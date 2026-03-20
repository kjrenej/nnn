import 'package:flutter/material.dart';
import '../../auth/auth_service.dart';
import '../../backend/database_service.dart';
import '../../backend/models/listing_row.dart';
import '../../components/property_card.dart';
import '../../components/common_widgets.dart';

class FavouritesPage extends StatefulWidget {
  const FavouritesPage({super.key});

  @override
  State<FavouritesPage> createState() => _FavouritesPageState();
}

class _FavouritesPageState extends State<FavouritesPage> {
  List<ListingRow> _listings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final uid = AuthService.instance.currentUserUid;
      final favs = await DatabaseService.instance.getFavourites(uid);
      final listingIds = favs.map((f) => f.favourite).whereType<String>();
      final all = await DatabaseService.instance.getListings();
      _listings = all.where((l) => listingIds.contains(l.id)).toList();
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Favourites')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _listings.isEmpty
          ? const EmptyState(
              icon: Icons.favorite_border,
              title: 'No favourites yet',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _listings.length,
              itemBuilder: (context, i) {
                return PropertyCard(listing: _listings[i]);
              },
            ),
    );
  }
}
