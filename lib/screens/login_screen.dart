import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/nature_leaf_background.dart';
import 'mode_selection_screen.dart';
import 'privacy_policy_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _authError;

  /// Whether to display the Google Sign In button and OR divider on the screen.
  /// Temporarily hidden for the current release per project requirements (see AGENTS.md).
  /// All underlying functionality and methods are kept completely intact.
  static const bool _showGoogleSignIn = false;

  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _identifierController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _identifierController.dispose();
    super.dispose();
  }

  void _proceedToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, anim, secAnim) => const ModeSelectionScreen(),
        transitionsBuilder: (context, anim, secAnim, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  Future<void> _handleEmailPasswordAuth() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _authError = null;
    });
    try {
      if (_isSignUp) {
        await AuthService.instance.registerWithUsername(
          username: _usernameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          avatar: AuthService.predefinedAvatars.first,
        );
        _showToast('Welcome, ${_usernameController.text.trim()}! Account created.');
      } else {
        final user = await AuthService.instance.loginWithUsernameOrEmail(
          identifier: _identifierController.text,
          password: _passwordController.text,
        );
        _showToast('Welcome back, ${user.username}!');
      }
      _proceedToHome();
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      debugPrint('[LoginScreen] Authentication failed: $message');
      if (mounted) setState(() => _authError = message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _authError = null;
    });

    try {
      final user = await AuthService.instance.signInWithGoogle();
      _showToast('Signed in with Google as ${user.username}!');
      _proceedToHome();
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      debugPrint('[LoginScreen] Google sign-in failed: $message');
      if (mounted) setState(() => _authError = message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGuestLogin() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _authError = null;
    });
    try {
      await AuthService.instance.continueAsGuest();
      _showToast('Playing as Guest!');
      _proceedToHome();
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      debugPrint('[LoginScreen] Guest sign-in failed: $message');
      if (mounted) setState(() => _authError = message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearAuthError() {
    if (_authError != null) setState(() => _authError = null);
  }

  void _showToast(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.red : AppTheme.emerald,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return Scaffold(
      body: NatureLeafBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo & Header
                    _buildHeader(context),
                    const SizedBox(height: 24),

                    // Card with Form
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF132244) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark ? Colors.white.withAlpha(22) : Colors.black.withAlpha(15),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(isDark ? 90 : 20),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_authError != null) ...[
                                _buildAuthError(context),
                                const SizedBox(height: 16),
                              ],
                              if (AuthService.cloudInitAttempted &&
                                  !AuthService.isCloudAvailable) ...[
                                _buildOfflineNotice(context),
                                const SizedBox(height: 16),
                              ],

                              // Toggle Login / Sign Up
                              _buildModeTabs(context),
                              const SizedBox(height: 24),

                              // Form Inputs
                              if (_isSignUp) ...[
                                _buildUsernameField(context),
                                const SizedBox(height: 16),
                                _buildEmailField(context),
                                const SizedBox(height: 16),
                              ] else ...[
                                _buildIdentifierField(context),
                                const SizedBox(height: 16),
                              ],

                              _buildPasswordField(context),
                              if (_isSignUp) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Use at least 8 characters with a letter and a number.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.getMuted(context),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),

                              // Submit Button
                              _buildSubmitButton(context),

                              // Google Sign In Button (hidden for this release, toggle in _showGoogleSignIn)
                              if (_showGoogleSignIn) ...[
                                const SizedBox(height: 20),
                                // "OR" Divider
                                _buildOrDivider(context),
                                const SizedBox(height: 20),
                                // Google Sign In Button
                                _buildGoogleSignInButton(context),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Guest / Skip Button
                      TextButton.icon(
                        onPressed: _isLoading ? null : _handleGuestLogin,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const Text(
                          'Skip for now · Play as Guest',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.getMuted(context),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Privacy Policy Button (Opens on New Screen)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PrivacyPolicyScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.shield_outlined,
                          size: 15,
                          color: AppTheme.blue,
                        ),
                        label: const Text(
                          'Privacy Policy',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.getMuted(context),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_isLoading)
              Container(
                color: Colors.black45,
                child: const Center(
                  child: CircularProgressIndicator(color: AppTheme.emerald),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.emerald.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            'Aa',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Color(0xFFA8E6CF), Color(0xFF2ECC71)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: Text(
            'SHABDKHOJ',
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.emerald.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.emerald.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            'WORD SEARCH PUZZLE',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: AppTheme.emerald,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthError(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.red.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _authError!,
              style: const TextStyle(
                fontSize: 13,
                height: 1.3,
                color: AppTheme.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineNotice(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppTheme.gold, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Offline mode: cloud sign-in is unavailable. Check your internet connection.',
              style: TextStyle(
                fontSize: 12,
                height: 1.3,
                color: AppTheme.getText(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTabs(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgDark.withValues(alpha: 0.6) : AppTheme.bgLightMedium,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_isSignUp) {
                  setState(() => _isSignUp = false);
                  _clearAuthError();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_isSignUp ? AppTheme.getCard(context) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !_isSignUp
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Log In',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: !_isSignUp ? FontWeight.w700 : FontWeight.w500,
                    color: !_isSignUp ? AppTheme.getText(context) : AppTheme.getMuted(context),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!_isSignUp) {
                  setState(() => _isSignUp = true);
                  _clearAuthError();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isSignUp ? AppTheme.getCard(context) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _isSignUp
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Sign Up',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: _isSignUp ? FontWeight.w700 : FontWeight.w500,
                    color: _isSignUp ? AppTheme.getText(context) : AppTheme.getMuted(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsernameField(BuildContext context) {
    return TextFormField(
      controller: _usernameController,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.newUsername],
      autocorrect: false,
      maxLength: 20,
      onChanged: (_) => _clearAuthError(),
      style: TextStyle(color: AppTheme.getText(context)),
      decoration: _inputDecoration(
        context,
        label: 'Username',
        hint: 'Choose a player username',
        icon: Icons.person_outline_rounded,
      ).copyWith(counterText: ''),
      validator: (val) => AuthService.validateUsername(val ?? ''),
    );
  }

  Widget _buildEmailField(BuildContext context) {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.email],
      autocorrect: false,
      maxLength: 254,
      onChanged: (_) => _clearAuthError(),
      style: TextStyle(color: AppTheme.getText(context)),
      decoration: _inputDecoration(
        context,
        label: 'Email',
        hint: 'your.email@example.com',
        icon: Icons.mail_outline_rounded,
      ).copyWith(counterText: ''),
      validator: (val) => AuthService.validateEmail(val ?? ''),
    );
  }

  Widget _buildIdentifierField(BuildContext context) {
    return TextFormField(
      controller: _identifierController,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.username, AutofillHints.email],
      autocorrect: false,
      maxLength: 254,
      onChanged: (_) => _clearAuthError(),
      style: TextStyle(color: AppTheme.getText(context)),
      decoration: _inputDecoration(
        context,
        label: 'Username or Email',
        hint: 'Enter username or email',
        icon: Icons.account_circle_outlined,
      ).copyWith(counterText: ''),
      validator: (val) {
        if (val == null || val.trim().isEmpty) return 'Please enter your username or email';
        return null;
      },
    );
  }

  Widget _buildPasswordField(BuildContext context) {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      enableSuggestions: false,
      autocorrect: false,
      maxLength: 128,
      textInputAction: TextInputAction.done,
      autofillHints: const [
        AutofillHints.password,
        AutofillHints.newPassword,
      ],
      onChanged: (_) => _clearAuthError(),
      onFieldSubmitted: (_) {
        if (!_isLoading) _handleEmailPasswordAuth();
      },
      style: TextStyle(color: AppTheme.getText(context)),
      decoration: _inputDecoration(
        context,
        label: 'Password',
        hint: _isSignUp ? 'Create a strong password' : 'Enter your password',
        icon: Icons.lock_outline_rounded,
        suffix: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppTheme.getMuted(context),
            size: 20,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ).copyWith(counterText: ''),
      validator: (val) {
        if (val == null || val.isEmpty) return 'Please enter your password';
        // Existing accounts may have shorter legacy passwords, so only new
        // sign-ups are held to the stronger policy.
        if (_isSignUp) return AuthService.validatePasswordStrength(val);
        return null;
      },
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.emerald, AppTheme.emeraldDark],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.emerald.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: _isLoading ? null : _handleEmailPasswordAuth,
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Text(
                _isSignUp ? 'Create Account' : 'Log In',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildOrDivider(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppTheme.isDark(context) ? Colors.white12 : Colors.black12,
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'OR',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.getMuted(context),
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppTheme.isDark(context) ? Colors.white12 : Colors.black12,
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleSignInButton(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: isDark ? AppTheme.bgDark.withValues(alpha: 0.5) : Colors.white,
        side: BorderSide(
          color: isDark ? Colors.white24 : Colors.black12,
          width: 1.2,
        ),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: _isLoading ? null : _handleGoogleSignIn,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Google 'G' Icon
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: const Text(
              'G',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF4285F4),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Continue with Google (Gmail)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.getText(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    final isDark = AppTheme.isDark(context);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: AppTheme.getMuted(context).withValues(alpha: 0.6), fontSize: 13),
      labelStyle: TextStyle(color: AppTheme.getMuted(context), fontSize: 14),
      prefixIcon: Icon(icon, color: AppTheme.emerald, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: isDark ? AppTheme.bgDark.withValues(alpha: 0.5) : AppTheme.bgLightMedium.withValues(alpha: 0.6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.emerald, width: 1.8),
      ),
    );
  }
}

