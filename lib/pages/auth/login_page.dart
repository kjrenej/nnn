import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../auth/auth_service.dart';
import '../../l10n/localizations.dart';
import '../../theme/rento_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.initialPage = 0});

  /// 0 = Login, 1 = Sign Up
  final int initialPage;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final PageController _pageController;

  // ── Login fields ──
  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailCtrl = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();
  bool _loginPasswordVisible = false;

  // ── Signup fields ──
  final _signupFormKey = GlobalKey<FormState>();
  final _signupEmailCtrl = TextEditingController();
  final _signupPasswordCtrl = TextEditingController();
  final _signupConfirmCtrl = TextEditingController();
  bool _signupPasswordVisible = false;
  bool _signupConfirmVisible = false;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _loginEmailCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _signupEmailCtrl.dispose();
    _signupPasswordCtrl.dispose();
    _signupConfirmCtrl.dispose();
    super.dispose();
  }

  // ── Auth actions ────────────────────────────────────────────

  Future<void> _requestLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    try {
      Position position = await Geolocator.getCurrentPosition();
      debugPrint("User location: ${position.latitude}, ${position.longitude}");
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      await AuthService.instance.signInWithGoogle();
      // Navigation is handled reactively by the router via AuthService.isNewUser
      // New users → /user-details, existing users → /
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

 Future<void> _signIn() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final ok = await AuthService.instance.signInWithEmail(
        email: _loginEmailCtrl.text.trim(),
        password: _loginPasswordCtrl.text,
      );
      if (!ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sign-in failed. Please check your credentials.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      await _requestLocation();
      if (mounted) context.go('/');
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

 Future<void> _register() async {
    if (!_signupFormKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final ok = await AuthService.instance.signUpWithEmail(
        email: _signupEmailCtrl.text.trim(),
        password: _signupPasswordCtrl.text,
      );

      if (!ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sign-up failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Case A: session immediately available (email confirmation disabled in Supabase)
      if (AuthService.instance.loggedIn) {
        await _requestLocation();
        if (mounted) context.go('/user-details');
        return;
      }

      // Case B: email confirmation required — tell the user to check their inbox
      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Verify your email'),
            content: const Text(
              'A confirmation link has been sent to your email address. '
              'Please verify it and then log in.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _goToPage(0); // Switch to login tab
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: PageView(
            physics: const NeverScrollableScrollPhysics(),
            controller: _pageController,
            children: [_buildLoginPage(context), _buildSignupPage(context)],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // PAGE 0 — LOGIN
  // ═══════════════════════════════════════════════════════════

  Widget _buildLoginPage(BuildContext context) {
    final l = RentoLocalizations.of(context);
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Container(
            decoration: BoxDecoration(color: theme.colorScheme.surface),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 16),
                // ── Logo ──
                _buildLogo(context),

                // ── Form ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      child: Form(
                        key: _loginFormKey,
                        child: Column(
                          children: [
                            // Title
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                l.get('appName') == 'Rento'
                                    ? 'Welcome'
                                    : 'स्वागत है',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),

                            // Subtitle
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                12,
                                16,
                                24,
                              ),
                              child: Text(
                                'Fill out the information below to access your account.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ),

                            // Email
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildTextField(
                                controller: _loginEmailCtrl,
                                label: l.get('email'),
                                keyboardType: TextInputType.emailAddress,
                                validator: _emailValidator,
                              ),
                            ),

                            // Password
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildTextField(
                                controller: _loginPasswordCtrl,
                                label: l.get('password'),
                                obscure: !_loginPasswordVisible,
                                validator: _passwordValidator,
                                suffixIcon: _visibilityToggle(
                                  visible: _loginPasswordVisible,
                                  onTap: () => setState(
                                    () => _loginPasswordVisible =
                                        !_loginPasswordVisible,
                                  ),
                                ),
                              ),
                            ),

                            // Sign In button
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildPrimaryButton(
                                label: l.get('login'),
                                onPressed: _loading ? null : _signIn,
                                loading: _loading,
                              ),
                            ),

                            // "Or sign in with"
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              child: Text(
                                'Or sign in with',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ),

                            // Google button
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: _buildSocialButton(
                                context,
                                iconWidget: Image.network(
                                  'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
                                  width: 22,
                                  height: 22,
                                ),
                                label: 'Continue with Google',
                                onPressed: _loading ? () {} : _signInWithGoogle,
                              ),
                            ),

                            // Apple button
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: _buildSocialButton(
                                context,
                                iconWidget: Icon(
                                  Icons.apple,
                                  size: 24,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                                label: 'Continue with Apple',
                                onPressed: () {
                                  // TODO: Implement Apple sign-in
                                },
                              ),
                            ),

                            // "Don't have an account? Sign Up here"
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                12,
                                16,
                                12,
                              ),
                              child: _buildPageToggle(
                                context,
                                question: "${l.get('dontHaveAccount')}   ",
                                action: l.get('signUp'),
                                onTap: () => _goToPage(1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── "rento" footer ──
                _buildRentoFooter(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // PAGE 1 — SIGN UP
  // ═══════════════════════════════════════════════════════════

  Widget _buildSignupPage(BuildContext context) {
    final l = RentoLocalizations.of(context);
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Container(
            decoration: BoxDecoration(color: theme.colorScheme.surface),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 16),
                // ── Logo ──
                _buildLogo(context),

                // ── Form ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      child: Form(
                        key: _signupFormKey,
                        child: Column(
                          children: [
                            // Title
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                'Welcome',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),

                            // Subtitle
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                12,
                                16,
                                24,
                              ),
                              child: Text(
                                'Fill out the information below to create your account.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ),

                            // Email
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildTextField(
                                controller: _signupEmailCtrl,
                                label: l.get('email'),
                                keyboardType: TextInputType.emailAddress,
                                validator: _emailValidator,
                              ),
                            ),

                            // Password
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildTextField(
                                controller: _signupPasswordCtrl,
                                label: l.get('password'),
                                obscure: !_signupPasswordVisible,
                                validator: _passwordValidator,
                                suffixIcon: _visibilityToggle(
                                  visible: _signupPasswordVisible,
                                  onTap: () => setState(
                                    () => _signupPasswordVisible =
                                        !_signupPasswordVisible,
                                  ),
                                ),
                              ),
                            ),

                            // Confirm Password
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildTextField(
                                controller: _signupConfirmCtrl,
                                label: l.get('confirmPassword'),
                                obscure: !_signupConfirmVisible,
                                validator: (v) {
                                  if (v != _signupPasswordCtrl.text) {
                                    return "Passwords don't match";
                                  }
                                  return null;
                                },
                                suffixIcon: _visibilityToggle(
                                  visible: _signupConfirmVisible,
                                  onTap: () => setState(
                                    () => _signupConfirmVisible =
                                        !_signupConfirmVisible,
                                  ),
                                ),
                              ),
                            ),

                            // Register button
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildPrimaryButton(
                                label: l.get('signUp'),
                                onPressed: _loading ? null : _register,
                                loading: _loading,
                                color: const Color(0xFF34A853),
                              ),
                            ),

                            // "Already have an account? Sign in here"
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                12,
                                16,
                                12,
                              ),
                              child: _buildPageToggle(
                                context,
                                question: "${l.get('alreadyHaveAccount')}   ",
                                action: l.get('login'),
                                onTap: () => _goToPage(0),
                                accentColor: const Color(0xFF34A853),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── "rento" footer ──
                _buildRentoFooter(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ═══════════════════════════════════════════════════════════

  Widget _buildLogo(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 150,
      alignment: Alignment.center,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          gradient: RentoTheme.primaryGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: RentoTheme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.home_work_rounded,
          size: 52,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscure = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        filled: true,
        fillColor: theme.scaffoldBackgroundColor,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: borderColor),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: RentoTheme.primaryColor,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: RentoTheme.errorColor),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: RentoTheme.errorColor,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _visibilityToggle({
    required bool visible,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      focusNode: FocusNode(skipTraversal: true),
      child: Icon(
        visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
        size: 22,
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
    bool loading = false,
    Color color = RentoTheme.primaryColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Widget _buildSocialButton(
    BuildContext context, {
    required Widget iconWidget,
    required String label,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: iconWidget,
        label: Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: theme.scaffoldBackgroundColor,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildPageToggle(
    BuildContext context, {
    required String question,
    required String action,
    required VoidCallback onTap,
    Color accentColor = RentoTheme.successColor,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: onTap,
      child: RichText(
        textScaler: MediaQuery.of(context).textScaler,
        text: TextSpan(
          children: [
            TextSpan(text: question, style: const TextStyle()),
            TextSpan(
              text: action,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          style: theme.textTheme.bodyMedium,
        ),
      ),
    );
  }

  Widget _buildRentoFooter(BuildContext context) {
    final theme = Theme.of(context);
    final headlineStyle = theme.textTheme.headlineSmall;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('r', style: headlineStyle),
          Align(
            alignment: Alignment.center,
            child: Transform.rotate(
              angle: 340 * (math.pi / 180),
              alignment: const Alignment(0, 0.2),
              origin: const Offset(2, 0),
              child: Text('e', style: headlineStyle),
            ),
          ),
          Text('n', style: headlineStyle),
          Text('t', style: headlineStyle),
          Text(
            'o',
            style: headlineStyle?.copyWith(color: theme.colorScheme.error),
          ),
        ],
      ),
    );
  }

  // ── Validators ──

  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email required';
    if (!v.contains('@')) return 'Invalid email';
    return null;
  }

  String? _passwordValidator(String? v) {
    if (v == null || v.isEmpty) return 'Password required';
    if (v.length < 6) return 'Min 6 characters';
    return null;
  }
}
