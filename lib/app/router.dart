import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_screen.dart';
import '../features/auth/reset_password_screen.dart';
import '../features/cart/deal_cart_screen.dart';
import '../features/home/home_screen.dart';
import '../features/image_search/image_analyzing_screen.dart';
import '../features/image_search/image_capture_screen.dart';
import '../features/image_search/image_deal_screen.dart';
import '../features/image_search/image_request_screen.dart';
import '../features/image_search/image_result_screen.dart';
import '../features/product/product_detail_screen.dart';
import '../features/profile/notifications_screen.dart';
import '../features/profile/price_alerts_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/saved/saved_screen.dart';
import '../features/search/ai_search_screen.dart';
import '../features/search/filter_screen.dart';
import '../features/search/search_results_screen.dart';
import '../repositories/repository_providers.dart';
import 'app_shell.dart';

abstract final class AppRoutes {
  static const String home = '/';
  static const String search = '/search';
  static const String cart = '/cart';
  static const String saved = '/saved';
  static const String profile = '/profile';
  static const String results = '/results';
  static const String filter = '/filter';
  static const String alerts = '/alerts';
  static const String notifications = '/notifications';
  static const String imageSearch = '/image-search';
  static const String imageSearchLibrary = '/image-search?source=library';
  static const String imageRequest = '/image-search/request';
  static const String imageAnalyzing = '/image-search/analyzing';
  static const String imageResult = '/image-search/result';
  static const String imageDeal = '/image-search/deal';
  static const String login = '/login';
  static const String resetPassword = '/reset-password';

  static String product(String id) => '/product/$id';
}

CustomTransitionPage<T> _fadeSlidePage<T>(GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(begin: const Offset(0.05, 0), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

  final router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: AppRoutes.home,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.home, builder: (context, state) => const HomeScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.search,
                builder: (context, state) => AiSearchScreen(initialQuery: state.uri.queryParameters['q']),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.cart, builder: (context, state) => const DealCartScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.saved, builder: (context, state) => const SavedScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.profile, builder: (context, state) => const ProfileScreen())],
          ),
        ],
      ),
      GoRoute(
        path: '/product/:id',
        parentNavigatorKey: rootKey,
        pageBuilder: (context, state) => _fadeSlidePage(
          state,
          ProductDetailScreen(
            productId: state.pathParameters['id']!,
            heroTag: state.extra is String ? state.extra! as String : null,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.results,
        parentNavigatorKey: rootKey,
        pageBuilder: (context, state) => _fadeSlidePage(
          state,
          SearchResultsScreen(
            query: state.uri.queryParameters['q'] ?? '',
            categoryId: state.uri.queryParameters['category'],
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.filter,
        parentNavigatorKey: rootKey,
        pageBuilder: (context, state) => _fadeSlidePage(
          state,
          FilterScreen(args: state.extra is FilterScreenArgs ? state.extra! as FilterScreenArgs : null),
        ),
      ),
      GoRoute(
        path: AppRoutes.alerts,
        parentNavigatorKey: rootKey,
        pageBuilder: (context, state) => _fadeSlidePage(state, const PriceAlertsScreen()),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        parentNavigatorKey: rootKey,
        pageBuilder: (context, state) => _fadeSlidePage(state, const NotificationsScreen()),
      ),
      GoRoute(
        path: AppRoutes.imageSearch,
        parentNavigatorKey: rootKey,
        pageBuilder: (context, state) =>
            _fadeSlidePage(state, ImageCaptureScreen(openLibrary: state.uri.queryParameters['source'] == 'library')),
      ),
      GoRoute(
        path: AppRoutes.imageRequest,
        parentNavigatorKey: rootKey,
        pageBuilder: (context, state) => _fadeSlidePage(state, const ImageRequestScreen()),
      ),
      GoRoute(
        path: AppRoutes.imageAnalyzing,
        parentNavigatorKey: rootKey,
        pageBuilder: (context, state) => _fadeSlidePage(state, const ImageAnalyzingScreen()),
      ),
      GoRoute(
        path: AppRoutes.imageResult,
        parentNavigatorKey: rootKey,
        pageBuilder: (context, state) => _fadeSlidePage(state, const ImageResultScreen()),
      ),
      GoRoute(
        path: AppRoutes.imageDeal,
        parentNavigatorKey: rootKey,
        pageBuilder: (context, state) => _fadeSlidePage(state, const ImageDealScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        parentNavigatorKey: rootKey,
        pageBuilder: (context, state) => _fadeSlidePage(state, const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        parentNavigatorKey: rootKey,
        pageBuilder: (context, state) => _fadeSlidePage(state, const ResetPasswordScreen()),
      ),
    ],
  );

  final recovery = ref
      .read(authRepositoryProvider)
      .passwordRecoveryEvents()
      .listen((_) => router.push(AppRoutes.resetPassword));
  ref.onDispose(recovery.cancel);
  ref.onDispose(router.dispose);
  return router;
});
