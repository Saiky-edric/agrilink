import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/theme/app_theme.dart';

class ProfileAvatarEditor extends StatefulWidget {
  final String userId;
  final String? currentImageUrl;
  final VoidCallback? onUpdated;
  final double radius;

  const ProfileAvatarEditor({
    super.key,
    required this.userId,
    required this.currentImageUrl,
    this.onUpdated,
    this.radius = 40,
  });

  @override
  State<ProfileAvatarEditor> createState() => _ProfileAvatarEditorState();
}

class _ProfileAvatarEditorState extends State<ProfileAvatarEditor> {
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndUpload(ImageSource source) async {
    try {
      setState(() => _isUploading = true);
      final picked = await _picker.pickImage(source: source, maxWidth: 1024, imageQuality: 85);
      if (picked == null) { setState(() => _isUploading = false); return; }
      final file = File(picked.path);
      final url = await StorageService.instance.uploadUserAvatar(userId: widget.userId, image: file);
      await ProfileService().updateAvatar(url);
      if (mounted) setState(() => _isUploading = false);
      widget.onUpdated?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated')));
      }
    } catch (e) {
      if (mounted) setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update avatar: $e')));
      }
    }
  }

  Future<void> _removePhoto() async {
    try {
      setState(() => _isUploading = true);
      await ProfileService().clearAvatar();
      if (mounted) setState(() => _isUploading = false);
      widget.onUpdated?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo removed')));
      }
    } catch (e) {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () { Navigator.pop(context); _pickAndUpload(ImageSource.gallery); },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a Photo'),
                onTap: () { Navigator.pop(context); _pickAndUpload(ImageSource.camera); },
              ),
              if (widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: AppTheme.errorRed),
                  title: const Text('Remove Photo'),
                  onTap: () { Navigator.pop(context); _removePhoto(); },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: widget.radius,
          backgroundColor: Colors.white.withValues(alpha: 0.3),
          backgroundImage: widget.currentImageUrl != null
              ? NetworkImage(widget.currentImageUrl!)
              : null,
          child: widget.currentImageUrl == null
              ? const Icon(Icons.person, size: 40, color: Colors.white)
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: InkWell(
            onTap: _isUploading ? null : _showOptions,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(4),
              child: _isUploading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.camera_alt, size: 16, color: AppTheme.primaryGreen),
            ),
          ),
        ),
      ],
    );
  }
}
