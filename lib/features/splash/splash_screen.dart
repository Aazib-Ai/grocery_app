import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Give it a minimum duration so the logo doesn't just flicker
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _checkAuth();
      }
    });
  }

  void _checkAuth() {
    final authProvider = context.read<AuthProvider>();
    
    // If provider is still loading, listen to it
    if (authProvider.isLoading) {
      authProvider.addListener(_onAuthChange);
    } else {
      _navigate(authProvider);
    }
  }

  void _onAuthChange() {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isLoading) {
      authProvider.removeListener(_onAuthChange);
      _navigate(authProvider);
    }
  }

  void _navigate(AuthProvider authProvider) {
    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      if (authProvider.currentUserRole?.isAdmin == true) {
        context.go('/admin');
      } else {
        context.go('/home');
      }
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Using a simple text logo for now, replace with actual logo asset if known
            const Icon(
              Icons.shopping_basket_rounded,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            Text(
              'Grocery App',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
