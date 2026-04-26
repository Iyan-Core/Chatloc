import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../providers/theme_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/snackbar_util.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Profile section
          if (user != null)
            ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                child: user.photoUrl == null ? Text(user.name[0]) : null,
              ),
              title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(user.email),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/home/edit-profile'),
            ),
          const Divider(),

          // Appearance
          _SectionHeader(title: 'Appearance'),
          ListTile(
            leading: const Icon(Iconsax.sun_1),
            title: const Text('Theme'),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
              onChanged: (mode) {
                if (mode != null) ref.read(themeModeProvider.notifier).setTheme(mode);
              },
            ),
          ),

          // Notifications
          _SectionHeader(title: 'Notifications'),
          _SwitchTile(
            icon: Iconsax.notification,
            title: 'Push Notifications',
            value: true,
            onChanged: (_) {},
          ),
          _SwitchTile(
            icon: Iconsax.volume_high,
            title: 'Message Sound',
            value: true,
            onChanged: (_) {},
          ),

          // Privacy
          _SectionHeader(title: 'Privacy & Security'),
          _SwitchTile(
            icon: Iconsax.location,
            title: 'Share Location',
            subtitle: 'Allow others to see your location',
            value: user?.locationSharingEnabled ?? false,
            onChanged: (_) {},
          ),
          ListTile(
            leading: const Icon(Iconsax.lock),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/auth/forgot-password'),
          ),

          // About
          _SectionHeader(title: 'About'),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (_, snap) => ListTile(
              leading: const Icon(Iconsax.info_circle),
              title: const Text('Version'),
              trailing: Text(
                snap.data != null
                    ? '${snap.data!.version} (${snap.data!.buildNumber})'
                    : '...',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Sign out
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) context.go('/auth/login');
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Iconsax.logout),
              label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 12)) : null,
      value: value,
      onChanged: onChanged,
    );
  }
}
