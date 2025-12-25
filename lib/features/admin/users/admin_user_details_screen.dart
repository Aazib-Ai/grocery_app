import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import 'providers/admin_user_provider.dart';
import '../../../data/models/user_model.dart';

/// Admin screen for viewing user details and managing status.
class AdminUserDetailsScreen extends StatefulWidget {
  final String userId;

  const AdminUserDetailsScreen({super.key, required this.userId});

  @override
  State<AdminUserDetailsScreen> createState() => _AdminUserDetailsScreenState();
}

class _AdminUserDetailsScreenState extends State<AdminUserDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminUserProvider>().fetchUserById(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<AdminUserProvider>();
    final user = userProvider.selectedUser;

    if (userProvider.isLoading && user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('User Details')),
        body: const Center(child: Text('User not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(user),
            const SizedBox(height: 24),

            // Account Information
            _buildInfoSection(
              title: 'Account Information',
              items: [
                _buildInfoTile(Icons.email, 'Email Address', user.email),
                _buildInfoTile(Icons.phone, 'Phone Number', user.phone ?? 'Not provided'),
                _buildInfoTile(Icons.calendar_today, 'Joined On', DateFormat('MMM dd, yyyy').format(user.createdAt)),
                _buildInfoTile(Icons.update, 'Last Updated', DateFormat('MMM dd, yyyy').format(user.updatedAt)),
              ],
            ),
            const SizedBox(height: 24),

            // Management Actions
            _buildManagementSection(context, userProvider, user),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
              backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
              child: user.avatarUrl == null
                  ? const Icon(Icons.person, size: 50, color: AppColors.primaryGreen)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildBadge(
                  user.role.name.toUpperCase(),
                  user.role.name.contains('admin') ? Colors.purple : Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildBadge(
                  user.isActive ? 'ACTIVE' : 'DISABLED',
                  user.isActive ? Colors.green : Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildInfoSection({required String title, required List<Widget> items}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          ...items,
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryGreen),
      title: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
    );
  }

  Widget _buildManagementSection(BuildContext context, AdminUserProvider provider, UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Management Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: provider.isLoading
              ? null
              : () => _toggleStatus(context, provider, user),
          icon: Icon(user.isActive ? Icons.block : Icons.check_circle),
          label: Text(user.isActive ? 'Disable Account' : 'Enable Account'),
          style: ElevatedButton.styleFrom(
            backgroundColor: user.isActive ? Colors.red : Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        if (user.role.name.contains('admin')) ...[
          const SizedBox(height: 12),
          const Text(
            'Note: Disabling an admin account may restrict system access.',
            style: TextStyle(color: Colors.red, fontSize: 12, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Future<void> _toggleStatus(BuildContext context, AdminUserProvider provider, UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${user.isActive ? 'Disable' : 'Enable'} User?'),
        content: Text('Are you sure you want to ${user.isActive ? 'disable' : 'enable'} access for ${user.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: user.isActive ? Colors.red : Colors.green),
            child: Text(user.isActive ? 'Disable' : 'Enable'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await provider.toggleUserStatus(user.id, !user.isActive);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'User status updated' : 'Failed to update status'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}
