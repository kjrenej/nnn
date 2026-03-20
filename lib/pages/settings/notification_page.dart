import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool _rentReminder = true;
  bool _bookingUpdates = true;
  bool _newListings = false;
  bool _promotions = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Push Notifications',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Rent Reminders'),
            subtitle: const Text('Get reminded before rent is due'),
            value: _rentReminder,
            onChanged: (v) => setState(() => _rentReminder = v),
          ),
          SwitchListTile(
            title: const Text('Booking Updates'),
            subtitle: const Text('Status updates on your bookings'),
            value: _bookingUpdates,
            onChanged: (v) => setState(() => _bookingUpdates = v),
          ),
          SwitchListTile(
            title: const Text('New Listings'),
            subtitle: const Text('When properties match your preferences'),
            value: _newListings,
            onChanged: (v) => setState(() => _newListings = v),
          ),
          SwitchListTile(
            title: const Text('Promotions'),
            subtitle: const Text('Offers and promotional content'),
            value: _promotions,
            onChanged: (v) => setState(() => _promotions = v),
          ),
        ],
      ),
    );
  }
}
