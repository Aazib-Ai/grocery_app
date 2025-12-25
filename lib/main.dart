import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'domain/entities/address.dart';
import 'core/config/supabase_config.dart';
import 'core/auth/auth_provider.dart';
import 'core/auth/supabase_auth_service.dart';
import 'features/products/providers/product_provider.dart';
import 'features/categories/providers/category_provider.dart';
import 'features/favorites/providers/favorites_provider.dart';
import 'features/cart/providers/cart_provider.dart';
import 'features/orders/providers/order_provider.dart';
import 'features/tracking/providers/tracking_provider.dart';
import 'data/repositories/product_repository_impl.dart';
import 'data/repositories/category_repository_impl.dart';
import 'data/repositories/favorites_repository_impl.dart';
import 'data/repositories/cart_repository_impl.dart';
import 'data/repositories/order_repository_impl.dart';
import 'data/repositories/tracking_repository_impl.dart';
import 'data/repositories/rider_repository_impl.dart';
import 'features/riders/providers/rider_provider.dart';
import 'features/search/services/search_service.dart';
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
import 'features/profile/addresses_screen.dart';
import 'features/profile/address_form_screen.dart';
import 'features/orders/orders_screen.dart';

import 'main_wrapper.dart';
import 'features/admin/admin_wrapper.dart';
import 'features/admin/admin_dashboard_screen.dart';
import 'features/admin/products/admin_products_screen.dart';
import 'features/admin/products/admin_product_form_screen.dart';
import 'features/admin/categories/admin_categories_screen.dart';
import 'features/admin/categories/admin_category_form_screen.dart';
import 'features/admin/riders/admin_riders_screen.dart';
import 'features/admin/riders/admin_rider_form_screen.dart';
import 'features/admin/riders/admin_rider_details_screen.dart';
import 'features/admin/orders/admin_orders_screen.dart';
import 'features/admin/orders/admin_order_details_screen.dart';
import 'features/admin/users/admin_users_screen.dart';
import 'features/admin/users/admin_user_details_screen.dart';
import 'features/admin/users/providers/admin_user_provider.dart';
import 'features/admin/deliveries/admin_deliveries_screen.dart';
import 'features/admin/analytics/providers/analytics_provider.dart';
import 'data/repositories/analytics_repository_impl.dart';
import 'data/repositories/profile_repository_impl.dart';
import 'core/auth/user_role.dart';
import 'core/realtime/realtime_service.dart';
import 'core/storage/image_storage_service.dart';
import 'features/profile/providers/profile_provider.dart';
import 'features/splash/splash_screen.dart';

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
    // Create RealtimeService instance
    final realtimeService = RealtimeService(SupabaseConfig.client);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            SupabaseAuthService(SupabaseConfig.client),
            const FlutterSecureStorage(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductProvider(
            ProductRepositoryImpl(SupabaseConfig.client),
            SearchService(
              ProductRepositoryImpl(SupabaseConfig.client),
              SupabaseConfig.client,
            ),
            realtimeService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(
            CategoryRepositoryImpl(SupabaseConfig.client),
          ),
        ),
        ChangeNotifierProxyProvider<AuthProvider, FavoritesProvider>(
          create: (context) => FavoritesProvider(
            FavoritesRepositoryImpl(SupabaseConfig.client),
            context.read<AuthProvider>(),
          ),
          update: (context, auth, previous) => previous ?? FavoritesProvider(
            FavoritesRepositoryImpl(SupabaseConfig.client),
            auth,
          ),
        ),
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (context) => CartProvider(
            CartRepositoryImpl(SupabaseConfig.client),
            context.read<AuthProvider>(),
          ),
          update: (context, auth, previous) => previous ?? CartProvider(
            CartRepositoryImpl(SupabaseConfig.client),
            auth,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => OrderProvider(
            repository: OrderRepositoryImpl(SupabaseConfig.client),
            realtimeService: realtimeService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => TrackingProvider(
            repository: TrackingRepositoryImpl(SupabaseConfig.client),
            realtimeService: realtimeService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => RiderProvider(
            RiderRepositoryImpl(SupabaseConfig.client),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminUserProvider(
            ProfileRepositoryImpl(SupabaseConfig.client),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AnalyticsProvider(
            AnalyticsRepositoryImpl(SupabaseConfig.client),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileProvider(
            SupabaseConfig.client,
            MockImageStorageService(),
          ),
        ),
      ],
      child: MaterialApp.router(
        title: 'Grocery App',
        theme: AppTheme.lightTheme,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final _adminNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash', // Start at Splash
  redirect: (context, state) {
    // No redirect for non-admin routes
    if (!state.uri.toString().startsWith('/admin')) {
      return null;
    }

    
    // Check if user is authenticated and is admin
    final authProvider = context.read<AuthProvider>();
    
    // Protect customer routes
    final isAuthRoute = state.uri.toString().startsWith('/auth');
    final isPublicRoute = state.uri.toString().startsWith('/onboarding') || 
                          isAuthRoute ||
                          state.uri.toString().startsWith('/help') ||
                          state.uri.toString().startsWith('/faq') ||
                          state.uri.toString().startsWith('/privacy');

    if (!authProvider.isAuthenticated && !isPublicRoute) {
      return '/auth';
    }

    if (authProvider.isAuthenticated && isAuthRoute) {
       return '/home';
    }

    if (!state.uri.toString().startsWith('/admin')) {
      return null;
    }

    final userRole = authProvider.currentUserRole;
    if (userRole == null || !userRole.isAdmin) {
      // Not an admin, redirect to home
      return '/home';
    }

    // User is admin, allow access
    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SplashScreen(),
    ),
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
    // Admin Routes
    ShellRoute(
      navigatorKey: _adminNavigatorKey,
      builder: (context, state, child) {
        return AdminWrapper(child: child);
      },
      routes: [
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: '/admin/products',
          builder: (context, state) => const AdminProductsScreen(),
        ),
        GoRoute(
          path: '/admin/products/new',
          builder: (context, state) => const AdminProductFormScreen(),
        ),
        GoRoute(
          path: '/admin/products/:id',
          builder: (context, state) {
            final productId = state.pathParameters['id']!;
            return AdminProductFormScreen(productId: productId);
          },
        ),
        GoRoute(
          path: '/admin/categories',
          builder: (context, state) => const AdminCategoriesScreen(),
        ),
        GoRoute(
          path: '/admin/categories/new',
          builder: (context, state) => const AdminCategoryFormScreen(),
        ),
        GoRoute(
          path: '/admin/categories/:id',
          builder: (context, state) {
            final categoryId = state.pathParameters['id']!;
            return AdminCategoryFormScreen(categoryId: categoryId);
          },
        ),
        GoRoute(
          path: '/admin/riders',
          builder: (context, state) => const AdminRidersScreen(),
        ),
        GoRoute(
          path: '/admin/riders/new',
          builder: (context, state) => const AdminRiderFormScreen(),
        ),
        GoRoute(
          path: '/admin/riders/:id',
          builder: (context, state) {
            final riderId = state.pathParameters['id']!;
            return AdminRiderDetailsScreen(riderId: riderId);
          },
        ),
        GoRoute(
          path: '/admin/riders/:id/edit',
          builder: (context, state) {
            final riderId = state.pathParameters['id']!;
            return AdminRiderFormScreen(riderId: riderId);
          },
        ),
        GoRoute(
          path: '/admin/orders',
          builder: (context, state) => const AdminOrdersScreen(),
        ),
        GoRoute(
          path: '/admin/orders/:id',
          builder: (context, state) {
            final orderId = state.pathParameters['id']!;
            return AdminOrderDetailsScreen(orderId: orderId);
          },
        ),
        GoRoute(
          path: '/admin/users',
          builder: (context, state) => const AdminUsersScreen(),
        ),
        GoRoute(
          path: '/admin/users/:id',
          builder: (context, state) {
            final userId = state.pathParameters['id']!;
            return AdminUserDetailsScreen(userId: userId);
          },
        ),
        GoRoute(
          path: '/admin/deliveries',
          builder: (context, state) => const AdminDeliveriesScreen(),
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
      path: '/tracking/:orderId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final orderId = state.pathParameters['orderId']!;
        return OrderTrackingScreen(orderId: orderId);
      },
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
         return ProductDetailsScreen(productId: id);
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
    GoRoute(
      path: '/addresses',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AddressesScreen(),
    ),
    GoRoute(
      path: '/address_form',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final address = state.extra as Address?;
        return AddressFormScreen(address: address);
      },
    ),
  ],
);
