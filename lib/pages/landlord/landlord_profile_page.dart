import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../auth/auth_service.dart';
import '../../backend/database_service.dart';
import '../../backend/models/listing_row.dart';
import '../../backend/models/payment_details_landlord_row.dart';
import '../../components/common_widgets.dart';
import '../../components/custom_alert.dart';

class LandlordProfilePage extends StatefulWidget {
  const LandlordProfilePage({super.key});

  @override
  State<LandlordProfilePage> createState() => _LandlordProfilePageState();
}

class _LandlordProfilePageState extends State<LandlordProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<ListingRow> _listings = [];
  PaymentDetailsLandlordRow? _paymentDetails;
  bool _loading = true;

  // Payout form
  final _holderNameCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    try {
      final uid = AuthService.instance.currentUserUid;
      _listings = await DatabaseService.instance.getListingsByOwner(uid);
      _paymentDetails = await DatabaseService.instance
          .getLandlordPaymentDetails(uid);
      if (_paymentDetails != null) {
        _holderNameCtrl.text = _paymentDetails!.accountHolderName ?? '';
        _accountCtrl.text = _paymentDetails!.accountNumber ?? '';
        _ifscCtrl.text = _paymentDetails!.ifscCode ?? '';
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _savePayout() async {
    try {
      await DatabaseService.instance.upsertLandlordPaymentDetails(
        PaymentDetailsLandlordRow(
          id: AuthService.instance.currentUserUid,
          accountHolderName: _holderNameCtrl.text.trim(),
          accountNumber: _accountCtrl.text.trim(),
          ifscCode: _ifscCtrl.text.trim(),
        ),
      );
      if (mounted) {
        CustomAlert.showToast(context, 'Payout details saved', type: AlertType.success);
      }
    } catch (e) {
      if (mounted) {
        CustomAlert.showToast(context, e.toString(), type: AlertType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Landlord Dashboard')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Landlord Dashboard'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'My Listings'),
            Tab(text: 'Payout Details'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // Listings tab
          _listings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const EmptyState(
                        icon: Icons.home_work,
                        title: 'No listings yet',
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => context.push('/add-listing'),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Property'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _listings.length,
                  itemBuilder: (context, i) {
                    final l = _listings[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: l.images.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  l.images.first,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.home),
                              ),
                        title: Text(
                          l.propertyName ?? 'Untitled',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('₹${l.price ?? 0}/mo • ${l.city ?? ''}'),
                        trailing: Chip(
                          label: Text(
                            l.status == 'active' ? 'Active' : 'Inactive',
                            style: const TextStyle(fontSize: 11),
                          ),
                          backgroundColor: l.status == 'active'
                              ? Colors.green.shade100
                              : Colors.grey.shade200,
                        ),
                        onTap: () => context.push('/property/${l.id}'),
                      ),
                    );
                  },
                ),

          // Payout tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bank Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _holderNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Account Holder Name',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _accountCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Account Number',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ifscCtrl,
                  decoration: const InputDecoration(labelText: 'IFSC Code'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _savePayout,
                  child: const Text('Save Payout Details'),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-listing'),
        icon: const Icon(Icons.add),
        label: const Text('Add Listing'),
      ),
    );
  }
}
