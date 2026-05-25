// settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/providers.dart';
import '../family/family_profiles_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final p = auth.profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (p != null) ...[
          ListTile(
            leading: const CircleAvatar(
                backgroundColor: AppColors.bgHighlight,
                child: Icon(Icons.person, color: AppColors.primary)),
            title: Text(p.name),
            subtitle: Text(p.email,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.location_city_outlined),
            title: const Text('City'),
            trailing: Text(p.city,
                style: const TextStyle(color: AppColors.primary)),
          ),
          ListTile(
            leading: const Icon(Icons.face_outlined),
            title: const Text('Skin tone'),
            trailing: Text('Fitzpatrick ${p.skinTone}',
                style: const TextStyle(color: AppColors.primary)),
          ),
          ListTile(
            leading: const Icon(Icons.cake_outlined),
            title: const Text('Age'),
            trailing: Text('${p.age} years',
                style: const TextStyle(color: AppColors.primary)),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.people_alt_outlined, color: AppColors.primary),
            title: const Text('Family & Friends Circle'),
            subtitle: const Text('Manage sub-profiles & view friends Vitamin D levels'),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FamilyProfilesScreen()),
              );
            },
          ),
          const Divider(),
        ],
        ListTile(
          leading: const Icon(Icons.logout_rounded,
              color: AppColors.statusDeficient),
          title: const Text('Sign out',
              style: TextStyle(color: AppColors.statusDeficient)),
          onTap: () async {
            await context.read<AuthProvider>().signOut();
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),
      ]),
    );
  }
}
