import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';

import '../../models/chat_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/user_avatar.dart';

class GroupInfoScreen extends ConsumerWidget {
  final String chatId;

  const GroupInfoScreen({super.key, required this.chatId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = ref.watch(authServiceProvider).currentUserId;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Group Info'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.edit),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('chats').doc(chatId).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final chat = ChatModel.fromMap(snap.data!.data() as Map<String, dynamic>, chatId);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // Group photo
                    UserAvatar(
                      name: chat.name ?? 'Group',
                      photoUrl: chat.photoUrl,
                      radius: 50,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      chat.name ?? 'Group Chat',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (chat.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        chat.description!,
                        style: const TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '${chat.memberIds.length} members',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Iconsax.people, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Members (${chat.memberIds.length})',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final memberId = chat.memberIds[index];
                    final memberName = chat.memberNames[memberId] ?? 'Unknown';
                    final isAdmin = memberId == chat.createdBy;
                    final isMe = memberId == currentUid;

                    return ListTile(
                      leading: UserAvatar(name: memberName, radius: 20),
                      title: Text('$memberName${isMe ? ' (You)' : ''}'),
                      trailing: isAdmin
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Admin',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : null,
                      onTap: () => context.push('/home/profile/$memberId'),
                    );
                  },
                  childCount: chat.memberIds.length,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
