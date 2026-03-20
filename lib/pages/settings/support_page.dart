import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(Icons.headset_mic, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'How can we help?',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reach out to us for any questions, issues, or feedback.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          _tile(
            context,
            Icons.email_outlined,
            'Email Us',
            'support@rento.app',
            () {
              launchUrl(Uri.parse('mailto:support@rento.app'));
            },
          ),
          _tile(
            context,
            Icons.phone_outlined,
            'Call Us',
            '+91 1800-XXX-XXXX',
            () {
              launchUrl(Uri.parse('tel:+911800XXXXXXX'));
            },
          ),
          _tile(
            context,
            Icons.chat_outlined,
            'FAQ',
            'Frequently asked questions',
            () {
              // Navigate to FAQ page or web
            },
          ),
          _tile(
            context,
            Icons.bug_report_outlined,
            'Report a Bug',
            'Help us improve',
            () {
              launchUrl(
                Uri.parse('mailto:bugs@rento.app?subject=Bug%20Report'),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
