import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  static const _languages = [
    {'code': 'en', 'name': 'English', 'native': 'English'},
    {'code': 'hi', 'name': 'Hindi', 'native': 'हिन्दी'},
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final current = appState.selectedLocale;

    return Scaffold(
      appBar: AppBar(title: const Text('Language')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _languages.length,
        separatorBuilder: (ctx, i) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final lang = _languages[i];
          final selected = current == lang['code'];
          return Card(
            color: selected
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            child: ListTile(
              leading: Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
              title: Text(
                lang['name']!,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(lang['native']!),
              onTap: () {
                appState.setLocale(lang['code']!);
                Navigator.of(context).pop();
              },
            ),
          );
        },
      ),
    );
  }
}
