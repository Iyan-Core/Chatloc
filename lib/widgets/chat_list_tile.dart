import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../theme/app_theme.dart';
import '../utils/time_util.dart';
import 'user_avatar.dart';

class ChatListTile extends StatelessWidget {
  final ChatModel chat;
  final String currentUserId;
  final String chatName;
  final int unreadCount;
  final VoidCallback onTap;

  const ChatListTile({
    super.key,
    required this.chat,
    required this.currentUserId,
    required this.chatName,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasUnread = unreadCount > 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: UserAvatar(
        name: chatName,
        photoUrl: chat.photoUrl,
        radius: 26,
        showOnlineIndicator: chat.type == ChatType.direct,
      ),
      title: Text(
        chatName,
        style: TextStyle(
          fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
          fontSize: 15,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          if (chat.lastMessageSenderId == currentUserId)
            const Text('You: ', style: TextStyle(fontSize: 13, color: Colors.grey)),
          Expanded(
            child: Text(
              chat.lastMessageText ?? 'No messages yet',
              style: TextStyle(
                fontSize: 13,
                color: hasUnread
                    ? (isDark ? Colors.white70 : Colors.black87)
                    : Colors.grey,
                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (chat.lastMessageAt != null)
            Text(
              TimeUtil.timeAgo(chat.lastMessageAt!),
              style: TextStyle(
                fontSize: 11,
                color: hasUnread ? AppTheme.primary : Colors.grey,
                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          const SizedBox(height: 4),
          if (hasUnread)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}
