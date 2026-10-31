// lib/features/profile/screens/profile_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import 'package:provider/provider.dart';
import 'package:sales_management/core/services/theme/theme_service.dart';
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

  void _showSettingsSheet(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                
                // ── THEME SELECTOR ──
                Consumer<ThemeService>(
                  builder: (context, themeService, child) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Appearance', style: TextStyle(fontWeight: FontWeight.bold, color: scheme.onSurface)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Dark Mode', style: TextStyle(color: scheme.onSurfaceVariant)),
                              Switch(
                                value: themeService.isDark,
                                onChanged: (val) => themeService.toggleThemeMode(),
                                activeColor: scheme.primary,
                              ),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text('Theme Style', style: TextStyle(color: scheme.onSurfaceVariant)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<ThemeStyle>(
                            value: themeService.themeStyle,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            items: ThemeStyle.values.map((style) {
                              return DropdownMenuItem(
                                value: style,
                                child: Text(style.label),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) themeService.setThemeStyle(val);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                
                // ── SHARE LOGS BUTTON ──
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
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
                const SizedBox(height: 24),
                
                // ── LOGOUT BUTTON ──
                OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _tokenService.clearSession();
                    if (!context.mounted) return;
                    // Navigate to AuthCheckScreen to trigger clean restart
                    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Log Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.error,
                    side: BorderSide(color: scheme.error.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
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

    return Stack(
      children: [
        // The main profile content
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24.0, 48.0, 24.0, 24.0),
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

              // ── CONTACT INFO GRID ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
                ),
                child: Column(
                  children: [
                    _ProfileDetailRow(icon: Icons.phone_rounded, label: 'Mobile', value: p.mobileNumber.isEmpty ? 'N/A' : p.mobileNumber),
                    const Divider(height: 24),
                    _ProfileDetailRow(icon: Icons.badge_rounded, label: 'Username', value: p.username),
                    const Divider(height: 24),
                    _ProfileDetailRow(icon: Icons.credit_card_rounded, label: 'PAN Card', value: p.pancard.isEmpty ? 'N/A' : p.pancard),
                    const Divider(height: 24),
                    _ProfileDetailRow(icon: Icons.fingerprint_rounded, label: 'Aadhar', value: p.aadharId.isEmpty ? 'N/A' : p.aadharId),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // ── ADDRESS CARD ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 20, color: scheme.primary),
                        const SizedBox(width: 8),
                        Text('Address', style: TextStyle(fontWeight: FontWeight.bold, color: scheme.onSurface)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (p.addressLine1.isNotEmpty) Text(p.addressLine1, style: TextStyle(color: scheme.onSurfaceVariant)),
                    if (p.addressLine2.isNotEmpty) Text(p.addressLine2, style: TextStyle(color: scheme.onSurfaceVariant)),
                    if (p.landmark.isNotEmpty) Text('Landmark: ${p.landmark}', style: TextStyle(color: scheme.onSurfaceVariant)),
                    if (p.area.isNotEmpty) Text(p.area, style: TextStyle(color: scheme.onSurfaceVariant)),
                    Text('${p.city.isNotEmpty ? p.city : "Unknown City"}, ${p.state.isNotEmpty ? p.state : "Unknown State"} - ${p.pinCode}', style: TextStyle(color: scheme.onSurfaceVariant)),
                    Text(p.country.isNotEmpty ? p.country : "India", style: TextStyle(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
        
        // ── SETTINGS BUTTON (Top Right) ──
        Positioned(
          top: 16,
          right: 16,
          child: IconButton(
            icon: const Icon(Icons.settings_outlined),
            color: scheme.onSurfaceVariant,
            iconSize: 28,
            onPressed: () => _showSettingsSheet(context),
          ),
        ),
      ],
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileDetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: scheme.primary, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: scheme.onSurface)),
          ],
        ),
      ],
    );
  }
}