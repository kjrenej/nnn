import 'package:flutter/material.dart';
import '../../backend/database_service.dart';
import '../../backend/models/listing_row.dart';
import '../../components/property_card.dart';
import '../../components/common_widgets.dart';

class CategoriesPage extends StatefulWidget {
  final String category;
  const CategoriesPage({super.key, required this.category});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  List<ListingRow> _listings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final listings = await DatabaseService.instance.getListings(
        propertyType: widget.category,
      );
      setState(() {
        _listings = listings;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _listings.isEmpty
          ? EmptyState(
              icon: Icons.home_outlined,
              title: 'No ${widget.category} listings',
              subtitle: 'Check back later',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _listings.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PropertyCard(listing: _listings[index]),
              ),
            ),
    );
  }
}
