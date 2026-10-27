import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sales_management/core/services/auth/token_service.dart';
import 'package:sales_management/core/utils/file_logger.dart';
import 'package:sales_management/features/auth/screens/authentication_screen.dart';
import 'package:sales_management/features/sales/screens/sales_dashboard_screen.dart';

class AuthCheckScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDark;

  const AuthCheckScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDark,
  });

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true; // Invalid token format

      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final payloadMap = json.decode(payload);

      final exp = payloadMap['exp'];
      if (exp != null) {
        final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        final isExpired = DateTime.now().isAfter(expiryDate);
        if (isExpired) {
          FileLogger().w("AuthCheckScreen: Token is expired. Expiry date was $expiryDate");
        }
        return isExpired;
      }
      FileLogger().w("AuthCheckScreen: Token has no 'exp' field.");
      return false;
    } catch (e) {
      FileLogger().e("AuthCheckScreen: Failed to decode token", e);
      return true;
    }
  }

  Future<void> _checkLoginStatus() async {
    final tokenService = TokenService();

    final token = await tokenService.getToken();
    final role = await tokenService.getRole();

    FileLogger().i("AuthCheckScreen: Checking login status. Has token: ${token != null}, Role: $role");

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    if (token != null && role != null && role.toUpperCase() == 'SALES_PERSON') {

      if (_isTokenExpired(token)) {
        FileLogger().w('⚠️ Token expired! Clearing session and routing to login.');
        await tokenService.clearSession();
        _routeToLogin();
      } else {
        FileLogger().i('Token valid. Routing to Sales Dashboard.');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SalesDashboardScreen()),
        );
      }

    } else {
      FileLogger().i('Missing token or invalid role. Routing to login.');
      _routeToLogin();
    }
  }

  void _routeToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => VanguardeLoginScreen(
          onToggleTheme: widget.onToggleTheme,
          isDark: widget.isDark,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: scheme.primary),
            const SizedBox(height: 24),
            Text(
              'Loading Vanguarde...',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}