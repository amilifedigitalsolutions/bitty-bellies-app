import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/auth_header_icon.dart';
import '../providers/auth_provider.dart';

class ConfirmScreen extends ConsumerStatefulWidget {
  final String email;
  const ConfirmScreen({super.key, required this.email});

  @override
  ConsumerState<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends ConsumerState<ConfirmScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.confirmSignUp(email: widget.email, confirmationCode: _codeCtrl.text.trim());
    if (!mounted) return;
    result.when(
      success: (_) {
        context.go('/login');
      },
      failure: (e) => setState(() => _errorMessage = e.message),
    );
    setState(() => _isLoading = false);
  }

  Future<void> _resend() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.resendConfirmationCode(widget.email);
    if (mounted) setState(() => _successMessage = 'Code resent to ${widget.email}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                const AuthHeaderIcon(Icons.mark_email_read_outlined),
                const SizedBox(height: 16),
                Text('Check your email', style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 8),
                Text('We sent a confirmation code to ${widget.email}.', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 40),

                AppTextField(
                  controller: _codeCtrl,
                  label: 'Confirmation code',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _confirm(),
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter the code from your email' : null,
                ),
                const SizedBox(height: 24),

                if (_errorMessage != null)
                  Text(_errorMessage!, style: const TextStyle(color: AppColors.error)),
                if (_successMessage != null)
                  Text(_successMessage!, style: const TextStyle(color: AppColors.success)),

                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _confirm,
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Confirm email'),
                ),
                const SizedBox(height: 16),
                TextButton(onPressed: _resend, child: const Text('Resend code')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
