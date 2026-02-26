import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _modeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Hệ thống';
      case ThemeMode.light:
        return 'Sáng';
      case ThemeMode.dark:
        return 'Tối';
    }
  }

  IconData _modeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return Icons.phone_android;
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ValueListenableBuilder<ThemeMode>(
        valueListenable: SettingsService.themeModeNotifier,
        builder: (context, mode, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Giao diện', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      const SizedBox(height: 12),
                      ...ThemeMode.values.map(
                        (item) => RadioListTile<ThemeMode>(
                          value: item,
                          groupValue: mode,
                          onChanged: (value) {
                            if (value != null) {
                              SettingsService.setThemeMode(value);
                            }
                          },
                          title: Text(_modeLabel(item)),
                          secondary: Icon(_modeIcon(item)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
