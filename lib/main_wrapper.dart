import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class MainWrapper extends StatefulWidget {
  final Widget child;
  const MainWrapper({super.key, required this.child});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/favorites');
        break;
      case 2:
        context.go('/history');
        break;
      case 3:
        context.go('/'); // Profile is at root '/' currently, or should be '/profile'
        // Let's make Profile the default root '/' effectively acts as Home? 
        // No, usually Home is '/' and Profile is '/profile'. 
        // Initial setup had '/' as Profile. I should change '/' to Home and '/profile' to Profile.
        context.go('/profile'); 
        break;
    }
  }

  // Calculate index based on location to keep sync on back button
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/favorites')) return 1;
    if (location.startsWith('/history')) return 2;
    if (location.startsWith('/profile') || location == '/') return 3; // Initial was profile
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) {
           switch (index) {
            case 0: context.go('/home'); break;
            case 1: context.go('/favorites'); break;
            case 2: context.go('/history'); break;
            case 3: context.go('/profile'); break;
           }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.background,
        elevation: 0,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
           BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
