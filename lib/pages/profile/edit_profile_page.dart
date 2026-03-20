import 'package:flutter/material.dart';
import '../../auth/auth_service.dart';
import '../../backend/database_service.dart';
import '../../backend/models/user_row.dart';
import '../../components/custom_alert.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _emergencyCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  UserRow? _user;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _user = await DatabaseService.instance.getUser(
        AuthService.instance.currentUserUid,
      );
      if (_user != null) {
        _nameCtrl.text = _user!.displayName ?? '';
        _phoneCtrl.text = _user!.phoneNumber ?? '';
        _addressCtrl.text = _user!.address ?? '';
        _cityCtrl.text = _user!.city ?? '';
        _stateCtrl.text = _user!.state ?? '';
        _emergencyCtrl.text = _user!.emergencyNumber ?? '';
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await DatabaseService.instance.upsertUser(
        UserRow(
          id: AuthService.instance.currentUserUid,
          displayName: _nameCtrl.text.trim(),
          phoneNumber: _phoneCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          city: _cityCtrl.text.trim(),
          state: _stateCtrl.text.trim(),
          emergencyNumber: _emergencyCtrl.text.trim(),
          role: _user?.role,
          onboardingStep: _user?.onboardingStep,
        ),
      );
      if (mounted) {
        CustomAlert.showToast(context, 'Profile updated', type: AlertType.success);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        CustomAlert.showToast(context, e.toString(), type: AlertType.error);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityCtrl,
                      decoration: const InputDecoration(labelText: 'City'),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _emergencyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact',
                  prefixIcon: Icon(Icons.emergency),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
