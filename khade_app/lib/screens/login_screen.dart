import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/khade_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.roleHint});

  final String? roleHint;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(text: 'customer@khade.ng');
  final _password = TextEditingController(text: 'password123');
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      final user = await AuthService.instance.login(email: _email.text.trim(), password: _password.text);
      await KhadeRepository.instance.syncAfterAuth(user);
      if (!mounted) return;
      if (user.isAdmin) {
        context.go('/admin');
      } else if (user.isProvider || widget.roleHint == 'provider') {
        context.go('/provider-home');
      } else {
        context.go('/home');
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('ApiException(401): ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            IconButton(alignment: Alignment.centerLeft, onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back, color: AppColors.matcha)),
            Text('Welcome back', style: AppTheme.serif(32)),
            Text('Sign in to book, track & manage your beauty appointments', style: AppTheme.sans(13, color: AppColors.soft)),
            const SizedBox(height: 28),
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.redBg, borderRadius: BorderRadius.circular(10)),
                child: Text(_error!, style: AppTheme.sans(12, color: AppColors.redDark)),
              ),
            _field('Email', _email, keyboard: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _field('Password', _password, obscure: true),
            const SizedBox(height: 8),
            Text('Demo: customer@ / provider@ / admin@khade.ng · password123', style: AppTheme.sans(10, color: AppColors.soft)),
            const SizedBox(height: 20),
            PrimaryButton(label: _loading ? 'Signing in...' : 'Sign In', onPressed: _loading ? null : _login),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _loading ? null : () async {
                await AuthService.instance.continueAsGuest();
                await KhadeRepository.instance.initialize();
                if (context.mounted) context.go('/home');
              },
              child: const Text('Continue as guest'),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => context.push('/register'),
                child: Text('New here? Create account', style: AppTheme.sans(12, color: AppColors.matcha)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c, {bool obscure = false, TextInputType? keyboard}) {
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
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
          ),
        ),
      ],
    );
  }
}
