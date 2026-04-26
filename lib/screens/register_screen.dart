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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      await ref.read(authServiceProvider).registerWithEmailPassword(
            name: _nameCtrl.text.trim(),
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Create account ✨',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ).animate().slideX(begin: -0.2, duration: 400.ms).fadeIn(),

                const SizedBox(height: 8),
                Text(
                  'Join ChatLoc today',
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white54
                        : Colors.black45,
                  ),
                ).animate().slideX(begin: -0.2, delay: 100.ms, duration: 400.ms).fadeIn(delay: 100.ms),

                const SizedBox(height: 40),

                CustomTextField(
                  controller: _nameCtrl,
                  label: 'Full Name',
                  hint: 'John Doe',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (v) => v == null || v.trim().length < 2
                      ? 'Name must be at least 2 characters'
                      : null,
                ).animate().slideY(begin: 0.2, delay: 150.ms, duration: 400.ms).fadeIn(delay: 150.ms),

                const SizedBox(height: 16),

                CustomTextField(
                  controller: _emailCtrl,
                  label: 'Email',
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: Validators.email,
                ).animate().slideY(begin: 0.2, delay: 200.ms, duration: 400.ms).fadeIn(delay: 200.ms),

                const SizedBox(height: 16),

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
                ).animate().slideY(begin: 0.2, delay: 250.ms, duration: 400.ms).fadeIn(delay: 250.ms),

                const SizedBox(height: 16),

                CustomTextField(
                  controller: _confirmPassCtrl,
                  label: 'Confirm Password',
                  hint: '••••••••',
                  obscureText: _obscurePass,
                  prefixIcon: Icons.lock_outline,
                  validator: (v) => v != _passCtrl.text ? 'Passwords do not match' : null,
                ).animate().slideY(begin: 0.2, delay: 300.ms, duration: 400.ms).fadeIn(delay: 300.ms),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: LoadingButton(
                    onPressed: _register,
                    isLoading: _loading,
                    label: 'Create Account',
                  ),
                ).animate().slideY(begin: 0.2, delay: 350.ms, duration: 400.ms).fadeIn(delay: 350.ms),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? '),
                    TextButton(
                      onPressed: () => context.go('/auth/login'),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
