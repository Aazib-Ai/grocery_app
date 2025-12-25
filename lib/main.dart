import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/auth/auth_screen.dart';
import 'features/checkout/delivery_details_screen.dart';
import 'features/checkout/payment_method_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/tracking/order_tracking_screen.dart';
import 'features/cart/cart_screen.dart';
import 'features/favorites/favorites_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/support/help_support_screen.dart';
import 'features/support/faq_screen.dart';
import 'features/support/privacy_policy_screen.dart';
import 'features/home/home_screen.dart';
import 'features/history/history_screen.dart';
import 'features/search/search_screen.dart';
import 'features/products/product_listing_screen.dart';
import 'features/products/product_details_screen.dart';
import 'features/profile/edit_profile_screen.dart';
import 'features/orders/orders_screen.dart';
import 'data/repositories/mock_repository.dart';
import 'main_wrapper.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Supabase before running the app
    await SupabaseConfig.initialize();
    
    // Run the app
    runApp(const GroceryApp());
  } catch (e) {
    // Handle initialization errors
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Initialization Error',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    e.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Please check your .env file and ensure:\n'
                    '1. SUPABASE_URL is set correctly\n'
                    '2. SUPABASE_ANON_KEY is set correctly\n'
                    '3. Both values are not placeholders',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
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

class GroceryApp extends StatelessWidget {
  const GroceryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Grocery App',
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/onboarding', // Start at Onboarding
  routes: [
     GoRoute(
      path: '/onboarding',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/auth',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AuthScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainWrapper(child: child);
      },
      routes: [
         GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/favorites',
          builder: (context, state) => const FavoritesScreen(),
        ),
         GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
    // Routes WITHOUT Bottom Nav
    GoRoute(
      path: '/delivery',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const DeliveryDetailsScreen(),
    ),
    GoRoute(
      path: '/payment',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PaymentMethodScreen(),
    ),
    GoRoute(
      path: '/tracking',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const OrderTrackingScreen(),
    ),
    GoRoute(
      path: '/cart',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CartScreen(),
    ),
    GoRoute(
      path: '/forgot_password',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/help',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const HelpSupportScreen(),
    ),
    GoRoute(
      path: '/faq',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const FAQScreen(),
    ),
     GoRoute(
      path: '/search',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: '/products',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ProductListingScreen(),
    ),
    GoRoute(
      path: '/product/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
         final id = state.pathParameters['id']!;
         // Mock finding product
         final product = MockRepository.getProducts().firstWhere((p) => p.id == id, orElse: () => MockRepository.getProducts()[0]);
         return ProductDetailsScreen(product: product);
      },
    ),
    GoRoute(
      path: '/privacy',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
    GoRoute(
      path: '/edit_profile',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/orders',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const OrdersScreen(),
    ),
  ],
);
