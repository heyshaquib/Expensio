import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/utils/section_header.dart';
import '../profile/profile_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final dynamicColor = ref.watch(dynamicColorProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Profile Settings
          SectionHeader('PROFILE'),
          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: const Text('Profile & Data'),
            subtitle: const Text('Manage your name, currency and data'),
            trailing: const Icon(Icons.chevron_right),
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
          ),
          const Divider(height: 32),

          // Appearance
          SectionHeader('APPEARANCE'),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme'),
            subtitle: Text(_getThemeDisplayName(themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _selectTheme(context, ref, themeMode),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.color_lens_outlined),
            title: const Text('Dynamic Color'),
            subtitle: const Text('Use wallpaper colors'),
            value: dynamicColor,
            onChanged: (v) async {
              ref.read(dynamicColorProvider.notifier).state = v;
              final db = ref.read(databaseProvider);
              await db.setSetting('dynamic_color', v.toString());
            },
          ),
          const Divider(height: 32),

          // About
          SectionHeader('ABOUT'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            subtitle: const Text('About And Licenses'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              );
            },
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  void _selectTheme(BuildContext context, WidgetRef ref, String current) {
    showDialog(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: const Text('Theme'),
            children:
                ['system', 'light', 'dark', 'night']
                    .map(
                      (t) => RadioListTile<String>(
                        title: Text(_getThemeDisplayName(t)),
                        value: t,
                        // ignore: deprecated_member_use
                        groupValue: current,
                        // ignore: deprecated_member_use
                        onChanged: (v) async {
                          if (v != null) {
                            ref.read(themeModeProvider.notifier).state = v;
                            final db = ref.read(databaseProvider);
                            await db.setSetting('theme_mode', v);
                          }
                          if (!context.mounted) return;
                          Navigator.pop(context);
                        },
                      ),
                    )
                    .toList(),
          ),
    );
  }

  String _getThemeDisplayName(String theme) {
    switch (theme) {
      case 'system':
        return 'System Default';
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      case 'night':
        return 'Night';
      default:
        return theme;
    }
  }
}
