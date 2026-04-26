import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../widgets/user_avatar.dart';
import '../../utils/snackbar_util.dart';

class CreateChatScreen extends ConsumerStatefulWidget {
  const CreateChatScreen({super.key});

  @override
  ConsumerState<CreateChatScreen> createState() => _CreateChatScreenState();
}

class _CreateChatScreenState extends ConsumerState<CreateChatScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  final Set<UserModel> _selectedUsers = {};
  bool _isGroupMode = false;
  final _groupNameCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _groupNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _createChat() async {
    if (_selectedUsers.isEmpty) return;
    setState(() => _loading = true);

    try {
      final chatService = ref.read(chatServiceProvider);

      if (_isGroupMode || _selectedUsers.length > 1) {
        final chat = await chatService.createGroupChat(
          name: _groupNameCtrl.text.trim().isEmpty
              ? _selectedUsers.map((u) => u.name.split(' ').first).join(', ')
              : _groupNameCtrl.text.trim(),
          members: _selectedUsers.toList(),
        );
        if (mounted) {
          context.go('/home/chat/${chat.id}', extra: {
            'chatName': chat.name,
            'isGroup': true,
          });
        }
      } else {
        final chat = await chatService.createDirectChat(_selectedUsers.first);
        if (mounted) {
          context.go('/home/chat/${chat.id}', extra: {
            'chatName': _selectedUsers.first.name,
            'chatPhotoUrl': _selectedUsers.first.photoUrl,
            'isGroup': false,
          });
        }
      }
    } catch (e) {
      if (mounted) SnackbarUtil.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('New Chat'),
        actions: [
          if (_selectedUsers.isNotEmpty)
            _loading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton(
                    onPressed: _createChat,
                    child: const Text('Create'),
                  ),
        ],
      ),
      body: Column(
        children: [
          // Group mode toggle
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _isGroupMode = false),
                  child: _ModeTab(label: 'Direct', selected: !_isGroupMode),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => setState(() => _isGroupMode = true),
                  child: _ModeTab(label: 'Group', selected: _isGroupMode),
                ),
              ],
            ),
          ),

          // Group name (if group mode)
          if (_isGroupMode || _selectedUsers.length > 1) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _groupNameCtrl,
                decoration: const InputDecoration(
                  hintText: 'Group name (optional)',
                  prefixIcon: Icon(Iconsax.people),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Selected users chips
          if (_selectedUsers.isNotEmpty)
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _selectedUsers.map((u) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      avatar: UserAvatar(name: u.name, photoUrl: u.photoUrl, radius: 12),
                      label: Text(u.name.split(' ').first),
                      onDeleted: () => setState(() => _selectedUsers.remove(u)),
                      deleteIconColor: Colors.grey,
                    ),
                  );
                }).toList(),
              ),
            ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: Icon(Iconsax.search_normal, size: 20),
              ),
            ),
          ),

          // User list
          Expanded(
            child: _query.length < 2
                ? const Center(
                    child: Text(
                      'Type at least 2 characters\nto search users',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : StreamBuilder<List<UserModel>>(
                    stream: ref.read(authServiceProvider).searchUsers(_query),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final users = snap.data ?? [];
                      if (users.isEmpty) {
                        return const Center(
                          child: Text('No users found', style: TextStyle(color: Colors.grey)),
                        );
                      }
                      return ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (_, i) {
                          final user = users[i];
                          final selected = _selectedUsers.contains(user);
                          return ListTile(
                            leading: UserAvatar(
                              name: user.name,
                              photoUrl: user.photoUrl,
                              showOnlineIndicator: user.isOnline,
                            ),
                            title: Text(user.name),
                            subtitle: Text(user.email),
                            trailing: selected
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : const Icon(Icons.circle_outlined, color: Colors.grey),
                            onTap: () {
                              setState(() {
                                if (selected) {
                                  _selectedUsers.remove(user);
                                } else {
                                  if (!_isGroupMode) _selectedUsers.clear();
                                  _selectedUsers.add(user);
                                }
                              });
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool selected;

  const _ModeTab({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).dividerColor,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : null,
        ),
      ),
    );
  }
}
