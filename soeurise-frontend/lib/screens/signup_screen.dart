import 'package:flutter/material.dart';
import '../constants.dart';
import '../theme/glass_widgets.dart';
import '../services.dart';
import 'main_app.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(
          () => _errorMessage = 'Les mots de passe ne correspondent pas');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await AuthenticationService.instance.register(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      passwordConfirm: _confirmPasswordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainApp(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else {
      setState(() => _errorMessage = result['error'] as String?);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top bar with back
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(180),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.beigeDark.withAlpha(60),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),

                      // Header
                      FadeSlideIn(
                        child: ShaderMask(
                          shaderCallback: (bounds) =>
                              AppColors.accentGradient.createShader(bounds),
                          child: const Text(
                            'Créer un compte',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      FadeSlideIn(
                        delay: const Duration(milliseconds: 100),
                        child: Text(
                          'Rejoignez la communauté Soeurise',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Error message
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.errorColor.withAlpha(20),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.errorColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),

                      // Form glass card
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 200),
                        child: GlassCard(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // First + Last name row
                                Row(
                                  children: [
                                    Expanded(
                                      child: GlassTextField(
                                        controller: _firstNameController,
                                        label: 'Prénom',
                                        prefixIcon:
                                            Icons.person_outline_rounded,
                                        validator: (v) =>
                                            ValidationService.validateName(
                                                v ?? ''),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: GlassTextField(
                                        controller: _lastNameController,
                                        label: 'Nom',
                                        prefixIcon:
                                            Icons.person_outline_rounded,
                                        validator: (v) =>
                                            ValidationService.validateName(
                                                v ?? ''),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                GlassTextField(
                                  controller: _usernameController,
                                  label: 'Nom d\'utilisateur',
                                  prefixIcon: Icons.alternate_email_rounded,
                                  validator: (v) =>
                                      ValidationService.validateUsername(
                                          v ?? ''),
                                ),

                                const SizedBox(height: 16),

                                GlassTextField(
                                  controller: _emailController,
                                  label: 'Email',
                                  prefixIcon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) =>
                                      ValidationService.validateEmail(
                                          v ?? ''),
                                ),

                                const SizedBox(height: 16),

                                GlassTextField(
                                  controller: _passwordController,
                                  label: 'Mot de passe',
                                  prefixIcon: Icons.lock_outline_rounded,
                                  obscureText: _obscurePassword,
                                  suffix: GestureDetector(
                                    onTap: () => setState(() =>
                                        _obscurePassword =
                                            !_obscurePassword),
                                    child: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.textLight,
                                      size: 20,
                                    ),
                                  ),
                                  validator: (v) =>
                                      ValidationService.validatePassword(
                                          v ?? ''),
                                ),

                                const SizedBox(height: 16),

                                GlassTextField(
                                  controller: _confirmPasswordController,
                                  label: 'Confirmer le mot de passe',
                                  prefixIcon: Icons.lock_outline_rounded,
                                  obscureText: true,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Confirmation requise';
                                    }
                                    if (v != _passwordController.text) {
                                      return 'Ne correspond pas';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 28),

                                GlassButton(
                                  label: 'Créer le compte',
                                  icon: Icons.arrow_forward_rounded,
                                  isLoading: _isLoading,
                                  onPressed: _submit,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Login link
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 400),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Déjà un compte ? ',
                              style: AppTextStyles.bodyMedium,
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Text(
                                'Se connecter',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
