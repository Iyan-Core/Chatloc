import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatType { direct, group }

class ChatModel {
  final String id;
  final ChatType type;
  final String? name;
  final String? photoUrl;
  final List<String> memberIds;
  final Map<String, String> memberNames;
  final String? lastMessageText;
  final String? lastMessageSenderId;
  final DateTime? lastMessageAt;
  final Map<String, int> unreadCount;
  final String? description;
  final DateTime createdAt;
  final String createdBy;
  final bool isActive;

  const ChatModel({
    required this.id,
    required this.type,
    this.name,
    this.photoUrl,
    required this.memberIds,
    required this.memberNames,
    this.lastMessageText,
    this.lastMessageSenderId,
    this.lastMessageAt,
    required this.unreadCount,
    this.description,
    required this.createdAt,
    required this.createdBy,
    this.isActive = true,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatModel(
      id: id,
      type: map['type'] == 'group' ? ChatType.group : ChatType.direct,
      name: map['name'] as String?,
      photoUrl: map['photoUrl'] as String?,
      memberIds: List<String>.from(map['memberIds'] as List),
      memberNames: Map<String, String>.from(map['memberNames'] as Map),
      lastMessageText: map['lastMessageText'] as String?,
      lastMessageSenderId: map['lastMessageSenderId'] as String?,
      lastMessageAt: (map['lastMessageAt'] as Timestamp?)?.toDate(),
      unreadCount: Map<String, int>.from(
        (map['unreadCount'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), (v as num).toInt()),
            ) ??
            {},
      ),
      description: map['description'] as String?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      createdBy: map['createdBy'] as String,
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'name': name,
      'photoUrl': photoUrl,
      'memberIds': memberIds,
      'memberNames': memberNames,
      'lastMessageText': lastMessageText,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageAt': lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
      'unreadCount': unreadCount,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'isActive': isActive,
    };
  }

  String getChatName(String currentUserId) {
    if (type == ChatType.group) return name ?? 'Group Chat';
    final otherMemberId = memberIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => memberIds.first,
    );
    return memberNames[otherMemberId] ?? 'Unknown';
  }
}
