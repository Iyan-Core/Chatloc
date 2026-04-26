import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String? phoneNumber;
  final bool isOnline;
  final DateTime? lastSeen;
  final String? fcmToken;
  final String? bio;
  final GeoPoint? lastLocation;
  final bool locationSharingEnabled;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.phoneNumber,
    this.isOnline = false,
    this.lastSeen,
    this.fcmToken,
    this.bio,
    this.lastLocation,
    this.locationSharingEnabled = false,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      photoUrl: map['photoUrl'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      isOnline: map['isOnline'] as bool? ?? false,
      lastSeen: (map['lastSeen'] as Timestamp?)?.toDate(),
      fcmToken: map['fcmToken'] as String?,
      bio: map['bio'] as String?,
      lastLocation: map['lastLocation'] as GeoPoint?,
      locationSharingEnabled: map['locationSharingEnabled'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'fcmToken': fcmToken,
      'bio': bio,
      'lastLocation': lastLocation,
      'locationSharingEnabled': locationSharingEnabled,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? name,
    String? photoUrl,
    String? phoneNumber,
    bool? isOnline,
    DateTime? lastSeen,
    String? fcmToken,
    String? bio,
    GeoPoint? lastLocation,
    bool? locationSharingEnabled,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      fcmToken: fcmToken ?? this.fcmToken,
      bio: bio ?? this.bio,
      lastLocation: lastLocation ?? this.lastLocation,
      locationSharingEnabled: locationSharingEnabled ?? this.locationSharingEnabled,
      createdAt: createdAt,
    );
  }
}
