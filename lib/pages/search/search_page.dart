import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../backend/database_service.dart';
import '../../backend/models/listing_row.dart';
import '../../components/property_card.dart';
import '../../components/common_widgets.dart';
import '../../l10n/localizations.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchCtrl = TextEditingController();
  List<ListingRow> _results = [];
  List<String> _recentSearches = [];
  bool _loading = false;
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }

  Future<void> _saveRecent(String query) async {
    final prefs = await SharedPreferences.getInstance();
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.sublist(0, 10);
    }
    await prefs.setStringList('recent_searches', _recentSearches);
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _searched = true;
    });
    await _saveRecent(query.trim());
    try {
      final results = await DatabaseService.instance.getListings(
        city: query.trim(),
      );
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = RentoLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l.get('search'),
            border: InputBorder.none,
            filled: false,
          ),
          onSubmitted: _search,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _search(_searchCtrl.text),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_searched
          ? _buildRecentSearches(theme)
          : _results.isEmpty
          ? EmptyState(
              icon: Icons.search_off,
              title: l.get('noResults'),
              subtitle: 'Try a different search term',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _results.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PropertyCard(listing: _results[index]),
              ),
            ),
    );
  }

  Widget _buildRecentSearches(ThemeData theme) {
    if (_recentSearches.isEmpty) {
      return const Center(child: Text('Search for properties by city or name'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Recent Searches',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._recentSearches.map(
          (s) => ListTile(
            leading: const Icon(Icons.history),
            title: Text(s),
            trailing: const Icon(Icons.north_west, size: 16),
            onTap: () {
              _searchCtrl.text = s;
              _search(s);
            },
          ),
        ),
      ],
    );
  }
}
