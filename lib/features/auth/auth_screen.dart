import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_text_field.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Login form controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  
  // Signup form controllers
  final _signupNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with Logo
            Container(
              height: 300,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage('assets/images/logo_1.png'),
                  ),
                  const SizedBox(height: 16),
                  const Text("Ali Mart", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Color(0xFF1B5E20))),
                ],
              ),
            ),
             const SizedBox(height: 24),
            // Tab Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primaryGreen,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                tabs: const [
                  Tab(text: "Login"),
                  Tab(text: "Sign-up"),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Error message display
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                if (authProvider.errorMessage != null) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authProvider.errorMessage!,
                              style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 16),
            
            // Tab Views
            SizedBox(
              height: 400, // Fixed height for form area
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLoginForm(context),
                  _buildSignupForm(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               CustomTextField(
                label: "Email address",
                controller: _loginEmailController,
                keyboardType: TextInputType.emailAddress,
              ),
               const SizedBox(height: 24),
               CustomTextField(
                label: "Password",
                isPassword: true,
                controller: _loginPasswordController,
              ),
               const SizedBox(height: 16),
               TextButton(
                 onPressed: () => context.push('/forgot_password'),
                 child: const Text("Forgot passcode?", style: TextStyle(color: AppColors.primaryGreen)),
               ),
               constSpacer(),
               PrimaryButton(
                 text: authProvider.isLoading ? "Logging in..." : "Login",
                 onPressed: authProvider.isLoading ? null : () => _handleLogin(context, authProvider),
               ),
               const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSignupForm(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               CustomTextField(
                label: "Full Name",
                controller: _signupNameController,
              ),
               const SizedBox(height: 16),
               CustomTextField(
                label: "Email address",
                controller: _signupEmailController,
                keyboardType: TextInputType.emailAddress,
              ),
               const SizedBox(height: 16),
               CustomTextField(
                label: "Password",
                isPassword: true,
                controller: _signupPasswordController,
              ),
               const SizedBox(height: 32),
               PrimaryButton(
                 text: authProvider.isLoading ? "Signing up..." : "Sign-up",
                 onPressed: authProvider.isLoading ? null : () => _handleSignup(context, authProvider),
               ),
                const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
  
  Future<void> _handleLogin(BuildContext context, AuthProvider authProvider) async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text;

    // Basic validation
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    // Attempt sign in
    final success = await authProvider.signIn(
      email: email,
      password: password,
    );

    if (success && context.mounted) {
      context.go('/home');
    }
  }

  Future<void> _handleSignup(BuildContext context, AuthProvider authProvider) async {
    final name = _signupNameController.text.trim();
    final email = _signupEmailController.text.trim();
    final password = _signupPasswordController.text;

    // Basic validation
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    // Attempt sign up
    final success = await authProvider.signUp(
      email: email,
      password: password,
      name: name,
    );

    if (success && context.mounted) {
      context.go('/home');
    }
  }
  
  Widget constSpacer() => const SizedBox(height: 24);
}
