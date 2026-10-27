import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sales_management/core/theme/theme.dart';

class VanguardeImagePicker extends StatefulWidget {
  final String label;
  final String hintText;
  final ValueChanged<String?> onPhotoChanged;
  final String? initialPhotoBase64;

  const VanguardeImagePicker({
    super.key,
    required this.label,
    this.hintText = 'Tap to take photo',
    required this.onPhotoChanged,
    this.initialPhotoBase64,
  });

  @override
  State<VanguardeImagePicker> createState() => _VanguardeImagePickerState();
}

class _VanguardeImagePickerState extends State<VanguardeImagePicker> {
  String? _photoBase64;

  @override
  void initState() {
    super.initState();
    _photoBase64 = widget.initialPhotoBase64;
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1024,
    );

    if (photo != null) {
      final bytes = await photo.readAsBytes();
      final base64String = base64Encode(bytes);

      setState(() {
        _photoBase64 = base64String;
      });

      // Pass the data back up to the parent form
      widget.onPhotoChanged(base64String);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<VanguardeColors>() ?? VanguardeColors.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 7),
        GestureDetector(
          onTap: _takePhoto,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colors.fieldBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.fieldBorder),
              image: _photoBase64 != null
                  ? DecorationImage(
                image: MemoryImage(base64Decode(_photoBase64!)),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: _photoBase64 == null
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt_outlined, color: colors.fieldHint, size: 32),
                const SizedBox(height: 8),
                Text(
                  widget.hintText,
                  style: TextStyle(color: colors.fieldHint, fontSize: 13),
                ),
              ],
            )
                : Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.6),
                  radius: 16,
                  child: const Icon(Icons.edit, color: Colors.white, size: 16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}