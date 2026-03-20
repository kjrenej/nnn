import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../backend/database_service.dart';
import '../../backend/models/listing_row.dart';
import '../../components/property_card.dart';
import '../../l10n/localizations.dart';

class CategoriesListPage extends StatefulWidget {
  const CategoriesListPage({super.key});

  @override
  State<CategoriesListPage> createState() => _CategoriesListPageState();
}

class _CategoriesListPageState extends State<CategoriesListPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // Cache loaded listings per tab to avoid refetching on tab switch
  final Map<int, List<ListingRow>> _cache = {};
  final Map<int, bool> _loading = {};
  final Map<int, String?> _error = {};

  static const _tabs = ['House', 'Hostel', 'PG', 'Flat'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadTab(_tabController.index);
      }
    });
    _loadTab(0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTab(int index) async {
    if (_cache.containsKey(index)) return;
    setState(() => _loading[index] = true);
    try {
      final listings = await DatabaseService.instance.getListings(
        propertyType: _tabs[index],
      );
      if (mounted) {
        setState(() {
          _cache[index] = listings;
          _loading[index] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error[index] = e.toString();
          _loading[index] = false;
        });
      }
    }
  }

  List<ListingRow> _filtered(int index) {
    final q = _searchController.text.trim().toLowerCase();
    final all = _cache[index] ?? [];
    if (q.isEmpty) return all;
    return all.where((l) {
      return (l.propertyName?.toLowerCase().contains(q) ?? false) ||
          (l.city?.toLowerCase().contains(q) ?? false) ||
          (l.state?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = RentoLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.get('categories'))),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search bar
          Container(
            color: theme.scaffoldBackgroundColor,
            padding: const EdgeInsets.all(16),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 4,
                    color: const Color(0x33000000),
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onChanged: (_) => setState(() {}),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: l.get('search'),
                        hintStyle: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        filled: true,
                        fillColor: theme.scaffoldBackgroundColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.menu,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      size: 24,
                    ),
                    onPressed: () => context.push('/filter'),
                  ),
                ],
              ),
            ),
          ),

          // Tabs + list
          Flexible(
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: theme.colorScheme.onSurface,
                  unselectedLabelColor: theme.colorScheme.onSurface.withValues(
                    alpha: 0.5,
                  ),
                  labelStyle: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  indicatorColor: theme.colorScheme.onSurface.withValues(
                    alpha: 0.6,
                  ),
                  tabs: const [
                    Tab(text: 'House'),
                    Tab(text: 'Hostel'),
                    Tab(text: 'PG'),
                    Tab(text: 'Flat'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: List.generate(_tabs.length, (i) {
                      return _TabContent(
                        index: i,
                        loading: _loading[i] ?? false,
                        error: _error[i],
                        listings: _filtered(i),
                        onRetry: () {
                          _cache.remove(i);
                          _loadTab(i);
                        },
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabContent extends StatelessWidget {
  final int index;
  final bool loading;
  final String? error;
  final List<ListingRow> listings;
  final VoidCallback onRetry;

  const _TabContent({
    required this.index,
    required this.loading,
    required this.error,
    required this.listings,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (listings.isEmpty) {
      return const Center(child: Text('No properties found'));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: listings.length,
      separatorBuilder: (_, _) => const SizedBox(height: 20),
      itemBuilder: (context, i) => PropertyCard(listing: listings[i]),
    );
  }
}
