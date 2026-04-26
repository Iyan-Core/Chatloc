import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  final auth = ref.watch(authServiceProvider);
  return ChatService(auth);
});

final chatsStreamProvider = StreamProvider<List<ChatModel>>((ref) {
  final service = ref.watch(chatServiceProvider);
  return service.getChats();
});

final messagesStreamProvider =
    StreamProvider.family<List<MessageModel>, String>((ref, chatId) {
  final service = ref.watch(chatServiceProvider);
  return service.getMessages(chatId);
});

class ChatService {
  final AuthService _auth;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  ChatService(this._auth);

  String get _uid => _auth.currentUserId!;

  // ─── Chats ────────────────────────────────────────────────────────────────

  Stream<List<ChatModel>> getChats() {
    return _db
        .collection('chats')
        .where('memberIds', arrayContains: _uid)
        .where('isActive', isEqualTo: true)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ChatModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<ChatModel> createDirectChat(UserModel otherUser) async {
    final currentUserDoc = await _db.collection('users').doc(_uid).get();
    final currentUser = UserModel.fromMap(currentUserDoc.data()!);

    // Check if direct chat already exists
    final existing = await _db
        .collection('chats')
        .where('type', isEqualTo: 'direct')
        .where('memberIds', arrayContains: _uid)
        .get();

    for (final doc in existing.docs) {
      final chat = ChatModel.fromMap(doc.data(), doc.id);
      if (chat.memberIds.contains(otherUser.uid)) return chat;
    }

    final ref = _db.collection('chats').doc();
    final chat = ChatModel(
      id: ref.id,
      type: ChatType.direct,
      memberIds: [_uid, otherUser.uid],
      memberNames: {
        _uid: currentUser.name,
        otherUser.uid: otherUser.name,
      },
      unreadCount: {_uid: 0, otherUser.uid: 0},
      createdAt: DateTime.now(),
      createdBy: _uid,
    );

    await ref.set(chat.toMap());
    return chat;
  }

  Future<ChatModel> createGroupChat({
    required String name,
    required List<UserModel> members,
    String? description,
    String? photoUrl,
  }) async {
    final currentUserDoc = await _db.collection('users').doc(_uid).get();
    final currentUser = UserModel.fromMap(currentUserDoc.data()!);

    final allMembers = [currentUser, ...members];
    final ref = _db.collection('chats').doc();

    final chat = ChatModel(
      id: ref.id,
      type: ChatType.group,
      name: name,
      photoUrl: photoUrl,
      description: description,
      memberIds: allMembers.map((u) => u.uid).toList(),
      memberNames: {for (final u in allMembers) u.uid: u.name},
      unreadCount: {for (final u in allMembers) u.uid: 0},
      createdAt: DateTime.now(),
      createdBy: _uid,
    );

    await ref.set(chat.toMap());
    return chat;
  }

  // ─── Messages ─────────────────────────────────────────────────────────────

  Stream<List<MessageModel>> getMessages(String chatId, {int limit = 50}) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => MessageModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> sendTextMessage({
    required String chatId,
    required String text,
    String? replyToId,
  }) async {
    final userDoc = await _db.collection('users').doc(_uid).get();
    final user = UserModel.fromMap(userDoc.data()!);

    final ref = _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    final msg = MessageModel(
      id: ref.id,
      chatId: chatId,
      senderId: _uid,
      senderName: user.name,
      senderPhotoUrl: user.photoUrl,
      type: MessageType.text,
      text: text,
      status: MessageStatus.sent,
      createdAt: DateTime.now(),
      replyToId: replyToId,
    );

    final batch = _db.batch();
    batch.set(ref, msg.toMap());
    batch.update(_db.collection('chats').doc(chatId), {
      'lastMessageText': text,
      'lastMessageSenderId': _uid,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    await _incrementUnread(chatId, excludeUid: _uid);
  }

  Future<void> sendLocationMessage({
    required String chatId,
    required double latitude,
    required double longitude,
    String? address,
    bool isLive = false,
  }) async {
    final userDoc = await _db.collection('users').doc(_uid).get();
    final user = UserModel.fromMap(userDoc.data()!);

    final ref = _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    final location = LocationData(
      latitude: latitude,
      longitude: longitude,
      address: address,
      isLive: isLive,
      expiresAt: isLive ? DateTime.now().add(const Duration(minutes: 30)) : null,
    );

    final msg = MessageModel(
      id: ref.id,
      chatId: chatId,
      senderId: _uid,
      senderName: user.name,
      senderPhotoUrl: user.photoUrl,
      type: MessageType.location,
      location: location,
      text: address ?? 'Shared a location',
      status: MessageStatus.sent,
      createdAt: DateTime.now(),
    );

    final batch = _db.batch();
    batch.set(ref, msg.toMap());
    batch.update(_db.collection('chats').doc(chatId), {
      'lastMessageText': '📍 ${address ?? 'Location'}',
      'lastMessageSenderId': _uid,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    await _incrementUnread(chatId, excludeUid: _uid);
  }

  Future<void> sendImageMessage({
    required String chatId,
    required String imageUrl,
  }) async {
    final userDoc = await _db.collection('users').doc(_uid).get();
    final user = UserModel.fromMap(userDoc.data()!);

    final ref = _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    final msg = MessageModel(
      id: ref.id,
      chatId: chatId,
      senderId: _uid,
      senderName: user.name,
      senderPhotoUrl: user.photoUrl,
      type: MessageType.image,
      mediaUrl: imageUrl,
      text: '📷 Image',
      status: MessageStatus.sent,
      createdAt: DateTime.now(),
    );

    final batch = _db.batch();
    batch.set(ref, msg.toMap());
    batch.update(_db.collection('chats').doc(chatId), {
      'lastMessageText': '📷 Image',
      'lastMessageSenderId': _uid,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    await _incrementUnread(chatId, excludeUid: _uid);
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'isDeleted': true, 'text': 'This message was deleted'});
  }

  Future<void> markAsRead(String chatId) async {
    await _db.collection('chats').doc(chatId).update({
      'unreadCount.$_uid': 0,
    });
  }

  Future<void> addReaction(
      String chatId, String messageId, String emoji) async {
    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'reactions.$emoji': FieldValue.arrayUnion([_uid]),
    });
  }

  Future<void> _incrementUnread(String chatId, {required String excludeUid}) async {
    final chatDoc = await _db.collection('chats').doc(chatId).get();
    final chat = ChatModel.fromMap(chatDoc.data()!, chatDoc.id);

    final updates = <String, dynamic>{};
    for (final uid in chat.memberIds) {
      if (uid != excludeUid) {
        updates['unreadCount.$uid'] = FieldValue.increment(1);
      }
    }

    if (updates.isNotEmpty) {
      await _db.collection('chats').doc(chatId).update(updates);
    }
  }
}
