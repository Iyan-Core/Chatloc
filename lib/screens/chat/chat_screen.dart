import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/message_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/location_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/location_picker_sheet.dart';
import '../../theme/app_theme.dart';
import '../../utils/snackbar_util.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String chatName;
  final String? chatPhotoUrl;
  final bool isGroup;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.chatName,
    this.chatPhotoUrl,
    this.isGroup = false,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();
  bool _canSend = false;
  MessageModel? _replyTo;

  @override
  void initState() {
    super.initState();
    _msgCtrl.addListener(() {
      setState(() => _canSend = _msgCtrl.text.trim().isNotEmpty);
    });
    // Mark as read
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatServiceProvider).markAsRead(widget.chatId);
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    setState(() => _replyTo = null);

    try {
      await ref.read(chatServiceProvider).sendTextMessage(
            chatId: widget.chatId,
            text: text,
            replyToId: _replyTo?.id,
          );
      _scrollToBottom();
    } catch (e) {
      if (mounted) SnackbarUtil.showError(context, 'Failed to send message');
    }
  }

  Future<void> _sendImage() async {
    final storage = ref.read(storageServiceProvider);
    final file = await storage.pickImage();
    if (file == null) return;

    try {
      final url = await storage.uploadChatImage(widget.chatId, File(file.path));
      await ref.read(chatServiceProvider).sendImageMessage(
            chatId: widget.chatId,
            imageUrl: url,
          );
      _scrollToBottom();
    } catch (e) {
      if (mounted) SnackbarUtil.showError(context, 'Failed to send image');
    }
  }

  Future<void> _sendLocation() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LocationPickerSheet(),
    );

    if (result == null) return;

    try {
      await ref.read(chatServiceProvider).sendLocationMessage(
            chatId: widget.chatId,
            latitude: result['lat'],
            longitude: result['lng'],
            address: result['address'],
            isLive: result['isLive'] ?? false,
          );
      _scrollToBottom();
    } catch (e) {
      if (mounted) SnackbarUtil.showError(context, 'Failed to send location');
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesStreamProvider(widget.chatId)).valueOrNull ?? [];
    final currentUserId = ref.watch(authServiceProvider).currentUserId ?? '';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: GestureDetector(
          onTap: widget.isGroup
              ? () => context.push('/home/group-info/${widget.chatId}')
              : null,
          child: Row(
            children: [
              UserAvatar(
                name: widget.chatName,
                photoUrl: widget.chatPhotoUrl,
                radius: 18,
                showOnlineIndicator: !widget.isGroup,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.chatName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.isGroup)
                      const Text(
                        'Tap for info',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.location),
            onPressed: () => context.push('/home/map', extra: {'chatId': widget.chatId}),
            tooltip: 'Map view',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showChatOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Text('No messages yet. Say hi! 👋',
                        style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderId == currentUserId;
                      final showAvatar = !isMe &&
                          (index == messages.length - 1 ||
                              messages[index + 1].senderId != msg.senderId);

                      return MessageBubble(
                        message: msg,
                        isMe: isMe,
                        showAvatar: showAvatar,
                        isGroup: widget.isGroup,
                        onReply: (m) => setState(() => _replyTo = m),
                        onDelete: (m) =>
                            ref.read(chatServiceProvider).deleteMessage(widget.chatId, m.id),
                        onReact: (m, emoji) =>
                            ref.read(chatServiceProvider).addReaction(widget.chatId, m.id, emoji),
                      );
                    },
                  ),
          ),

          // Reply preview
          if (_replyTo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 36,
                    color: AppTheme.primary,
                    margin: const EdgeInsets.only(right: 10),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _replyTo!.senderName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                        Text(
                          _replyTo!.text ?? '',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _replyTo = null),
                  ),
                ],
              ),
            ),

          // Input bar
          Container(
            padding: EdgeInsets.only(
              left: 8,
              right: 8,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Iconsax.gallery),
                  onPressed: _sendImage,
                  tooltip: 'Send image',
                ),
                IconButton(
                  icon: const Icon(Iconsax.location4),
                  onPressed: _sendLocation,
                  tooltip: 'Share location',
                ),
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    focusNode: _focusNode,
                    maxLines: 4,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _sendText(),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: _canSend
                      ? FloatingActionButton.small(
                          onPressed: _sendText,
                          backgroundColor: AppTheme.primary,
                          elevation: 0,
                          child: const Icon(Iconsax.send_1, color: Colors.white, size: 20),
                        )
                      : const SizedBox(width: 40),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Iconsax.search_normal),
              title: const Text('Search'),
              onTap: () => Navigator.pop(context),
            ),
            if (widget.isGroup)
              ListTile(
                leading: const Icon(Iconsax.people),
                title: const Text('Group Info'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/home/group-info/${widget.chatId}');
                },
              ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Block', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
