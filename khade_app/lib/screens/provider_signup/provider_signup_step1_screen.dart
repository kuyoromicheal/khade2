import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/khade_repository.dart';
import '../../services/provider_onboarding_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/password_strength_bar.dart';
import '../../widgets/provider_onboard_layout.dart';

class ProviderSignupStep1Screen extends StatefulWidget {
  const ProviderSignupStep1Screen({super.key});

  @override
  State<ProviderSignupStep1Screen> createState() => _ProviderSignupStep1ScreenState();
}

class _ProviderSignupStep1ScreenState extends State<ProviderSignupStep1Screen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;
  bool _agreed = false;
  bool _loading = false;

  bool get _passwordValid => RegExp(r'^(?=.*[A-Z])(?=.*\d).{8,}$').hasMatch(_password.text);
  bool get _emailValid => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(_email.text);
  bool get _canContinue => _firstName.text.trim().isNotEmpty && _lastName.text.trim().isNotEmpty && _emailValid && _passwordValid && _agreed;

  Future<void> _next() async {
    setState(() => _loading = true);
    try {
      final user = await AuthService.instance.register(
        email: _email.text.trim(),
        password: _password.text,
        name: '${_firstName.text.trim()} ${_lastName.text.trim()}',
        role: 'provider',
      );
      await KhadeRepository.instance.syncAfterAuth(user);
      ProviderOnboardingController.instance.update((d) => d.copyWith(
            userId: user.id,
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            email: _email.text.trim(),
          ));
      if (mounted) context.go('/provider-signup/step2');
    } catch (e) {
      if (mounted) {
        final msg = e.toString()
            .replaceFirst('ApiException(0): ', '')
            .replaceFirst('ApiException(409): ', '')
            .replaceFirst('ApiException(400): ', '')
            .replaceFirst('ApiException(401): ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.redDark),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProviderOnboardLayout(
      step: 1,
      onBack: () => context.go('/provider-signup'),
      onNext: _next,
      nextDisabled: !_canContinue,
      loading: _loading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Let's get you set up", style: ProviderOnboardStyles.stepTitle(context)),
          const SizedBox(height: 6),
          Text('What should we call you?', style: ProviderOnboardStyles.stepSub(context)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: TextField(controller: _firstName, decoration: ProviderOnboardStyles.input('First name'), onChanged: (_) => setState(() {}))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _lastName, decoration: ProviderOnboardStyles.input('Last name'), onChanged: (_) => setState(() {}))),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: ProviderOnboardStyles.input('Email address'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: !_showPassword,
            decoration: ProviderOnboardStyles.input('Create a password').copyWith(
              suffixIcon: IconButton(
                icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          PasswordStrengthBar(password: _password.text),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => setState(() => _agreed = !_agreed),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22, height: 22,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: _agreed ? AppColors.matcha : AppColors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _agreed ? AppColors.matcha : AppColors.border),
                  ),
                  child: _agreed ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: "I agree to Khade's ",
                      style: AppTheme.sans(12, color: AppColors.mid),
                      children: [
                        TextSpan(text: 'Terms of Service', style: AppTheme.sans(12, color: AppColors.matcha)),
                        const TextSpan(text: ' and '),
                        TextSpan(text: 'Privacy Policy', style: AppTheme.sans(12, color: AppColors.matcha)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
