import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/khade_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/tier_badge.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.initialRole = 'customer'});

  final String initialRole;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  late String _role;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _role = widget.initialRole == 'provider' ? 'customer' : widget.initialRole;
    if (widget.initialRole == 'provider') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.push('/provider-signup');
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() { _loading = true; _error = null; });
    try {
      final user = await AuthService.instance.register(
        email: _email.text.trim(),
        password: _password.text,
        name: _name.text.trim(),
        role: _role,
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      );
      await KhadeRepository.instance.syncAfterAuth(user);
      if (!mounted) return;
      if (AuthService.instance.consumeWelcomeBonus() != null) {
        showWelcomeBonusDialog(context);
      }
      if (_role == 'provider') {
        context.go('/provider-signup');
      } else {
        context.go('/home');
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('ApiException(409): ', '').replaceFirst('ApiException(400): ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProvider = _role == 'provider';
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            IconButton(alignment: Alignment.centerLeft, onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back, color: AppColors.matcha)),
            Text(isProvider ? 'Register your business' : 'Create account', style: AppTheme.serif(32)),
            Text(
              isProvider
                  ? 'Providers sign up on our dedicated onboarding flow'
                  : 'Free ₦2,000 wallet credit · Bronze tier to start',
              style: AppTheme.sans(13, color: AppColors.soft),
            ),
            if (isProvider) ...[
              const SizedBox(height: 24),
              PrimaryButton(label: 'Continue to Provider Sign Up', onPressed: () => context.push('/provider-signup')),
              const SizedBox(height: 12),
              Center(child: TextButton(onPressed: () => setState(() => _role = 'customer'), child: Text('Register as customer instead', style: AppTheme.sans(12, color: AppColors.matcha)))),
            ] else ...[
              const SizedBox(height: 8),
              const TierBadge(tier: 'Bronze'),
              const SizedBox(height: 24),
              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.redBg, borderRadius: BorderRadius.circular(10)),
                  child: Text(_error!, style: AppTheme.sans(12, color: AppColors.redDark)),
                ),
              Row(
                children: [
                  Expanded(child: _roleChip('Customer', 'customer', Icons.person_outline)),
                  const SizedBox(width: 10),
                  Expanded(child: _roleChip('Provider', 'provider', Icons.storefront_outlined)),
                ],
              ),
              const SizedBox(height: 16),
              _field('Full name', _name),
              const SizedBox(height: 12),
              _field('Phone', _phone, keyboard: TextInputType.phone, hint: '+2348012345678'),
              const SizedBox(height: 12),
              _field('Email', _email, keyboard: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _field('Password (6+ chars)', _password, obscure: true),
              const SizedBox(height: 20),
              PrimaryButton(label: _loading ? 'Creating...' : 'Create Account', onPressed: _loading ? null : _register),
              const SizedBox(height: 12),
              Center(child: TextButton(onPressed: () => context.pop(), child: Text('Already have an account? Sign in', style: AppTheme.sans(12, color: AppColors.matcha)))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _roleChip(String label, String role, IconData icon) {
    final active = _role == role;
    return GestureDetector(
      onTap: () {
        if (role == 'provider') {
          context.push('/provider-signup');
          return;
        }
        setState(() => _role = role);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: active ? AppColors.matchaPale : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? AppColors.matcha : AppColors.border, width: active ? 2 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: active ? AppColors.matcha : AppColors.soft),
            const SizedBox(width: 8),
            Text(label, style: AppTheme.sans(12, weight: active ? FontWeight.w600 : FontWeight.w400, color: active ? AppColors.matcha : AppColors.mid)),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c, {bool obscure = false, TextInputType? keyboard, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.sans(11, color: AppColors.soft)),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          obscureText: obscure,
          keyboardType: keyboard,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
          ),
        ),
      ],
    );
  }
}
