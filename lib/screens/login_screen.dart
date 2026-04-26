import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_button.dart';
import '../../utils/validators.dart';
import '../../utils/snackbar_util.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      await ref.read(authServiceProvider).signInWithEmailPassword(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
          );
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) SnackbarUtil.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),

                // Header
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.secondary],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),

                const SizedBox(height: 32),

                const Text(
                  'Welcome back 👋',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ).animate().slideX(begin: -0.2, duration: 400.ms).fadeIn(),

                const SizedBox(height: 8),

                Text(
                  'Sign in to continue chatting',
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ).animate().slideX(begin: -0.2, delay: 100.ms, duration: 400.ms).fadeIn(delay: 100.ms),

                const SizedBox(height: 48),

                // Email
                CustomTextField(
                  controller: _emailCtrl,
                  label: 'Email',
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: Validators.email,
                ).animate().slideY(begin: 0.2, delay: 200.ms, duration: 400.ms).fadeIn(delay: 200.ms),

                const SizedBox(height: 16),

                // Password
                CustomTextField(
                  controller: _passCtrl,
                  label: 'Password',
                  hint: '••••••••',
                  obscureText: _obscurePass,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                  validator: Validators.password,
                ).animate().slideY(begin: 0.2, delay: 300.ms, duration: 400.ms).fadeIn(delay: 300.ms),

                const SizedBox(height: 12),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/auth/forgot-password'),
                    child: const Text('Forgot password?'),
                  ),
                ),

                const SizedBox(height: 24),

                // Login button
                SizedBox(
                  width: double.infinity,
                  child: LoadingButton(
                    onPressed: _login,
                    isLoading: _loading,
                    label: 'Sign In',
                  ),
                ).animate().slideY(begin: 0.2, delay: 400.ms, duration: 400.ms).fadeIn(delay: 400.ms),

                const SizedBox(height: 32),

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/auth/register'),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
