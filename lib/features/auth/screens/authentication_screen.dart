import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:sales_management/core/services/auth/auth_service.dart';
import 'package:sales_management/core/services/auth/token_service.dart';
import 'package:sales_management/core/services/base_api_service.dart';
import 'package:sales_management/core/theme/theme.dart';
import 'package:sales_management/core/utils/ui_feedback_service.dart';
import 'package:sales_management/core/widgets/vanguard_text_field.dart';
import 'package:sales_management/core/widgets/vanguarde_button.dart';
import 'package:sales_management/features/sales/screens/sales_dashboard_screen.dart';

class VanguardeLoginScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDark;

  const VanguardeLoginScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDark,
  });

  @override
  State<VanguardeLoginScreen> createState() => _VanguardeLoginScreenState();
}

class _VanguardeLoginScreenState extends State<VanguardeLoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  // ── 1. LOAD SAVED CREDENTIALS ON START ──
  Future<void> _loadSavedCredentials() async {
    final tokenService = TokenService();
    final creds = await tokenService.getSavedCredentials();

    if (creds != null && mounted) {
      setState(() {
        _usernameController.text = creds['username'] ?? '';
        _passwordController.text = creds['password'] ?? '';
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final username = _usernameController.text;
    final password = _passwordController.text;
    final dio = Dio();
    final uiFeedback = UiFeedbackService();
    final tokenService = TokenService();

    final baseApi = BaseApiService(dio, uiFeedback, tokenService);
    final authService = AuthService(baseApi);

    // 1. Await the role from the backend
    final String? userRole = await authService.login(username, password);

    if (!mounted) return;

    // 2. Add some debug logging to see what the role actually is
    debugPrint('🔥 RETURNED ROLE: $userRole');

    // 3. Redirect based on the role
    if (userRole != null) {

      // ── 2. SILENTLY SAVE CREDENTIALS ON SUCCESS ──
      await tokenService.saveLoginCredentials(username, password);

      switch (userRole.toUpperCase()) {
        case 'SALES_PERSON':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SalesDashboardScreen()),
          );
          break;
        default:
          uiFeedback.showError('Unknown user role: $userRole');
      }
    } else {
      uiFeedback.showError('Login failed: Could not parse user role.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<VanguardeColors>() ?? VanguardeColors.light;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Theme Toggle
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.dark_mode_outlined,
                      size: 16,
                      color: colors.subtitle,
                    ),
                    Switch(
                      value: widget.isDark,
                      onChanged: (_) => widget.onToggleTheme(),
                      activeColor: scheme.primary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 2. Hero Header Section
              Text(
                'One network.',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Every dealer, every sale.',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sign in to the Vanguarde Ops Console to manage your team and track every sale.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: colors.subtitle,
                ),
              ),

              const SizedBox(height: 40),

              // 3. The Login Form inside a styled Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: widget.isDark ? const Color(0xFF162420) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.fieldBorder, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sign in to manage your sales network.',
                      style: TextStyle(fontSize: 13, color: colors.subtitle),
                    ),

                    const SizedBox(height: 28),

                    // ── Username Field ──
                    VanguardeTextField(
                      label: 'Username',
                      labelHint: 'required',
                      hintText: 'Enter your username',
                      controller: _usernameController,
                      textInputAction: TextInputAction.next,
                    ),

                    const SizedBox(height: 16),

                    // ── Password Field ──
                    VanguardeTextField(
                      label: 'Password',
                      labelHint: 'required',
                      hintText: '••••••••',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _handleLogin(),
                      suffixIcon: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 18,
                          color: colors.fieldHint,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Login Button ──
                    VanguardeButton(
                      text: 'Sign In',
                      onPressed: _handleLogin,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}