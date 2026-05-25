import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../../providers/providers.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.signIn(_emailCtrl.text.trim(), _passCtrl.text);
    if (ok && mounted) Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Logo / Icon
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.bgHighlight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: const Icon(Icons.wb_sunny_rounded,
                      color: AppColors.primary, size: 32),
                ),
                const SizedBox(height: 32),

                Text('Welcome back', style: Theme.of(context).textTheme.displayLarge),
                const SizedBox(height: 8),
                Text('Sign in to track your vitamin D',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 40),

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter your email';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter your password';
                    if (v.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _showForgotPassword(context),
                    child: const Text('Forgot password?',
                        style: TextStyle(color: AppColors.primary)),
                  ),
                ),
                const SizedBox(height: 8),

                // Error
                if (auth.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.statusDeficientBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.statusDeficient, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(auth.error!,
                          style: const TextStyle(color: AppColors.statusDeficient,
                              fontSize: 13))),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],

                // Sign In button
                ElevatedButton(
                  onPressed: auth.loading ? null : _login,
                  child: auth.loading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Sign In'),
                ),
                const SizedBox(height: 24),

                // Sign Up link
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text("Don't have an account? ",
                      style: TextStyle(color: AppColors.textSecondary)),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SignupScreen())),
                    child: const Text('Sign Up',
                        style: TextStyle(color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPassword(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (diagContext) => AlertDialog(
      backgroundColor: AppColors.bgCard,
      title: const Text('Reset Password'),
      content: TextField(
        controller: ctrl,
        decoration: const InputDecoration(labelText: 'Your email'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(diagContext),
            child: const Text('Cancel')),
        TextButton(onPressed: () async {
          final email = ctrl.text.trim();
          if (email.isEmpty) return;
          
          final auth = context.read<AuthProvider>();
          await auth.sendPasswordReset(email);
          
          if (mounted) {
            Navigator.pop(diagContext);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Password reset email sent')));
          }
        }, child: const Text('Send', style: TextStyle(color: AppColors.primary))),
      ],
    ));
  }
}
