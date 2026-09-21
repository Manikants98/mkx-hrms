import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import 'package:mkx_core/constants/app_colors.dart';
import 'package:mkx_core/utils/ui_helpers.dart';
import 'package:mkx_core/widgets/custom_text_field.dart';
import '../state/auth_provider.dart';

/// Employee Login Screen matching the MKX HRMS design system
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      UiHelpers.showSnackBar(
        context,
        'Welcome back, ${auth.currentUser?.name ?? "Employee"}!',
        isSuccess: true,
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } else {
      UiHelpers.showSnackBar(
        context,
        auth.errorMessage ?? 'Login failed. Please verify your credentials.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = M3ETheme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Logo & Header
                    Center(
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSecondary
                              : AppColors.lightSecondary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.fingerprint_rounded,
                          size: 32,
                          color: isDark
                              ? AppColors.darkPrimary
                              : AppColors.lightPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'MKX HRMS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: isDark
                            ? AppColors.darkForeground
                            : AppColors.lightForeground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Employee Self-Service Portal',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            isDark ? AppColors.darkMuted : AppColors.lightMuted,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Card Container
                    M3ECard(
                      variant: M3ECardVariant.elevated,
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Sign In',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Enter your corporate email and password to access your dashboard.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkMuted
                                  : AppColors.lightMuted,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Email Input
                          CustomTextField(
                            controller: _emailController,
                            label: 'Corporate Email',
                            hintText: 'name@mkx.dev',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icon(
                              Icons.alternate_email_rounded,
                              size: 18,
                              color: isDark
                                  ? AppColors.darkMuted
                                  : AppColors.lightMuted,
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!val.contains('@')) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password Input
                          CustomTextField(
                            controller: _passwordController,
                            label: 'Password',
                            hintText: '••••••••',
                            obscureText: _obscurePassword,
                            prefixIcon: Icon(
                              Icons.lock_outline_rounded,
                              size: 18,
                              color: isDark
                                  ? AppColors.darkMuted
                                  : AppColors.lightMuted,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 18,
                                color: isDark
                                    ? AppColors.darkMuted
                                    : AppColors.lightMuted,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Password is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 22),

                          if (auth.isLoading)
                            Center(
                                child: SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: M3EProgressIndicator.circularWavy(
                                        strokeWidth: 3)))
                          else
                            M3EButton(
                              style: M3EButtonStyle.filled,
                              size: M3EButtonSize.md,
                              onPressed: _handleLogin,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Sign In to Portal'),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
