import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/family_member.dart';
import '../../data/repositories/health_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/social_provider.dart';

class FamilyProfilesScreen extends StatefulWidget {
  const FamilyProfilesScreen({super.key});

  @override
  State<FamilyProfilesScreen> createState() => _FamilyProfilesScreenState();
}

class _FamilyProfilesScreenState extends State<FamilyProfilesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.profile != null) {
        context.read<UserProvider>().loadFamily(
            context.read<HealthRepository>(), auth.profile!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Family & Friends'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.family_restroom_rounded), text: 'Sub-Profiles'),
              Tab(icon: Icon(Icons.people_alt_rounded), text: 'Friends Circle'),
            ],
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
          ),
        ),
        body: const TabBarView(
          children: [
            _FamilyProfilesTab(),
            _FriendsCircleTab(),
          ],
        ),
      ),
    );
  }
}

class _FamilyProfilesTab extends StatelessWidget {
  const _FamilyProfilesTab();

  @override
  Widget build(BuildContext context) {
    final userProv = context.watch<UserProvider>();
    final auth     = context.watch<AuthProvider>();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMember(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.person_add_outlined),
      ),
      body: Column(children: [
        // Main user tile
        _ProfileTile(
          name: auth.profile?.name ?? 'You',
          relation: 'Main account',
          age: auth.profile?.age ?? 0,
          skinTone: auth.profile?.skinTone ?? 5,
          isActive: userProv.isViewingMain,
          onTap: () => userProv.switchToMember(null),
        ),
        const Divider(height: 1),

        if (userProv.familyMembers.isEmpty)
          const Expanded(child: Center(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.group_outlined, size: 48, color: AppColors.textMuted),
              SizedBox(height: 12),
              Text('No family members yet',
                  style: TextStyle(color: AppColors.textSecondary)),
              SizedBox(height: 6),
              Text('Tap + to add a family member',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          )))
        else
          Expanded(child: ListView.separated(
            itemCount: userProv.familyMembers.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final m = userProv.familyMembers[i];
              return _ProfileTile(
                name: m.name, relation: m.relation,
                age: m.age, skinTone: m.skinTone,
                isActive: userProv.activeMemberId == m.id,
                onTap: () => userProv.switchToMember(m.id),
                onDelete: () async {
                  if (auth.profile != null) {
                    await userProv.removeMember(
                        context.read<HealthRepository>(), auth.profile!.uid, m.id);
                  }
                },
              );
            },
          )),
      ]),
    );
  }

  void _showAddMember(BuildContext context) {
    final nameCtrl     = TextEditingController();
    int age            = 10;
    String gender      = 'male';
    int skinTone       = 5;
    String relation    = 'child';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24,
              MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Add Family Member', style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            TextField(controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 16),
            Text('Age: $age'),
            Slider(value: age.toDouble(), min: 1, max: 90, divisions: 89,
                activeColor: AppColors.primary,
                onChanged: (v) => setSheet(() => age = v.round())),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: relation,
              decoration: const InputDecoration(labelText: 'Relation'),
              items: ['child', 'parent', 'spouse', 'other']
                  .map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => setSheet(() => relation = v!),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                final auth = context.read<AuthProvider>();
                if (auth.profile == null) return;
                final member = FamilyMember(
                  id: const Uuid().v4(), ownerId: auth.profile!.uid,
                  name: nameCtrl.text.trim(), age: age,
                  gender: gender, skinTone: skinTone, relation: relation,
                );
                await context.read<UserProvider>().addMember(
                    context.read<HealthRepository>(), member);
                Navigator.pop(ctx);
              },
              child: const Text('Add Member'),
            ),
          ]),
        ),
      ),
    );
  }
}

class _FriendsCircleTab extends StatefulWidget {
  const _FriendsCircleTab();

  @override
  State<_FriendsCircleTab> createState() => _FriendsCircleTabState();
}

class _FriendsCircleTabState extends State<_FriendsCircleTab> {
  final _emailCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.profile != null) {
        context.read<SocialProvider>().loadFriends(auth.profile!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final social = context.watch<SocialProvider>();
    final auth = context.watch<AuthProvider>();
    final myUid = auth.profile?.uid ?? '';

    final filteredResults = social.searchResults.where((u) {
      final isMe = u['uid'] == myUid;
      final alreadyFriend = social.friends.any((f) => f.uid == u['uid']);
      return !isMe && !alreadyFriend;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Search Friends by Name or Email',
                  hintText: 'Type their name or email address...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (val) {
                  social.searchUsers(val);
                },
              ),
              if (social.searching)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (_emailCtrl.text.trim().isNotEmpty && filteredResults.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Center(
                    child: Text(
                      'No registered users found matching query.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ),
                )
              else if (filteredResults.isNotEmpty)
                Container(
                  height: 90,
                  margin: const EdgeInsets.only(top: 12),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: filteredResults.length,
                    itemBuilder: (ctx, idx) {
                      final user = filteredResults[idx];
                      return Card(
                        color: AppColors.bgCard,
                        margin: const EdgeInsets.only(right: 8, bottom: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.border, width: 0.5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.bgHighlight,
                                child: Text(
                                  user['name'][0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    user['name'],
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    user['email'],
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(Icons.person_add_rounded, color: AppColors.primary),
                                tooltip: 'Add Friend',
                                onPressed: () async {
                                  setState(() => _submitting = true);
                                  final success = await social.addFriendByEmail(myUid, user['email']);
                                  setState(() => _submitting = false);
                                  if (success) {
                                    _emailCtrl.clear();
                                    social.searchUsers('');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Friend added successfully!'),
                                        backgroundColor: AppColors.statusNormal,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        if (social.loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (social.friends.isEmpty)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline, size: 48, color: AppColors.textMuted),
                  SizedBox(height: 12),
                  Text('Your Friends Circle is empty', style: TextStyle(color: AppColors.textSecondary)),
                  SizedBox(height: 6),
                  Text('Enter their email to check their daily Vitamin D level!', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              itemCount: social.friends.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final friend = social.friends[i];
                final progress = (friend.todaySynthesized / friend.dailyTarget).clamp(0.0, 1.0);
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(
                      friend.name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(friend.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                      Text(
                        '${friend.todaySynthesized.round()} / ${friend.dailyTarget.round()} IU',
                        style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Skin Type: Fitzpatrick ${friend.skinTone} · ${friend.email}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation(
                            progress >= 1.0 ? AppColors.statusNormal : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.statusDeficient),
                    onPressed: () async {
                      await social.removeFriend(myUid, friend.uid);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Friend removed.')),
                      );
                    },
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final String name, relation;
  final int age, skinTone;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _ProfileTile({required this.name, required this.relation,
    required this.age, required this.skinTone, required this.isActive,
    required this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    tileColor: isActive ? AppColors.bgHighlight : null,
    leading: CircleAvatar(
      backgroundColor: isActive ? AppColors.primary : AppColors.bgCardAlt,
      child: Text(name[0].toUpperCase(),
          style: TextStyle(color: isActive ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w600)),
    ),
    title: Text(name, style: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
    subtitle: Text('$relation · Age $age · Fitzpatrick $skinTone',
        style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
    trailing: onDelete == null
        ? (isActive ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20) : null)
        : PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
            color: AppColors.bgCard,
            itemBuilder: (_) => [
              PopupMenuItem(onTap: onDelete,
                  child: const Text('Remove',
                      style: TextStyle(color: AppColors.statusDeficient))),
            ]),
  );
}
