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

  @override
  void initState() {
    super.initState();
    if (widget.listingId != null) {
      _loadListing(widget.listingId!);
    }
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
          _selectedAmenities.addAll(listing.amenities);
          _existingImages = List<String>.from(listing.images);
        });
      }
    } catch (e) {
      debugPrint('Error loading listing: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _descCtrl,
      _addressCtrl,
      _cityCtrl,
      _stateCtrl,
      _pincodeCtrl,
      _priceCtrl,
      _depositCtrl,
      _maintenanceCtrl,
      _bedsCtrl,
      _washroomsCtrl,
      _areaCtrl,
      _floorCtrl,
      _totalFloorsCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 75);
    if (picked.isNotEmpty) {
      // Pre-load bytes for each image (needed for web-compatible preview & upload)
      for (final img in picked) {
        final bytes = await img.readAsBytes();
        _imageBytes[img.name] = bytes;
      }
      setState(() => _images.addAll(picked));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty && _existingImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select the exact location on the map in the Location step.',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      // Upload images (use pre-loaded bytes — works on web & mobile)
      final entries = <MapEntry<String, Uint8List>>[];
      for (final img in _images) {
        final bytes = _imageBytes[img.name] ?? await img.readAsBytes();
        entries.add(MapEntry(img.name, bytes));
      }
      final urls = await StorageService.instance.uploadFiles(
        bucketName: AppConfig
            .storageBucket, // Use config instead of hardcoded 'listings'
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
        await DatabaseService.instance.updateListing(
          targetId,
          listingData.toJson(),
        );
      } else {
        await DatabaseService.instance.insertListing(listingData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? 'Listing updated successfully!'
                  : 'Listing created successfully!',
            ),
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
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.listingId != null ? 'Edit Property' : 'Add Property',
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.listingId != null ? 'Edit Property' : 'Add Property',
        ),
        actions: [
          TextButton(
            onPressed: _step == 3
                ? (_saving ? null : _submit)
                : () => setState(() => _step++),
            child: Text(
              _step == 3
                  ? (widget.listingId != null ? 'Update' : 'Submit')
                  : 'Next',
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _step,
          onStepContinue: () {
            if (_step < 3) setState(() => _step++);
          },
          onStepCancel: () {
            if (_step > 0) setState(() => _step--);
          },
          controlsBuilder: (_, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  if (_step < 3)
                    ElevatedButton(
                      onPressed: details.onStepContinue,
                      child: const Text('Continue'),
                    ),
                  if (_step == 3)
                    ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              widget.listingId != null
                                  ? 'Update Listing'
                                  : 'Submit Listing',
                            ),
                    ),
                  if (_step > 0) ...[
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Back'),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Basic Info'),
              isActive: _step >= 0,
              content: Column(
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Property Name',
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _propertyType,
                    decoration: const InputDecoration(
                      labelText: 'Property Type',
                    ),
                    items: AppConstants.propertyTypes
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => _propertyType = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _roomType,
                    decoration: const InputDecoration(labelText: 'Room Type'),
                    items: AppConstants.roomTypes
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => _roomType = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _furnishing,
                    decoration: const InputDecoration(labelText: 'Furnishing'),
                    items: AppConstants.furnishingTypes
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => _furnishing = v!),
                  ),
                ],
              ),
            ),
            Step(
              title: const Text('Location'),
              isActive: _step >= 1,
              content: Column(
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
                          // Only auto-fill if the user hasn't explicitly typed something else,
                          // or just overwrite since the map pin is the source of truth.
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
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cityCtrl,
                          decoration: const InputDecoration(labelText: 'City'),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Required' : null,
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
              ),
            ),
            Step(
              title: const Text('Pricing & Details'),
              isActive: _step >= 2,
              content: Column(
                children: [
                  TextFormField(
                    controller: _priceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Monthly Rent (₹)',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _depositCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Security Deposit (₹)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _maintenanceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Monthly Maintenance (₹)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _bedsCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Bedrooms',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _washroomsCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Washrooms',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _areaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Area (sq ft)',
                    ),
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
                          decoration: const InputDecoration(
                            labelText: 'Total Floors',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Amenities', style: theme.textTheme.titleSmall),
                  ),
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
              ),
            ),
            Step(
              title: const Text('Images'),
              isActive: _step >= 3,
              content: Column(
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
                                      onTap: () {
                                        setState(() {
                                          _existingImages.removeAt(i);
                                        });
                                      },
                                      child: const CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Colors.red,
                                        child: Icon(
                                          Icons.close,
                                          size: 14,
                                          color: Colors.white,
                                        ),
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
                                                strokeWidth: 2,
                                              ),
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
                                        child: Icon(
                                          Icons.close,
                                          size: 14,
                                          color: Colors.white,
                                        ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
