import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, location, audio, file, system }
enum MessageStatus { sending, sent, delivered, read, failed }

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final MessageType type;
  final String? text;
  final String? mediaUrl;
  final LocationData? location;
  final MessageStatus status;
  final DateTime createdAt;
  final DateTime? editedAt;
  final bool isDeleted;
  final String? replyToId;
  final Map<String, List<String>>? reactions; // emoji -> list of userIds
  final int? duration; // for audio messages in seconds

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.type,
    this.text,
    this.mediaUrl,
    this.location,
    this.status = MessageStatus.sending,
    required this.createdAt,
    this.editedAt,
    this.isDeleted = false,
    this.replyToId,
    this.reactions,
    this.duration,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      chatId: map['chatId'] as String,
      senderId: map['senderId'] as String,
      senderName: map['senderName'] as String,
      senderPhotoUrl: map['senderPhotoUrl'] as String?,
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      text: map['text'] as String?,
      mediaUrl: map['mediaUrl'] as String?,
      location: map['location'] != null
          ? LocationData.fromMap(map['location'] as Map<String, dynamic>)
          : null,
      status: MessageStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => MessageStatus.sent,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      editedAt: (map['editedAt'] as Timestamp?)?.toDate(),
      isDeleted: map['isDeleted'] as bool? ?? false,
      replyToId: map['replyToId'] as String?,
      reactions: (map['reactions'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, List<String>.from(v as List)),
      ),
      duration: map['duration'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'type': type.name,
      'text': text,
      'mediaUrl': mediaUrl,
      'location': location?.toMap(),
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'isDeleted': isDeleted,
      'replyToId': replyToId,
      'reactions': reactions,
      'duration': duration,
    };
  }

  MessageModel copyWith({
    MessageStatus? status,
    bool? isDeleted,
    DateTime? editedAt,
    String? text,
    Map<String, List<String>>? reactions,
  }) {
    return MessageModel(
      id: id,
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      type: type,
      text: text ?? this.text,
      mediaUrl: mediaUrl,
      location: location,
      status: status ?? this.status,
      createdAt: createdAt,
      editedAt: editedAt ?? this.editedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      replyToId: replyToId,
      reactions: reactions ?? this.reactions,
      duration: duration,
    );
  }
}

class LocationData {
  final double latitude;
  final double longitude;
  final String? address;
  final bool isLive;
  final DateTime? expiresAt;

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.address,
    this.isLive = false,
    this.expiresAt,
  });

  factory LocationData.fromMap(Map<String, dynamic> map) {
    return LocationData(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      address: map['address'] as String?,
      isLive: map['isLive'] as bool? ?? false,
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'isLive': isLive,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };
  }
}
