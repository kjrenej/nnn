import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/auth_service.dart';
import '../../backend/database_service.dart';
import '../../backend/storage_service.dart';
import '../../backend/models/listing_row.dart';
import '../../config/constants.dart';
import '../../config/app_config.dart';
import '../../components/map_picker_widget.dart';

class AddListingPage extends StatefulWidget {
  final String? listingId;
  const AddListingPage({super.key, this.listingId});

  @override
  State<AddListingPage> createState() => _AddListingPageState();
}

class _AddListingPageState extends State<AddListingPage> {
  final _formKey = GlobalKey<FormState>();
  int _step = 0;
  bool _saving = false;
  bool _loading = false;
  List<String> _existingImages = [];

  // Basic
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _propertyType = AppConstants.propertyTypes.first;
  String _roomType = AppConstants.roomTypes.first;
  String _furnishing = AppConstants.furnishingTypes.first;

  // Location
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  double? _latitude;
  double? _longitude;

  // Pricing
  final _priceCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();
  final _maintenanceCtrl = TextEditingController();

  // Details
  final _bedsCtrl = TextEditingController(text: '1');
  final _washroomsCtrl = TextEditingController(text: '1');
  final _areaCtrl = TextEditingController();
  final _floorCtrl = TextEditingController();
  final _totalFloorsCtrl = TextEditingController();
  final List<String> _selectedAmenities = [];

  // Images
  final List<XFile> _images = [];
  final Map<String, Uint8List> _imageBytes = {};
  final _picker = ImagePicker();

  static const _stepTitles = [
    'Basic Info',
    'Location',
    'Pricing & Details',
    'Images',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.listingId != null) _loadListing(widget.listingId!);
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _descCtrl, _addressCtrl, _cityCtrl, _stateCtrl,
      _pincodeCtrl, _priceCtrl, _depositCtrl, _maintenanceCtrl,
      _bedsCtrl, _washroomsCtrl, _areaCtrl, _floorCtrl, _totalFloorsCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadListing(String id) async {
    setState(() => _loading = true);
    try {
      final listing = await DatabaseService.instance.getListing(id);
      if (listing != null && mounted) {
        setState(() {
          _nameCtrl.text = listing.propertyName ?? '';
          _descCtrl.text = listing.description ?? '';
          if (AppConstants.propertyTypes.contains(listing.propertyType)) {
            _propertyType = listing.propertyType!;
          }
          if (AppConstants.roomTypes.contains(listing.roomType)) {
            _roomType = listing.roomType!;
          }
          if (AppConstants.furnishingTypes.contains(listing.furnishing)) {
            _furnishing = listing.furnishing!;
          }
          _addressCtrl.text = listing.propertyAddress ?? '';
          _cityCtrl.text = listing.city ?? '';
          _stateCtrl.text = listing.state ?? '';
          _pincodeCtrl.text = (listing.pincode ?? '').toString();
          _latitude = listing.latitude;
          _longitude = listing.longitude;
          _priceCtrl.text = (listing.price ?? '').toString();
          _depositCtrl.text = (listing.securityDeposit ?? '').toString();
          _maintenanceCtrl.text = (listing.monthlyMaintenance ?? '').toString();
          _bedsCtrl.text = (listing.beds ?? '1').toString();
          _washroomsCtrl.text = listing.washrooms ?? '1';
          _areaCtrl.text = listing.area ?? '';
          _floorCtrl.text = listing.floorInHouse ?? '';
          _totalFloorsCtrl.text = (listing.totalFloor ?? '').toString();
          _selectedAmenities
            ..clear()
            ..addAll(listing.amenities);
          _existingImages = List<String>.from(listing.images);
        });
      }
    } catch (e) {
      debugPrint('Error loading listing: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 75);
    if (picked.isNotEmpty) {
      for (final img in picked) {
        final bytes = await img.readAsBytes();
        _imageBytes[img.name] = bytes;
      }
      setState(() => _images.addAll(picked));
    }
  }

  bool _validateCurrentStep() {
    switch (_step) {
      case 0:
        if (_nameCtrl.text.trim().isEmpty) {
          _showError('Property name is required');
          return false;
        }
        return true;
      case 1:
        if (_addressCtrl.text.trim().isEmpty) {
          _showError('Address is required');
          return false;
        }
        if (_cityCtrl.text.trim().isEmpty) {
          _showError('City is required');
          return false;
        }
        if (_latitude == null || _longitude == null) {
          _showError('Please select location on the map');
          return false;
        }
        return true;
      case 2:
        if (_priceCtrl.text.trim().isEmpty) {
          _showError('Monthly rent is required');
          return false;
        }
        return true;
      case 3:
        if (_images.isEmpty && _existingImages.isEmpty) {
          _showError('Please add at least one image');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _next() {
    if (!_validateCurrentStep()) return;
    if (_step < 3) setState(() => _step++);
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _submit() async {
    if (!_validateCurrentStep()) return;
    setState(() => _saving = true);
    try {
      final entries = <MapEntry<String, Uint8List>>[];
      for (final img in _images) {
        final bytes = _imageBytes[img.name] ?? await img.readAsBytes();
        entries.add(MapEntry(img.name, bytes));
      }
      final urls = await StorageService.instance.uploadFiles(
        bucketName: AppConfig.storageBucket,
        files: entries,
      );

      final allImages = [..._existingImages, ...urls];
      final uid = AuthService.instance.currentUserUid;
      final isEdit = widget.listingId != null;
      final targetId = isEdit ? widget.listingId! : uid;

      final listingData = ListingRow(
        id: targetId,
        propertyName: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        propertyType: _propertyType,
        roomType: _roomType,
        furnishing: _furnishing,
        propertyAddress: _addressCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        state: _stateCtrl.text.trim(),
        pincode: int.tryParse(_pincodeCtrl.text.trim()),
        price: int.tryParse(_priceCtrl.text.trim()),
        securityDeposit: int.tryParse(_depositCtrl.text.trim()),
        monthlyMaintenance: int.tryParse(_maintenanceCtrl.text.trim()),
        beds: int.tryParse(_bedsCtrl.text.trim()),
        washrooms: _washroomsCtrl.text.trim(),
        area: _areaCtrl.text.trim(),
        floorInHouse: _floorCtrl.text.trim(),
        totalFloor: int.tryParse(_totalFloorsCtrl.text.trim()),
        amenities: _selectedAmenities,
        images: allImages,
        latitude: _latitude,
        longitude: _longitude,
      );

      if (isEdit) {
        await DatabaseService.instance.updateListing(targetId, listingData.toJson());
      } else {
        await DatabaseService.instance.insertListing(listingData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit
                ? 'Listing updated successfully!'
                : 'Listing created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.listingId != null;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(isEdit ? 'Edit Property' : 'Add Property')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Property' : 'Add Property'),
      ),
      body: Column(
        children: [
          // ── Custom step indicator (no InkWell/mouse issues) ──
          _StepIndicator(
            currentStep: _step,
            titles: _stepTitles,
          ),

          // ── Step content ──
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildStepContent(theme),
              ),
            ),
          ),

          // ── Navigation buttons ──
          _buildNavBar(theme, isEdit),
        ],
      ),
    );
  }

  // ── Step content switcher ────────────────────────────────

  Widget _buildStepContent(ThemeData theme) {
    switch (_step) {
      case 0:
        return _buildBasicInfo(theme);
      case 1:
        return _buildLocation(theme);
      case 2:
        return _buildPricingDetails(theme);
      case 3:
        return _buildImages(theme);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step 0: Basic Info ───────────────────────────────────

  Widget _buildBasicInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _nameCtrl,
          decoration: const InputDecoration(labelText: 'Property Name'),
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _descCtrl,
          decoration: const InputDecoration(labelText: 'Description'),
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _propertyType,
          decoration: const InputDecoration(labelText: 'Property Type'),
          items: AppConstants.propertyTypes
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (v) => setState(() => _propertyType = v!),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _roomType,
          decoration: const InputDecoration(labelText: 'Room Type'),
          items: AppConstants.roomTypes
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (v) => setState(() => _roomType = v!),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _furnishing,
          decoration: const InputDecoration(labelText: 'Furnishing'),
          items: AppConstants.furnishingTypes
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (v) => setState(() => _furnishing = v!),
        ),
      ],
    );
  }

  // ── Step 1: Location ─────────────────────────────────────

  Widget _buildLocation(ThemeData theme) {
    return Column(
      children: [
        SizedBox(
          height: 400,
          child: MapLocationPicker(
            initialLat: _latitude,
            initialLng: _longitude,
            onLocationSelected: (lat, lng, address, city, state) {
              setState(() {
                _latitude = lat;
                _longitude = lng;
                _addressCtrl.text = address;
                _cityCtrl.text = city;
                _stateCtrl.text = state;
              });
            },
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressCtrl,
          decoration: const InputDecoration(labelText: 'Address'),
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _cityCtrl,
                decoration: const InputDecoration(labelText: 'City'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _stateCtrl,
                decoration: const InputDecoration(labelText: 'State'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _pincodeCtrl,
          decoration: const InputDecoration(labelText: 'Pincode'),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  // ── Step 2: Pricing & Details ────────────────────────────

  Widget _buildPricingDetails(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _priceCtrl,
          decoration: const InputDecoration(labelText: 'Monthly Rent (₹)'),
          keyboardType: TextInputType.number,
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _depositCtrl,
          decoration: const InputDecoration(labelText: 'Security Deposit (₹)'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _maintenanceCtrl,
          decoration: const InputDecoration(labelText: 'Monthly Maintenance (₹)'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _bedsCtrl,
                decoration: const InputDecoration(labelText: 'Bedrooms'),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _washroomsCtrl,
                decoration: const InputDecoration(labelText: 'Washrooms'),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _areaCtrl,
          decoration: const InputDecoration(labelText: 'Area (sq ft)'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _floorCtrl,
                decoration: const InputDecoration(labelText: 'Floor'),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _totalFloorsCtrl,
                decoration: const InputDecoration(labelText: 'Total Floors'),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Amenities', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: AppConstants.amenities.map((a) {
            final selected = _selectedAmenities.contains(a);
            return FilterChip(
              label: Text(a),
              selected: selected,
              onSelected: (v) {
                setState(() {
                  if (v) {
                    _selectedAmenities.add(a);
                  } else {
                    _selectedAmenities.remove(a);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Step 3: Images ───────────────────────────────────────

  Widget _buildImages(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Add Images'),
        ),
        if (_existingImages.isNotEmpty || _images.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (int i = 0; i < _existingImages.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _existingImages[i],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _existingImages.removeAt(i)),
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.red,
                              child: Icon(Icons.close,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                for (int i = 0; i < _images.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _imageBytes[_images[i].name] != null
                              ? Image.memory(
                                  _imageBytes[_images[i].name]!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                )
                              : const SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              final name = _images[i].name;
                              setState(() {
                                _images.removeAt(i);
                                _imageBytes.remove(name);
                              });
                            },
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.red,
                              child: Icon(Icons.close,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_existingImages.length + _images.length} images selected',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  // ── Bottom nav bar ────────────────────────────────────────

  Widget _buildNavBar(ThemeData theme, bool isEdit) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_step > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _back,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_step > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _saving
                  ? null
                  : (_step < 3 ? _next : _submit),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _step < 3
                          ? 'Continue'
                          : (isEdit ? 'Update Listing' : 'Submit Listing'),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom step indicator ─────────────────────────────────
// Uses plain Container + Text — no InkWell, no mouse tracking.

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> titles;

  const _StepIndicator({
    required this.currentStep,
    required this.titles,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: List.generate(titles.length, (i) {
          final isDone = i < currentStep;
          final isActive = i == currentStep;

          return Expanded(
            child: Row(
              children: [
                // Circle
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? primary
                        : isActive
                            ? primary
                            : (isDark ? Colors.grey[700] : Colors.grey[300]),
                  ),
                  alignment: Alignment.center,
                  child: isDone
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isActive
                                ? Colors.white
                                : (isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600]),
                          ),
                        ),
                ),
                const SizedBox(width: 6),
                // Label (only show on active step to save space)
                if (isActive)
                  Flexible(
                    child: Text(
                      titles[i],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: primary,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                // Connector line
                if (i < titles.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: i < currentStep
                          ? primary
                          : (isDark ? Colors.grey[700] : Colors.grey[300]),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}