import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../riders/providers/rider_provider.dart';
import '../../../domain/entities/rider.dart';

/// Admin riders list screen.
/// 
/// Displays all riders with status, performance metrics, and management actions.
class AdminRidersScreen extends StatefulWidget {
  const AdminRidersScreen({super.key});

  @override
  State<AdminRidersScreen> createState() => _AdminRidersScreenState();
}

class _AdminRidersScreenState extends State<AdminRidersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RiderProvider>().loadRiders();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final riderProvider = context.watch<RiderProvider>();
    var riders = riderProvider.riders;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      riders = riders.where((rider) {
        return rider.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            rider.phone.contains(_searchQuery) ||
            (rider.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Riders'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/admin/riders/new'),
            tooltip: 'Add Rider',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search riders by name, phone, or email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Riders list
          Expanded(
            child: riderProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : riderProvider.errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(riderProvider.errorMessage!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => riderProvider.loadRiders(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : riders.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.directions_bike,
                                    size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'No riders yet'
                                      : 'No riders found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (_searchQuery.isEmpty)
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        context.go('/admin/riders/new'),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add First Rider'),
                                  ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => riderProvider.refresh(),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: riders.length,
                              itemBuilder: (context, index) {
                                final rider = riders[index];
                                return _buildRiderCard(context, rider);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderCard(BuildContext context, Rider rider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go('/admin/riders/${rider.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 30,
                backgroundImage: rider.avatarUrl != null && rider.avatarUrl!.isNotEmpty
                    ? NetworkImage(rider.avatarUrl!)
                    : null,
                child: rider.avatarUrl == null || rider.avatarUrl!.isEmpty
                    ? const Icon(Icons.person, size: 30)
                    : null,
              ),
              const SizedBox(width: 16),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rider.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rider.phone,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildStatusChip(rider.status),
                        const SizedBox(width: 8),
                        if (!rider.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Inactive',
                              style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Stats & Actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${rider.totalDeliveries}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const Text(
                    'Deliveries',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleAction(context, value, rider),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, size: 20),
                            SizedBox(width: 8),
                            Text('View Details'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: rider.isActive ? 'deactivate' : 'activate',
                        child: Row(
                          children: [
                            Icon(rider.isActive ? Icons.block : Icons.check_circle, size: 20),
                            SizedBox(width: 8),
                            Text(rider.isActive ? 'Deactivate' : 'Activate'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(RiderStatus status) {
    Color color;
    String label;
    
    switch (status) {
      case RiderStatus.available:
        color = Colors.green;
        label = 'Available';
        break;
      case RiderStatus.onDelivery:
        color = Colors.blue;
        label = 'On Delivery';
        break;
      case RiderStatus.offline:
        color = Colors.grey;
        label = 'Offline';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _handleAction(BuildContext context, String action, Rider rider) {
    switch (action) {
      case 'view':
        context.go('/admin/riders/${rider.id}');
        break;
      case 'edit':
        context.go('/admin/riders/${rider.id}/edit');
        break;
      case 'deactivate':
        _toggleRiderStatus(context, rider, false);
        break;
      case 'activate':
        _toggleRiderStatus(context, rider, true);
        break;
    }
  }

  Future<void> _toggleRiderStatus(BuildContext context, Rider rider, bool activate) async {
    final provider = context.read<RiderProvider>();
    final success = await provider.updateRider(rider.id, isActive: activate);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success != null 
            ? 'Rider ${activate ? 'activated' : 'deactivated'} successfully' 
            : 'Operation failed'),
          backgroundColor: success != null ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
