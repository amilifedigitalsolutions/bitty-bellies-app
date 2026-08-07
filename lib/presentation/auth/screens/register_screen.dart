import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _birthdate;
  // Default-unchecked, not pre-ticked — explicit opt-in rather than
  // opt-out, both as good practice and because it's what we told AWS SES
  // we do when requesting production sending access.
  bool _marketingOptIn = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirthdate(ValueChanged<DateTime> onPicked) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthdate ?? DateTime(now.year - 30, now.month, now.day),
      firstDate: DateTime(now.year - 120),
      // Requires the account holder to be at least 13 — a reasonable
      // minimum-age default for account creation, not explicitly
      // requested but standard practice once a birthdate is collected.
      lastDate: DateTime(now.year - 13, now.month, now.day),
      helpText: 'Your birthdate',
    );
    if (picked != null) {
      setState(() => _birthdate = picked);
      onPicked(picked);
    }
  }

  void _showAlreadyExistsDialog(String email) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Account already exists'),
        content: Text('An account with $email already exists. Would you like to sign in or reset your password?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/login');
            },
            child: const Text('Sign in'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/forgot-password');
            },
            child: const Text('Reset password'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    // FormField's own validator covers "not picked at all" (see
    // _formKey.currentState!.validate() below), but re-checked here too
    // since the value itself is needed to actually call signUp.
    if (!_formKey.currentState!.validate() || _birthdate == null) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    final email = _emailCtrl.text.trim();
    final result = await ref.read(authRepositoryProvider).signUp(
      email: email,
      password: _passwordCtrl.text,
      displayName: _nameCtrl.text.trim(),
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      birthdate: _birthdate!,
      marketingOptIn: _marketingOptIn,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);
    result.when(
      success: (_) => context.push('/confirm?email=${Uri.encodeComponent(email)}'),
      failure: (e) {
        if (e is AlreadyRegisteredError) {
          _showAlreadyExistsDialog(email);
        } else {
          setState(() => _errorMessage = e.message);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                // Real logo instead of the generic icon badge the other
                // auth screens use — sign-up is the first real branding
                // moment for a new user.
                Image.asset('assets/logos/logo-long.png', height: 48, fit: BoxFit.contain),
                const SizedBox(height: 16),
                Text('Create account', style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 8),
                Text(
                  'Join a global community of parents sharing what works in their kitchens!',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 40),

                AppTextField(
                  controller: _nameCtrl,
                  label: 'Display name',
                  hint: 'How you\'ll appear to other users',
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Display name is required';
                    if (v.trim().length < 2) return 'Must be at least 2 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _firstNameCtrl,
                        label: 'First name',
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _lastNameCtrl,
                        label: 'Last name',
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                FormField<DateTime>(
                  initialValue: _birthdate,
                  validator: (v) => v == null ? 'Birthdate is required' : null,
                  builder: (field) => InkWell(
                    onTap: () => _pickBirthdate(field.didChange),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Birthdate',
                        suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                        errorText: field.errorText,
                      ),
                      child: Text(
                        _birthdate == null
                            ? 'Tap to select a date'
                            : '${_birthdate!.year}-${_birthdate!.month.toString().padLeft(2, '0')}-${_birthdate!.day.toString().padLeft(2, '0')}',
                        style: _birthdate == null
                            ? TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _emailCtrl,
                  label: 'Email address',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email is required';
                    if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _passwordCtrl,
                  label: 'Password',
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 8) return 'Must be at least 8 characters';
                    if (!v.contains(RegExp(r'[A-Z]'))) return 'Must include an uppercase letter';
                    if (!v.contains(RegExp(r'[0-9]'))) return 'Must include a number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _confirmCtrl,
                  label: 'Confirm password',
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  validator: (v) {
                    if (v != _passwordCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Opt-in checkbox, not a hidden default — feeds the
                // marketingOptIn Cognito attribute, which WelcomeEmailLambda
                // reads to decide whether to add this user to the SES
                // marketing contact list.
                InkWell(
                  onTap: () => setState(() => _marketingOptIn = !_marketingOptIn),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _marketingOptIn,
                          onChanged: (v) => setState(() => _marketingOptIn = v ?? false),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              'Send me recipe inspiration, brand promotions, & app updates by email',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error)),
                  ),
                  const SizedBox(height: 16),
                ],

                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  // Matches the logo's own wordmark blue rather than the
                  // theme's default button blue-violet.
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.logoBlue),
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Create account'),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Sign in'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                Text(
                  'By creating an account, you agree to our Terms of Service and Privacy Policy.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
