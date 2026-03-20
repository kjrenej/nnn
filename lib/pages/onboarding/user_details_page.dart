import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../auth/auth_service.dart';
import '../../backend/database_service.dart';
import '../../backend/models/user_row.dart';
import '../../l10n/localizations.dart';

class UserDetailsPage extends StatefulWidget {
  const UserDetailsPage({super.key});

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _emergencyCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _emergencyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final uid = AuthService.instance.currentUserUid;
      final email = AuthService.instance.currentUserEmail;
      await DatabaseService.instance.upsertUser(
        UserRow(
          id: uid,
          email: email,
          displayName: _nameCtrl.text.trim(),
          phoneNumber: _phoneCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          city: _cityCtrl.text.trim(),
          state: _stateCtrl.text.trim(),
          emergencyNumber: _emergencyCtrl.text.trim(),
          onboardingStep: 1,
        ),
      );
      if (mounted) context.go('/role-selection');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = RentoLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Details')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Tell us about yourself',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'We need a few details to set up your account.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                _field(
                  _nameCtrl,
                  l.get('name'),
                  Icons.person_outline,
                  required: true,
                ),
                const SizedBox(height: 16),
                _field(
                  _phoneCtrl,
                  l.get('phone'),
                  Icons.phone_outlined,
                  keyboard: TextInputType.phone,
                  required: true,
                ),
                const SizedBox(height: 16),
                _field(_addressCtrl, l.get('address'), Icons.home_outlined),
                const SizedBox(height: 16),
                _field(
                  _cityCtrl,
                  l.get('city'),
                  Icons.location_city_outlined,
                  required: true,
                ),
                const SizedBox(height: 16),
                _field(
                  _stateCtrl,
                  l.get('state'),
                  Icons.map_outlined,
                  required: true,
                ),
                const SizedBox(height: 16),
                _field(
                  _emergencyCtrl,
                  l.get('emergencyNumber'),
                  Icons.emergency_outlined,
                  keyboard: TextInputType.phone,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l.get('continue_')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
    bool required = false,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
          : null,
    );
  }
}
