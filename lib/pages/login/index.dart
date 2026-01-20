import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/layout/window_controls.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final PageController _pageController = PageController();
  int _currentSlide = 0;

  // Product introduction slides data
  final List<_SlideData> _slides = const [
    _SlideData(
      icon: Icons.timer_outlined,
      title: 'Focus Timer',
      description: 'Stay productive with Pomodoro technique and customizable focus sessions.',
    ),
    _SlideData(
      icon: Icons.check_circle_outline,
      title: 'Task Management',
      description: 'Organize your tasks efficiently with intuitive drag-and-drop interface.',
    ),
    _SlideData(
      icon: Icons.insights_outlined,
      title: 'Analytics',
      description: 'Track your productivity patterns and improve over time.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Auto-advance slides
    _startSlideTimer();
  }

  void _startSlideTimer() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _pageController.hasClients) {
        final nextPage = (_currentSlide + 1) % _slides.length;
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
    _usernameController.dispose();
    _passwordController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      if (success && mounted) {
        context.go('/app/list');
      }
    }
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
                  'Focus Hut',
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
              itemCount: _slides.length,
              itemBuilder: (context, index) {
                final slide = _slides[index];
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
                _slides.length,
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
    return Container(
      color: AppTheme.backgroundColor,
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
                    'Welcome Back',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    'Sign in to continue to Focus Hut',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),

                  const SizedBox(height: AppTheme.spacingXl),

                  // Username field
                  Text(
                    'Username',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your username',
                      prefixIcon: Icon(Icons.person_outline, size: AppTheme.iconSizeMd),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入用户名';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppTheme.spacingMd),

                  // Password field
                  Text(
                    'Password',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your password',
                      prefixIcon: Icon(Icons.lock_outline, size: AppTheme.iconSizeMd),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleLogin(),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入密码';
                      }
                      if (value.length < 4) {
                        return '密码至少4位';
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
                                  authProvider.errorMessage!,
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
                              : const Text('Sign In'),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: AppTheme.spacingLg),

                  // Demo credentials hint
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingSm),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: AppTheme.iconSizeSm,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        Expanded(
                          child: Text(
                            'Demo: admin / admin123',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.primaryColor,
                                ),
                          ),
                        ),
                      ],
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
