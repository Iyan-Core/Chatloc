import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/user_avatar.dart';
import '../../utils/snackbar_util.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  File? _newPhoto;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  void _loadCurrentData() {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user != null) {
      _nameCtrl.text = user.name;
      _bioCtrl.text = user.bio ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await ref.read(storageServiceProvider).pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _newPhoto = File(file.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      String? photoUrl;
      if (_newPhoto != null) {
        photoUrl = await ref.read(storageServiceProvider).uploadProfilePhoto(_newPhoto!);
      }

      await ref.read(authServiceProvider).updateProfile(
            name: _nameCtrl.text.trim(),
            bio: _bioCtrl.text.trim(),
            photoUrl: photoUrl,
          );

      if (mounted) {
        SnackbarUtil.showSuccess(context, 'Profile updated!');
        context.pop();
      }
    } catch (e) {
      if (mounted) SnackbarUtil.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('Edit Profile'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Avatar
            Center(
              child: Stack(
                children: [
                  _newPhoto != null
                      ? CircleAvatar(radius: 55, backgroundImage: FileImage(_newPhoto!))
                      : UserAvatar(
                          name: user?.name ?? '',
                          photoUrl: user?.photoUrl,
                          radius: 55,
                        ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickPhoto,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF6C63FF),
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            CustomTextField(
              controller: _nameCtrl,
              label: 'Name',
              prefixIcon: Icons.person_outline,
              validator: (v) => v == null || v.trim().length < 2 ? 'Too short' : null,
            ),

            const SizedBox(height: 16),

            CustomTextField(
              controller: _bioCtrl,
              label: 'Bio',
              hint: 'Tell something about yourself...',
              prefixIcon: Icons.info_outline,
              maxLines: 3,
            ),

            const SizedBox(height: 32),

            LoadingButton(
              onPressed: _save,
              isLoading: _loading,
              label: 'Save Changes',
            ),
          ],
        ),
      ),
    );
  }
}
