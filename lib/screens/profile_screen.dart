import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/user_avatar.dart';
import '../../utils/time_util.dart';

class ProfileScreen extends ConsumerWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = ref.watch(authServiceProvider).currentUserId;
    final isMe = currentUid == userId;

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = UserModel.fromMap(snap.data!.data() as Map<String, dynamic>);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  if (isMe)
                    IconButton(
                      icon: const Icon(Iconsax.edit),
                      onPressed: () => context.push('/home/edit-profile'),
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF06D6A0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        UserAvatar(
                          name: user.name,
                          photoUrl: user.photoUrl,
                          radius: 44,
                          showOnlineIndicator: user.isOnline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Online status
                      _InfoRow(
                        icon: user.isOnline ? Icons.circle : Icons.circle_outlined,
                        iconColor: user.isOnline ? Colors.green : Colors.grey,
                        label: user.isOnline
                            ? 'Online now'
                            : 'Last seen ${user.lastSeen != null ? TimeUtil.timeAgo(user.lastSeen!) : 'recently'}',
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: Icons.email_outlined,
                        label: user.email,
                      ),
                      if (user.phoneNumber != null) ...[
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.phone_outlined,
                          label: user.phoneNumber!,
                        ),
                      ],
                      if (user.bio != null) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'About',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(user.bio!, style: const TextStyle(color: Colors.grey, height: 1.5)),
                      ],
                      const SizedBox(height: 32),
                      if (!isMe)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              // Create direct chat and navigate
                            },
                            icon: const Icon(Iconsax.message),
                            label: const Text('Send Message'),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;

  const _InfoRow({required this.icon, required this.label, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor ?? Colors.grey),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}
