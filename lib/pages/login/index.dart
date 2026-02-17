import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/layout/window_controls.dart';
import '../../widgets/app_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final PageController _pageController = PageController();
  int _currentSlide = 0;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  List<_SlideData> _slides(AppLocalizations l10n) => [
    _SlideData(
      icon: Icons.timer_outlined,
      title: l10n.loginSlideTitle1,
      description: l10n.loginSlideDesc1,
    ),
    _SlideData(
      icon: Icons.check_circle_outline,
      title: l10n.loginSlideTitle2,
      description: l10n.loginSlideDesc2,
    ),
    _SlideData(
      icon: Icons.insights_outlined,
      title: l10n.loginSlideTitle3,
      description: l10n.loginSlideDesc3,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startSlideTimer();
  }

  void _startSlideTimer() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _pageController.hasClients) {
        final nextPage = (_currentSlide + 1) % 3;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        _startSlideTimer();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  String _localizeError(AppLocalizations l10n, String errorCode) {
    switch (errorCode) {
      case 'empty_credentials':
        return l10n.authEmptyCredentials;
      case 'invalid_credentials':
        return l10n.authInvalidCredentials;
      case 'encryption_error':
        return l10n.authEncryptionError;
      case 'network_error':
        return l10n.authNetworkError;
      case 'server_error':
        return l10n.authServerError;
      case 'session_expired':
        return l10n.authSessionExpired;
      case 'email_not_verified':
        return l10n.authEmailNotVerified;
      case 'too_many_requests':
        return l10n.authTooManyRequests;
      default:
        return errorCode;
    }
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // Route guard will handle navigation on success
      await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    }
  }

  void _handleRegister() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.openRegisterPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          Row(
            children: [
              // Left side - Product Introduction Slides
              Expanded(
                flex: 1,
                child: _buildProductSlides(),
              ),
              // Right side - Login Form
              Expanded(
                flex: 1,
                child: _buildLoginForm(),
              ),
            ],
          ),
          // Window controls overlay at top-left
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onPanStart: (_) => appWindow.startDragging(),
              behavior: HitTestBehavior.translucent,
              child: Container(
                height: 32,
                padding: const EdgeInsets.only(left: AppTheme.spacingSm),
                child: const Row(
                  children: [
                    WindowControls(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSlides() {
    final l10n = AppLocalizations.of(context)!;
    final slides = _slides(l10n);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.shade700,
            AppTheme.primaryColor.shade500,
          ],
        ),
      ),
      child: Column(
        children: [
          // App Logo and Name
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacingXl),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: const Icon(
                    Icons.hourglass_empty,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  l10n.appTitle,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),

          // Slides
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentSlide = index;
                });
              },
              itemCount: slides.length,
              itemBuilder: (context, index) {
                final slide = slides[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingXl,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingLg),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          slide.icon,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingLg),
                      Text(
                        slide.title,
                        style:
                            Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      Text(
                        slide.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Slide Indicators
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingXl),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                slides.length,
                (index) => Container(
                  width: _currentSlide == index ? 20 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: _currentSlide == index
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: colors.background,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingXl),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.loginWelcomeBack,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    l10n.loginSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                  ),

                  const SizedBox(height: AppTheme.spacingXl),

                  // Email field
                  AppTextField(
                    label: l10n.loginEmail,
                    hint: l10n.loginEmailPlaceholder,
                    controller: _emailController,
                    prefixIcon: const Icon(Icons.email_outlined, size: AppTheme.iconSizeMd),
                    keyboardType: TextInputType.emailAddress,
                    onFieldSubmitted: () => FocusScope.of(context).nextFocus(),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.loginEmailRequired;
                      }
                      if (!_emailRegex.hasMatch(value.trim())) {
                        return l10n.loginEmailInvalid;
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppTheme.spacingMd),

                  // Password field
                  AppTextField(
                    label: l10n.loginPassword,
                    hint: l10n.loginPasswordPlaceholder,
                    controller: _passwordController,
                    prefixIcon: const Icon(Icons.lock_outline, size: AppTheme.iconSizeMd),
                    keyboardType: TextInputType.text,
                    obscureText: true,
                    onFieldSubmitted: _handleLogin,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.loginPasswordRequired;
                      }
                      if (value.length < 8) {
                        return l10n.loginPasswordTooShort;
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppTheme.spacingMd),

                  // Error message
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      if (authProvider.errorMessage != null) {
                        return Container(
                          padding: const EdgeInsets.all(AppTheme.spacingSm),
                          margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withValues(alpha: 0.1),
                            border: Border.all(
                              color: AppTheme.errorColor.withValues(alpha: 0.3),
                            ),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: AppTheme.errorColor,
                                size: AppTheme.iconSizeSm,
                              ),
                              const SizedBox(width: AppTheme.spacingSm),
                              Expanded(
                                child: Text(
                                  _localizeError(l10n, authProvider.errorMessage!),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.errorColor,
                                      ),
                                ),
                              ),
                              InkWell(
                                onTap: authProvider.clearError,
                                child: Icon(
                                  Icons.close,
                                  size: AppTheme.iconSizeSm,
                                  color: AppTheme.errorColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Login button
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return SizedBox(
                        height: AppTheme.buttonHeight,
                        child: ElevatedButton(
                          onPressed: authProvider.isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentColor,
                            foregroundColor: Colors.black87,
                          ),
                          child: authProvider.isLoading
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(l10n.loginSignIn),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: AppTheme.spacingLg),

                  // Register link
                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                        children: [
                          TextSpan(text: l10n.loginRegister),
                          const TextSpan(text: ' '),
                          TextSpan(
                            text: l10n.loginRegisterLink,
                            style: TextStyle(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = _handleRegister,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Data class for slide content
class _SlideData {
  final IconData icon;
  final String title;
  final String description;

  const _SlideData({
    required this.icon,
    required this.title,
    required this.description,
  });
}
