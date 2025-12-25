import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../riders/providers/rider_provider.dart';
import '../../../domain/entities/rider.dart';

/// Admin rider details screen.
class AdminRiderDetailsScreen extends StatefulWidget {
  final String riderId;

  const AdminRiderDetailsScreen({super.key, required this.riderId});

  @override
  State<AdminRiderDetailsScreen> createState() => _AdminRiderDetailsScreenState();
}

class _AdminRiderDetailsScreenState extends State<AdminRiderDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RiderProvider>().getRiderById(widget.riderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RiderProvider>();
    final rider = provider.selectedRider;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rider Details'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          if (rider != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.go('/admin/riders/${rider.id}/edit'),
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : rider == null
              ? const Center(child: Text('Rider not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      _buildHeader(rider),
                      const SizedBox(height: 24),
                      
                      // Info Sections
                      _buildSectionTitle('Performance'),
                      _buildPerformanceStats(rider),
                      const SizedBox(height: 24),
                      
                      _buildSectionTitle('Vehicle Information'),
                      _buildInfoTile(Icons.directions_bike, 'Type', rider.vehicleType ?? 'Not specified'),
                      _buildInfoTile(Icons.pin, 'Registration Number', rider.vehicleNumber ?? 'Not specified'),
                      const SizedBox(height: 24),
                      
                      _buildSectionTitle('Contact Information'),
                      _buildInfoTile(Icons.phone, 'Phone', rider.phone),
                      _buildInfoTile(Icons.email, 'Email', rider.email ?? 'Not specified'),
                      const SizedBox(height: 24),
                      
                      _buildSectionTitle('Account Details'),
                      _buildInfoTile(Icons.calendar_today, 'Joined On', _formatDate(rider.createdAt)),
                      _buildInfoTile(Icons.account_circle, 'Account Status', rider.isActive ? 'Active' : 'Disabled'),
                      
                      const SizedBox(height: 40),
                      
                      // Bottom Actions
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => context.go('/admin/riders/${rider.id}/edit'),
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit Profile'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _toggleStatus(context, rider),
                              icon: Icon(rider.isActive ? Icons.block : Icons.check_circle),
                              label: Text(rider.isActive ? 'Deactivate' : 'Activate'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: rider.isActive ? Colors.red : Colors.green,
                                side: BorderSide(color: rider.isActive ? Colors.red : Colors.green),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader(Rider rider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[200],
              backgroundImage: rider.avatarUrl != null && rider.avatarUrl!.isNotEmpty
                  ? NetworkImage(rider.avatarUrl!)
                  : null,
              child: rider.avatarUrl == null || rider.avatarUrl!.isEmpty
                  ? const Icon(Icons.person, size: 50, color: Colors.grey)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              rider.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildStatusChip(rider.status),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(RiderStatus status) {
    Color color;
    switch (status) {
      case RiderStatus.available: color = Colors.green; break;
      case RiderStatus.onDelivery: color = Colors.blue; break;
      case RiderStatus.offline: color = Colors.grey; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildPerformanceStats(Rider rider) {
    return Row(
      children: [
        _buildStatCard('Deliveries', '${rider.totalDeliveries}', Icons.local_shipping, Colors.blue),
        const SizedBox(width: 16),
        _buildStatCard('Rating', '4.8', Icons.star, Colors.orange), // Static for now
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryGreen, size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _toggleStatus(BuildContext context, Rider rider) async {
    final provider = context.read<RiderProvider>();
    final success = await provider.updateRider(rider.id, isActive: !rider.isActive);
    
    if (mounted && success != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rider ${!rider.isActive ? 'activated' : 'deactivated'} successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
