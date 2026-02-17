import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import './pages/login/index.dart';
import './pages/app/app_shell.dart';
import './pages/list/index.dart';
import './pages/schedule/index.dart';
import './pages/profile/index.dart';
import './pages/setting/index.dart';
import './pages/statistics/index.dart';
import './pages/focus/index.dart';
import './providers/auth_provider.dart';

GoRouter router({required AuthProvider authProvider}) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isLoggedIn = authProvider.isAuthenticated;
      final isInitialized = authProvider.isInitialized;
      final isLoginRoute = state.matchedLocation == '/login';

      // While auth is initializing, don't redirect (avoid flash)
      if (!isInitialized) return null;

      // Not authenticated → force to login page
      if (!isLoggedIn && !isLoginRoute) return '/login';

      // Already authenticated → redirect away from login
      if (isLoggedIn && isLoginRoute) return '/app/list';

      return null;
    },
    routes: [
      // Login page - no shell
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),

      // Main app routes with shell (sidebar layout)
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          // Default app route redirects to list
          GoRoute(
            path: '/app',
            redirect: (context, state) => '/app/list',
          ),

          // List page - main task list
          GoRoute(
            path: '/app/list',
            pageBuilder: (context, state) => _buildPageWithoutAnimation(
              state,
              const ListPage(),
            ),
          ),

          // Schedule page - calendar view
          GoRoute(
            path: '/app/schedule',
            pageBuilder: (context, state) => _buildPageWithoutAnimation(
              state,
              const SchedulePage(),
            ),
          ),

          // Profile page - user profile
          GoRoute(
            path: '/app/profile',
            pageBuilder: (context, state) => _buildPageWithoutAnimation(
              state,
              const ProfilePage(),
            ),
          ),

          // Settings page
          GoRoute(
            path: '/app/settings',
            pageBuilder: (context, state) => _buildPageWithoutAnimation(
              state,
              const SettingPage(),
            ),
          ),

          // Statistics page
          GoRoute(
            path: '/app/statistics',
            pageBuilder: (context, state) => _buildPageWithoutAnimation(
              state,
              const StatisticsPage(),
            ),
          ),

          // Focus page - Pomodoro timer
          GoRoute(
            path: '/app/focus/:taskId',
            pageBuilder: (context, state) {
              final taskId = state.pathParameters['taskId']!;
              return _buildPageWithoutAnimation(
                state,
                FocusPage(taskId: taskId),
              );
            },
          ),
        ],
      ),
    ],
  );
}

/// Build page without transition animation for smoother navigation
CustomTransitionPage<void> _buildPageWithoutAnimation(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 150),
  );
}
