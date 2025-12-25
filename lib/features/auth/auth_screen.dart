import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_text_field.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           CustomTextField(label: "Email address", initialValue: "aliirtiza@gmail.com"),
           const SizedBox(height: 24),
           CustomTextField(label: "Password", isPassword: true, initialValue: "password"),
           const SizedBox(height: 16),
           TextButton(
             onPressed: () => context.push('/forgot_password'),
             child: const Text("Forgot passcode?", style: TextStyle(color: AppColors.primaryGreen)),
           ),
           constSpacer(),
           PrimaryButton(
             text: "Login",
             onPressed: () => context.go('/home'),
           ),
           const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSignupForm(BuildContext context) {
     return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           CustomTextField(label: "Full Name", initialValue: "Ali Raza"),
           const SizedBox(height: 16),
           CustomTextField(label: "Email address", initialValue: "aliirtiza@gmail.com"),
           const SizedBox(height: 16),
           CustomTextField(label: "Password", isPassword: true, initialValue: "password"),
           const SizedBox(height: 32),
           PrimaryButton(
             text: "Sign-up",
             onPressed: () => context.go('/home'),
           ),
            const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  Widget constSpacer() => const SizedBox(height: 24);
}
