import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/message_model.dart';
import '../theme/app_theme.dart';
import '../utils/time_util.dart';
import 'user_avatar.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool showAvatar;
  final bool isGroup;
  final void Function(MessageModel) onReply;
  final void Function(MessageModel) onDelete;
  final void Function(MessageModel, String) onReact;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.showAvatar,
    required this.isGroup,
    required this.onReply,
    required this.onDelete,
    required this.onReact,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onLongPress: () => _showOptions(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar for other users
            if (!isMe) ...[
              showAvatar
                  ? UserAvatar(
                      name: message.senderName,
                      photoUrl: message.senderPhotoUrl,
                      radius: 16,
                    )
                  : const SizedBox(width: 32),
              const SizedBox(width: 6),
            ],

            // Bubble
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                ),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Sender name (group chats)
                    if (!isMe && isGroup && showAvatar)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 2),
                        child: Text(
                          message.senderName,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),

                    // Main bubble
                    Container(
                      padding: message.type == MessageType.image
                          ? EdgeInsets.zero
                          : message.type == MessageType.location
                              ? const EdgeInsets.all(4)
                              : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: message.isDeleted
                            ? Colors.grey.withOpacity(0.2)
                            : isMe
                                ? AppTheme.primary
                                : isDark
                                    ? AppTheme.darkCard
                                    : AppTheme.lightCard,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(isMe ? 18 : 4),
                          bottomRight: Radius.circular(isMe ? 4 : 18),
                        ),
                        border: !isMe && !isDark
                            ? Border.all(color: AppTheme.lightBorder)
                            : null,
                      ),
                      child: _buildContent(context),
                    ),

                    // Reactions
                    if (message.reactions != null && message.reactions!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Wrap(
                          spacing: 4,
                          children: message.reactions!.entries.map((e) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.lightBorder),
                              ),
                              child: Text(
                                '${e.key} ${e.value.length}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                    // Time + status
                    Padding(
                      padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            TimeUtil.formatTime(message.createdAt),
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            _StatusIcon(status: message.status),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (isMe) const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (message.isDeleted) {
      return const Text(
        'This message was deleted',
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: Colors.grey,
          fontSize: 14,
        ),
      );
    }

    switch (message.type) {
      case MessageType.text:
        return Text(
          message.text ?? '',
          style: TextStyle(
            fontSize: 15,
            height: 1.4,
            color: isMe ? Colors.white : null,
          ),
        );

      case MessageType.image:
        return ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          child: CachedNetworkImage(
            imageUrl: message.mediaUrl ?? '',
            width: 220,
            height: 220,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              width: 220,
              height: 220,
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (_, __, ___) => Container(
              width: 220,
              height: 220,
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image),
            ),
          ),
        );

      case MessageType.location:
        return _LocationBubble(
          location: message.location!,
          isMe: isMe,
        );

      default:
        return Text(message.text ?? '', style: TextStyle(color: isMe ? Colors.white : null));
    }
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            // Emoji reactions row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['❤️', '😂', '👍', '😮', '😢', '🙏'].map((emoji) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onReact(message, emoji);
                  },
                  child: Text(emoji, style: const TextStyle(fontSize: 28)),
                );
              }).toList(),
            ),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.reply_rounded),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                onReply(message);
              },
            ),
            if (isMe && !message.isDeleted)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete(message);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _LocationBubble extends StatelessWidget {
  final LocationData location;
  final bool isMe;

  const _LocationBubble({required this.location, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Static map preview
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
          ),
          child: SizedBox(
            width: 220,
            height: 140,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(location.latitude, location.longitude),
                zoom: 14,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('loc'),
                  position: LatLng(location.latitude, location.longitude),
                ),
              },
              zoomControlsEnabled: false,
              scrollGesturesEnabled: false,
              zoomGesturesEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              liteModeEnabled: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                location.isLive ? Icons.location_on : Icons.location_on_outlined,
                size: 16,
                color: isMe ? Colors.white70 : AppTheme.primary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  location.isLive
                      ? '📡 Live location'
                      : location.address ?? '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isMe ? Colors.white : null,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final MessageStatus status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageStatus.sending:
        return const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white54),
        );
      case MessageStatus.sent:
        return const Icon(Icons.check, size: 12, color: Colors.white54);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 12, color: Colors.white54);
      case MessageStatus.read:
        return const Icon(Icons.done_all, size: 12, color: Colors.lightBlueAccent);
      case MessageStatus.failed:
        return const Icon(Icons.error_outline, size: 12, color: Colors.red);
    }
  }
}
