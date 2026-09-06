import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/primary_button.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  bool _saving = false;
  String? _newAvatarUrl;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider).value;
    _nameCtrl.text = profile?.fullName ?? '';
    _bioCtrl.text = profile?.bio ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;

    setState(() => _saving = true);
    final url = await CloudinaryService()
        .uploadImage(file, folder: 'avatars');
    setState(() {
      _newAvatarUrl = url;
      _saving = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(profileProvider.notifier).update({
      'full_name': _nameCtrl.text.trim(),
      'bio': _bioCtrl.text.trim(),
      if (_newAvatarUrl != null) 'avatar_url': _newAvatarUrl,
    });
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Modifier le profil')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Avatar
              GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      backgroundImage: _newAvatarUrl != null
                          ? NetworkImage(_newAvatarUrl!)
                          : null,
                      child: _newAvatarUrl == null
                          ? const Icon(Icons.person,
                              size: 50, color: AppColors.primary)
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  hintText: 'Parlez de vous et de votre passion culinaire...',
                  prefixIcon: Icon(Icons.info_outline),
                ),
              ),

              const SizedBox(height: 32),

              PrimaryButton(
                label: 'Sauvegarder',
                onPressed: _save,
                isLoading: _saving,
              ),
            ],
          ),
        ),
      );
}
