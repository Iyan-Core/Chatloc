import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import 'auth_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  final auth = ref.watch(authServiceProvider);
  return StorageService(auth);
});

class StorageService {
  final AuthService _auth;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  final _uuid = const Uuid();

  StorageService(this._auth);

  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    return await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1080,
    );
  }

  Future<String> uploadChatImage(String chatId, File file) async {
    final ext = path.extension(file.path);
    final fileName = '${_uuid.v4()}$ext';
    final ref = _storage.ref('chats/$chatId/images/$fileName');

    final task = await ref.putFile(file);
    return await task.ref.getDownloadURL();
  }

  Future<String> uploadProfilePhoto(File file) async {
    final uid = _auth.currentUserId!;
    final ext = path.extension(file.path);
    final ref = _storage.ref('users/$uid/avatar$ext');

    final task = await ref.putFile(file);
    return await task.ref.getDownloadURL();
  }

  Future<String> uploadGroupPhoto(String chatId, File file) async {
    final ext = path.extension(file.path);
    final ref = _storage.ref('chats/$chatId/photo$ext');

    final task = await ref.putFile(file);
    return await task.ref.getDownloadURL();
  }

  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {}
  }
}
