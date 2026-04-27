import 'package:go_router/go_router.dart';

import '../../features/client/auth/login_screen.dart';
import '../../features/client/cart/cart_screen.dart';
import '../../features/client/catalog/catalog_screen.dart';
import '../../features/client/checkout/checkout_screen.dart';
import '../../features/client/checkout/order_success_screen.dart';
import '../../features/client/home/home_screen.dart';
import '../../features/client/onboarding/onboarding_screen.dart';
import '../../features/client/product/product_screen.dart';
import '../../features/client/profile/profile_screen.dart';
import '../../features/client/shell.dart';
import '../../features/client/subscription/subscription_screen.dart';

GoRouter buildClientRouter({bool seenOnboarding = false}) {
  return GoRouter(
    initialLocation: seenOnboarding ? '/' : '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
        routes: [
          GoRoute(
            path: 'otp',
            builder: (_, state) => OtpScreen(
              phone: state.uri.queryParameters['phone'] ?? '',
            ),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => ClientShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/catalog', builder: (_, __) => const CatalogScreen()),
          GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
      GoRoute(
        path: '/product/:slug',
        builder: (_, state) => ProductScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: '/checkout',
        builder: (_, __) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/order-success',
        builder: (_, state) => OrderSuccessScreen(
          code: state.uri.queryParameters['code'] ?? 'AZF-0001',
        ),
      ),
      GoRoute(
        path: '/subscription',
        builder: (_, __) => const SubscriptionScreen(),
      ),
    ],
  );
}
