import 'package:flutter/cupertino.dart';
import 'package:mkx_core/features/auth/state/auth_provider.dart';
import 'package:provider/provider.dart';

import '../../../widgets/ios27_button.dart';
import '../../../widgets/ios27_glass_surface.dart';
import '../../../widgets/ios27_login_header.dart';
import '../../../widgets/ios27_text_field.dart';
import '../../../widgets/ios27_toast.dart';

/**
 * Dedicated Liquid Glass Login Screen for the Employee Mobile Application
 */
class EmployeeLoginScreen extends StatefulWidget {
  /**
   * Creates an instance of the dedicated employee login screen
   */
  const EmployeeLoginScreen({super.key});

  @override
  State<EmployeeLoginScreen> createState() => _EmployeeLoginScreenState();
}

class _EmployeeLoginScreenState extends State<EmployeeLoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberDevice = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Ios27Toast.show(
        context,
        'Welcome back, ${auth.currentUser?.name ?? "Employee"}!',
        isSuccess: true,
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } else {
      Ios27Toast.show(
        context,
        auth.errorMessage ??
            'Authentication failed. Please verify your credentials.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cupertinoTheme = CupertinoTheme.of(context);
    final isDark = cupertinoTheme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final primary = cupertinoTheme.primaryColor;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      child: Ios27Background(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Ios27LoginHeader(),
                      const SizedBox(height: 24),
                      Ios27GlassCard(
                        margin: EdgeInsets.zero,
                        padding: const EdgeInsets.all(22),
                        borderRadius: 26,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Employee Sign In',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.4,
                                    color: isDark
                                        ? CupertinoColors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  CupertinoIcons.lock_shield_fill,
                                  size: 20,
                                  color: primary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sign in with your enterprise credentials to access shifts, leaves, and payroll.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: isDark
                                    ? CupertinoColors.white
                                        .withValues(alpha: 0.55)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Ios27TextField(
                              controller: _emailController,
                              label: 'Corporate Email',
                              placeholder: 'name@mkx.monster',
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              prefixIcon: Icon(
                                CupertinoIcons.mail,
                                size: 19,
                                color: isDark
                                    ? CupertinoColors.white
                                        .withValues(alpha: 0.50)
                                    : const Color(0xFF64748B),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Email is required';
                                }
                                if (!val.contains('@')) {
                                  return 'Enter a valid corporate email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Ios27TextField(
                              controller: _passwordController,
                              label: 'Password',
                              placeholder: '••••••••',
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _handleLogin(),
                              prefixIcon: Icon(
                                CupertinoIcons.lock,
                                size: 19,
                                color: isDark
                                    ? CupertinoColors.white
                                        .withValues(alpha: 0.50)
                                    : const Color(0xFF64748B),
                              ),
                              suffixIcon: CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                child: Icon(
                                  _obscurePassword
                                      ? CupertinoIcons.eye
                                      : CupertinoIcons.eye_slash,
                                  size: 19,
                                  color: isDark
                                      ? CupertinoColors.white
                                          .withValues(alpha: 0.50)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Password is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Remember this device',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? CupertinoColors.white
                                            .withValues(alpha: 0.80)
                                        : const Color(0xFF334155),
                                  ),
                                ),
                                CupertinoSwitch(
                                  value: _rememberDevice,
                                  activeTrackColor: primary,
                                  onChanged: (val) {
                                    setState(() {
                                      _rememberDevice = val;
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            Ios27Button(
                              label: 'Sign In to Portal',
                              icon: const Icon(
                                CupertinoIcons.arrow_right_circle_fill,
                                size: 19,
                                color: CupertinoColors.white,
                              ),
                              isLoading: auth.isLoading,
                              onPressed: _handleLogin,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Center(
                        child: Text(
                          'Secured with MKX Quantum Shield & End-to-End Encryption',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? CupertinoColors.white.withValues(alpha: 0.35)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
