import 'package:flutter/material.dart';
import '../../backend/database_service.dart';
import '../../backend/models/listing_row.dart';
import '../../components/property_card.dart';
import '../../components/common_widgets.dart';
import '../../l10n/localizations.dart';

class FilterPage extends StatefulWidget {
  const FilterPage({super.key});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  String? _propertyType;
  String? _roomType;
  String? _amenity;
  String _distance = 'Within 1 km';
  final _minController = TextEditingController();
  final _maxController = TextEditingController();
  List<ListingRow> _results = [];
  bool _loading = false;
  bool _applied = false;

  static const _propertyTypes = ['House', 'Hostel', 'PG', 'Flat'];
  static const _roomTypes = [
    'Single',
    'Double',
    'Triple',
    'Shared',
    'Private',
    'Studio',
    '1 BHK',
    '2 BHK',
    '3 BHK',
  ];
  static const _amenities = [
    'WiFi',
    'Parking',
    'AC',
    'Swimming',
    'Gym',
    'Food Serve',
    'Security',
    'Laundry',
  ];
  static const _amenityIcons = <IconData>[
    Icons.wifi_rounded,
    Icons.local_parking_rounded,
    Icons.ac_unit_rounded,
    Icons.pool_rounded,
    Icons.directions_run,
    Icons.restaurant_rounded,
    Icons.security_rounded,
    Icons.local_laundry_service_rounded,
  ];
  static const _distances = [
    'Within 1 km',
    'Within 2 km',
    'Within 5 km',
    'No Preference',
  ];

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _propertyType = null;
      _roomType = null;
      _amenity = null;
      _distance = 'Within 1 km';
      _minController.clear();
      _maxController.clear();
      _results = [];
      _applied = false;
    });
  }

  Future<void> _apply() async {
    setState(() {
      _loading = true;
      _applied = true;
    });
    try {
      final min = int.tryParse(_minController.text.trim());
      final max = int.tryParse(_maxController.text.trim());
      var results = await DatabaseService.instance.getListings(
        propertyType: _propertyType,
        minPrice: min,
        maxPrice: max,
      );
      if (_roomType != null) {
        results = results.where((l) => l.roomType == _roomType).toList();
      }
      if (_amenity != null) {
        results = results
            .where(
              (l) => l.amenities.any(
                (a) => a.toLowerCase().contains(_amenity!.toLowerCase()),
              ),
            )
            .toList();
      }
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = RentoLocalizations.of(context);

    if (_applied) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Filter Results'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => setState(() => _applied = false),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _results.isEmpty
            ? EmptyState(
                icon: Icons.search_off,
                title: l.get('noResults'),
                onAction: () => setState(() => _applied = false),
                actionLabel: 'Adjust Filters',
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _results.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: PropertyCard(listing: _results[i]),
                ),
              ),
      );
    }

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 24),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Filter',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton(
                onPressed: _reset,
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.tertiary,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Reset'),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: true,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Property Type
                  _FilterSection(
                    title: 'Property Type',
                    child: _ChipGroup(
                      items: _propertyTypes,
                      selected: _propertyType,
                      onSelect: (v) => setState(
                        () => _propertyType = _propertyType == v ? null : v,
                      ),
                    ),
                  ),
                  _sectionDivider,

                  // Room Type
                  _FilterSection(
                    title: 'Room Type',
                    child: _ChipGroup(
                      items: _roomTypes,
                      selected: _roomType,
                      onSelect: (v) =>
                          setState(() => _roomType = _roomType == v ? null : v),
                    ),
                  ),
                  _sectionDivider,

                  // Amenities
                  _FilterSection(
                    title: 'Amenities',
                    child: _IconChipGroup(
                      items: _amenities,
                      icons: _amenityIcons,
                      selected: _amenity,
                      onSelect: (v) =>
                          setState(() => _amenity = _amenity == v ? null : v),
                    ),
                  ),
                  _sectionDivider,

                  // Price Range
                  _FilterSection(
                    title: 'Price Range',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _PriceField(
                          label: 'Min amount',
                          hint: '0',
                          controller: _minController,
                        ),
                        _PriceField(
                          label: 'Max amount',
                          hint: '0',
                          controller: _maxController,
                        ),
                      ],
                    ),
                  ),
                  _sectionDivider,

                  // Distance
                  _FilterSection(
                    title: 'Distance',
                    child: _ChipGroup(
                      items: _distances,
                      selected: _distance,
                      onSelect: (v) => setState(() => _distance = v),
                    ),
                  ),
                  _sectionDivider,

                  // Apply
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _apply,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.scaffoldBackgroundColor,
                        foregroundColor: theme.colorScheme.error,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        textStyle: theme.textTheme.labelLarge,
                      ),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget get _sectionDivider => const Padding(
    padding: EdgeInsets.symmetric(vertical: 24),
    child: Divider(height: 1, thickness: 1),
  );
}

// ── Reusable section wrapper ────────────────────────────────

class _FilterSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _FilterSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

// ── Chip group (text only, single select) ───────────────────

class _ChipGroup extends StatelessWidget {
  final List<String> items;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _ChipGroup({
    required this.items,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final altColor = Colors.grey[300]!;
    final theme = Theme.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = selected == item;
        return GestureDetector(
          onTap: () => onSelect(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected ? altColor : theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: altColor),
            ),
            child: Text(
              item,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Chip group with icon (amenities) ────────────────────────

class _IconChipGroup extends StatelessWidget {
  final List<String> items;
  final List<IconData> icons;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _IconChipGroup({
    required this.items,
    required this.icons,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final altColor = Colors.grey[300]!;
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(items.length, (i) {
        final isSelected = selected == items[i];
        return GestureDetector(
          onTap: () => onSelect(items[i]),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected ? altColor : theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: altColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icons[i],
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  items[i],
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ── Price text field ─────────────────────────────────────────

class _PriceField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;

  const _PriceField({
    required this.label,
    required this.hint,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final altColor = Colors.grey[300]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        SizedBox(
          width: 150,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: theme.textTheme.labelMedium,
              filled: true,
              fillColor: theme.scaffoldBackgroundColor,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: altColor, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(8),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.error),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.error),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
