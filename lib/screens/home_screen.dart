import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../widgets/chat_list_tile.dart';
import '../../widgets/user_avatar.dart';
import '../../theme/app_theme.dart';
import '../../utils/time_util.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final chats = ref.watch(chatsStreamProvider).valueOrNull ?? [];

    final filteredChats = _searchQuery.isEmpty
        ? chats
        : chats
            .where((c) => c
                .getChatName(currentUser?.uid ?? '')
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ChatLoc'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.map),
            onPressed: () => context.push('/home/map'),
            tooltip: 'Map view',
          ),
          GestureDetector(
            onTap: () => context.push('/home/profile/${currentUser?.uid}'),
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: UserAvatar(
                name: currentUser?.name ?? '',
                photoUrl: currentUser?.photoUrl,
                radius: 18,
                showOnlineIndicator: true,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search chats...',
                prefixIcon: const Icon(Iconsax.search_normal, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Chat list
          Expanded(
            child: filteredChats.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    itemCount: filteredChats.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
                    itemBuilder: (context, index) {
                      final chat = filteredChats[index];
                      final name = chat.getChatName(currentUser?.uid ?? '');
                      final unread = chat.unreadCount[currentUser?.uid] ?? 0;

                      return ChatListTile(
                        chat: chat,
                        currentUserId: currentUser?.uid ?? '',
                        chatName: name,
                        unreadCount: unread,
                        onTap: () {
                          ref.read(chatServiceProvider).markAsRead(chat.id);
                          context.push(
                            '/home/chat/${chat.id}',
                            extra: {
                              'chatName': name,
                              'chatPhotoUrl': chat.photoUrl,
                              'isGroup': chat.type.name == 'group',
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/home/create-chat'),
        backgroundColor: AppTheme.primary,
        child: const Icon(Iconsax.message_add, color: Colors.white),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          setState(() => _currentIndex = i);
          if (i == 1) context.push('/home/map');
          if (i == 2) context.push('/home/settings');
        },
        destinations: const [
          NavigationDestination(icon: Icon(Iconsax.message), label: 'Chats'),
          NavigationDestination(icon: Icon(Iconsax.location), label: 'Map'),
          NavigationDestination(icon: Icon(Iconsax.setting_2), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.message, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'No results found' : 'No conversations yet',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          if (_searchQuery.isEmpty)
            const Text(
              'Tap + to start a new chat',
              style: TextStyle(color: Colors.grey),
            ),
        ],
      ),
    );
  }
}
