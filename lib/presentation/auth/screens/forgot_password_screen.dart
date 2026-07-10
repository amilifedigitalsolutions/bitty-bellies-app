import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _codeSent = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });
    final result = await ref.read(authRepositoryProvider).forgotPassword(_emailCtrl.text.trim());
    if (!mounted) return;
    result.when(
      success: (_) => setState(() => _codeSent = true),
      failure: (e) => setState(() => _error = e.message),
    );
    setState(() => _isLoading = false);
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });
    final result = await ref.read(authRepositoryProvider).confirmForgotPassword(
      email: _emailCtrl.text.trim(),
      newPassword: _passwordCtrl.text,
      confirmationCode: _codeCtrl.text.trim(),
    );
    if (!mounted) return;
    result.when(
      success: (_) => context.go('/login'),
      failure: (e) => setState(() => _error = e.message),
    );
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  controller: _emailCtrl,
                  label: 'Email address',
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_codeSent,
                  validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
                if (_codeSent) ...[
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _codeCtrl,
                    label: 'Reset code',
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.isEmpty) ? 'Enter the code from your email' : null,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _passwordCtrl,
                    label: 'New password',
                    obscureText: true,
                    validator: (v) {
                      if (v == null || v.length < 8) return 'Must be at least 8 characters';
                      if (!v.contains(RegExp(r'[A-Z]'))) return 'Must include an uppercase letter';
                      if (!v.contains(RegExp(r'[0-9]'))) return 'Must include a number';
                      return null;
                    },
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(color: Color(0xFFD32F2F))),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : (_codeSent ? _resetPassword : _sendCode),
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_codeSent ? 'Set new password' : 'Send reset code'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
