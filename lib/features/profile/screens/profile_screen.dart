// lib/features/profile/screens/profile_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import 'package:sales_management/core/services/auth/token_service.dart';
import 'package:sales_management/core/services/base_api_service.dart';
import 'package:sales_management/core/utils/ui_feedback_service.dart';
import 'package:sales_management/core/utils/file_logger.dart';
import 'package:sales_management/features/profile/models/profile-model.dart';
import 'package:sales_management/features/profile/service/profile-service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileService _profileService;
  late final TokenService _tokenService;

  bool _isLoading = true;
  SalesPersonProfile? _profile;

  @override
  void initState() {
    super.initState();
    final dio = Dio();
    final uiFeedback = UiFeedbackService();
    _tokenService = TokenService();
    final baseApi = BaseApiService(dio, uiFeedback, _tokenService);
    _profileService = ProfileService(baseApi);

    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final salesIdString = await _tokenService.getUserId();
      final userId = int.tryParse(salesIdString ?? '0') ?? 0;

      if (userId == 0) throw Exception("User ID not found");

      final profile = await _profileService.getProfile(userId);

      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        UiFeedbackService().showError("Could not load profile details.");
      }
    }
  }

  ImageProvider? _getAvatarImage(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      final cleanBase64 = base64String.contains(',')
          ? base64String.split(',').last
          : base64String;
      return MemoryImage(base64Decode(cleanBase64));
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_profile == null) {
      return const Center(child: Text("Profile not found."));
    }

    final p = _profile!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── AVATAR ──
          CircleAvatar(
            radius: 56,
            backgroundColor: scheme.primaryContainer,
            backgroundImage: _getAvatarImage(p.photoBase64),
            child: _getAvatarImage(p.photoBase64) == null
                ? Icon(Icons.person, size: 56, color: scheme.onPrimaryContainer)
                : null,
          ),
          const SizedBox(height: 24),

          // ── NAME & ROLE ──
          Text(
            p.fullName,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              p.designationName.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: scheme.onSecondaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // ── BASIC CONTACT BAR ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Icon(Icons.phone_rounded, color: scheme.primary),
                    const SizedBox(height: 8),
                    Text(
                        p.mobileNumber.isEmpty ? 'N/A' : p.mobileNumber,
                        style: const TextStyle(fontWeight: FontWeight.w600)
                    ),
                  ],
                ),
                Container(width: 1, height: 40, color: scheme.outlineVariant.withOpacity(0.5)),
                Column(
                  children: [
                    Icon(Icons.badge_rounded, color: scheme.primary),
                    const SizedBox(height: 8),
                    Text(
                        p.username,
                        style: const TextStyle(fontWeight: FontWeight.w600)
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── SHARE LOGS BUTTON ──
          ElevatedButton.icon(
            onPressed: () async {
              await FileLogger().shareLogs();
            },
            icon: const Icon(Icons.bug_report),
            label: const Text('Share App Logs'),
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.errorContainer,
              foregroundColor: scheme.onErrorContainer,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}