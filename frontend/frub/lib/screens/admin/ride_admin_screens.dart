import 'package:flutter/material.dart';
import '../../models/ride_models.dart';
import '../../services/ride_service.dart';
import '../admin/events_admin_screen.dart';  // If in a different directory

/// Screen for administrators to manage ride-sharing functionality
/// Includes tabs for queue management, driver status, and ride supervision
class RideAdminScreen extends StatefulWidget {
  const RideAdminScreen({super.key});

  @override
  State<RideAdminScreen> createState() => _RideAdminScreenState();
}

class _RideAdminScreenState extends State<RideAdminScreen> with SingleTickerProviderStateMixin {
  // Service for ride management functionality
  final _rideService = RideService();
  // Tab controller for managing the three main tabs
  late TabController _tabController;
  
  // State variables to hold data
  List<Driver> _drivers = [];
  List<RideQueue> _queues = [];
  List<RideRequest> _activeRides = [];
  List<RideRequest> _pendingUserRides = []; // Tracks pending rides not yet in official queue

  
  @override
  void initState() {
    super.initState();
    // Initialize tab controller with 3 tabs: QUEUE, DRIVERS, RIDES
  _tabController = TabController(length: 4, vsync: this); // Change from 3 to 4    
    // Load dummy data if queue is empty (for testing/demo purposes)
    if (_rideService.queues.isEmpty) {
      _rideService.initWithDummyData();
    }
    
    // Initial data load
    _loadData();
    
    // Setup listeners for real-time data updates
    // When driver data changes, update UI
    _rideService.driversStream.listen((drivers) {
      setState(() {
        _drivers = drivers;
      });
    });
    
    // When queue data changes, update UI
    _rideService.queuesStream.listen((queues) {
      setState(() {
        _queues = queues;
      });
    });
    
    // When ride data changes, update UI (filter out completed/canceled rides)
    _rideService.ridesStream.listen((rides) {
      setState(() {
        _activeRides = rides.where((r) => 
          r.status != RideStatus.completed && 
          r.status != RideStatus.canceled
        ).toList();
      });
    });
  }
  
  @override
  void dispose() {
    // Clean up resources when widget is removed
    _tabController.dispose();
    super.dispose();
  }
  
  // Load all required data from the ride service
  void _loadData() {
    setState(() {
      _drivers = _rideService.drivers;
      _queues = _rideService.queues;
      _activeRides = _rideService.allRides.where((r) => 
        r.status != RideStatus.completed && 
        r.status != RideStatus.canceled
      ).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride And Event Administration'),
        backgroundColor: const Color(0xFF4B0082), // Deep purple color
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70, // Semi-transparent white for unselected tabs
          tabs: const [
            Tab(text: 'QUEUE'),
            Tab(text: 'DRIVERS'),
            Tab(text: 'RIDES'),
            Tab(text: 'EVENTS'), // Add this new tab

          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQueueTab(),
          _buildDriversTab(),
          _buildRidesTab(),
          const EventsAdminScreen(),
        ],
      ),
     floatingActionButton: FloatingActionButton(
      backgroundColor: const Color(0xFF4B0082),
      onPressed: () {
        // Different action for each tab
        switch (_tabController.index) {
          case 0: // Queue tab
            _showAddQueueDialog();
            break;
          case 1: // Drivers tab
            _showAddDriverDialog();
            break;
          case 2: // Rides tab
            _showCreateRideDialog();
            break;
          case 3: // Events tab
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EventsAdminScreen()),
            );
            break;
        }
      },
      child: const Icon(Icons.add, color: Colors.white),
    ),
    );
  }
  
  // Builds the Queue tab content showing all ride queues
  Widget _buildQueueTab() {
    if (_queues.isEmpty) {
      return const Center(
        child: Text('No queues available. Create one to get started.'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _queues.length,
      itemBuilder: (context, index) {
        final queue = _queues[index];
        
        // Create a combined list including pending user rides
        // This ensures that rides that haven't been officially added to the
        // queue yet still appear in the admin view
        final combinedRequests = List<RideRequest>.from(queue.requests);

        // Find rides that aren't in the queue but should be displayed
        // Includes pending or assigned rides, but excludes rides in progress
        final pendingUserRides = _rideService.allRides.where((ride) => 
          !queue.requests.any((queueRide) => queueRide.id == ride.id) &&
          (ride.status == RideStatus.pending || ride.status == RideStatus.assigned) &&
          ride.status != RideStatus.inProgress
        ).toList();

        // Add pending rides to the display at the end of the queue
        if (pendingUserRides.isNotEmpty) {
          for (var pendingRide in pendingUserRides) {
            // Create a display version with position at the end of the queue
            final displayRide = RideRequest(
              id: pendingRide.id,
              userId: pendingRide.userId,
              userName: pendingRide.userName,
              pickup: pendingRide.pickup,
              destination: pendingRide.destination,
              requestTime: pendingRide.requestTime,
              status: RideStatus.inQueue, // Show as if in queue
              // Calculate wait time based on last person in queue + 5 minutes
              estimatedWaitMinutes: queue.requests.isEmpty ? 5 : 
                 queue.requests.last.estimatedWaitMinutes + 5,
              position: queue.requests.length + 1,
            );
            combinedRequests.add(displayRide);
          }
        }
        
        // Build card for each queue showing queue stats and riders
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Queue header with name and ride count
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      queue.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Badge showing total number of rides (including pending)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4B0082),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${combinedRequests.length} Rides', // Shows combined count including pending
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              // Show queue stats and rides if there are any
              if (combinedRequests.isNotEmpty) ...[
                const Divider(height: 0),
                _buildQueueStats(queue), // Summary statistics
                const Divider(height: 0),
                // List of all rides in queue
                for (int i = 0; i < combinedRequests.length; i++)
                  _buildQueueItemAdmin(combinedRequests[i], i),
              ] else ...[
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No rides in queue'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
  
  // Builds the queue statistics section with wait times, rider count, and driver availability
  Widget _buildQueueStats(RideQueue queue) {
    // Get pending/assigned rides to include in stats calculation
    final pendingUserRides = _rideService.allRides.where((ride) => 
      !queue.requests.any((queueRide) => queueRide.id == ride.id) &&
      (ride.status == RideStatus.pending || ride.status == RideStatus.assigned) &&
      ride.status != RideStatus.inProgress
    ).toList();
    
    // Calculate total including pending rides for accurate stats
    final totalWaiting = queue.length + pendingUserRides.length;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Average wait time statistic
          _buildStatItem(
            label: 'Average Wait', 
            value: '${queue.averageWaitTime.toStringAsFixed(1)} min',
            icon: Icons.access_time,
          ),
          // Total waiting riders statistic (including pending)
          _buildStatItem(
            label: 'Total Waiting', 
            value: '$totalWaiting riders', // Updated to include pending rides
            icon: Icons.people,
          ),
          // Available drivers statistic
          _buildStatItem(
            label: 'Drivers Available', 
            value: '${_rideService.availableDrivers.length}',
            icon: Icons.drive_eta,
          ),
        ],
      ),
    );
  }
  
  // Helper to build individual statistic items with icon, value, and label
  Widget _buildStatItem({required String label, required String value, required IconData icon}) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF4B0082)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  // Builds an individual queue item in the admin view
  Widget _buildQueueItemAdmin(RideRequest request, int index) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      // Position indicator (1, 2, 3, etc.)
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF4B0082),
        child: Text('${index + 1}'),
      ),
      title: Text(request.userName),
      subtitle: Text('To: ${request.destination.name}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Wait time display
          Text(
            '${request.estimatedWaitMinutes} min',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          // Actions menu (assign driver, remove from queue)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'assign') {
                _showAssignDriverDialog(request);
              } else if (value == 'remove') {
                _showRemoveRideDialog(request);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'assign',
                child: Text('Assign Driver'),
              ),
              const PopupMenuItem(
                value: 'remove',
                child: Text('Remove from Queue'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Builds the Drivers tab content showing all available drivers
  Widget _buildDriversTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _drivers.length,
      itemBuilder: (context, index) {
        final driver = _drivers[index];
        // Card for each driver showing their details
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Driver header with name, vehicle and status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driver.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${driver.vehicleModel} (${driver.licensePlate})',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status badge (Available, Busy, Offline)
                    _buildDriverStatusBadge(driver.status),
                  ],
                ),
                const SizedBox(height: 16),
                // Driver statistics - capacity, assigned rides, available seats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDriverStat(
                      label: 'Capacity',
                      value: '${driver.capacity}',
                    ),
                    _buildDriverStat(
                      label: 'Assigned',
                      value: '${driver.assignedRides.length}',
                    ),
                    _buildDriverStat(
                      label: 'Available',
                      value: '${driver.availableSeats}',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Driver actions - status toggle and view rides button
                Row(
                  children: [
                    // Driver status dropdown to change availability
                    const Text('Status: '),
                    const SizedBox(width: 8),
                    DropdownButton<DriverStatus>(
                      value: driver.status,
                      onChanged: (newStatus) {
                        if (newStatus != null) {
                          _rideService.updateDriverStatus(driver.id, newStatus);
                        }
                      },
                      items: DriverStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(_getDriverStatusText(status)),
                        );
                      }).toList(),
                    ),
                    const Spacer(),
                    // View rides button - only if driver has assigned rides
                    if (driver.assignedRides.isNotEmpty)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.visibility),
                        label: const Text('View Rides'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4B0082),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _showDriverRidesDialog(driver),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Creates a color-coded status badge for drivers
  Widget _buildDriverStatusBadge(DriverStatus status) {
    // Set color based on driver status
    late Color color;
    switch (status) {
      case DriverStatus.available:
        color = Colors.green;
        break;
      case DriverStatus.busy:
        color = Colors.orange;
        break;
      case DriverStatus.offline:
        color = Colors.grey;
        break;
    }
    
    // Create a rounded badge with appropriate status text
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getDriverStatusText(status),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  // Helper to build driver statistics with value and label
  Widget _buildDriverStat({required String label, required String value}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  // Builds the Rides tab content showing all active rides grouped by status
  Widget _buildRidesTab() {
    if (_activeRides.isEmpty) {
      return const Center(
        child: Text('No active rides at the moment.'),
      );
    }
    
    // Group rides by their status for organized display
    final pendingRides = _activeRides.where((r) => 
      r.status == RideStatus.pending || r.status == RideStatus.inQueue
    ).toList();
    
    final assignedRides = _activeRides.where((r) => 
      r.status == RideStatus.assigned
    ).toList();
    
    final inProgressRides = _activeRides.where((r) => 
      r.status == RideStatus.inProgress
    ).toList();
    
    // List view with sections for each ride status
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Section for pending and queued rides
        if (pendingRides.isNotEmpty) ...[
          const Text(
            'Pending & Queued',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white
            ),
          ),
          const SizedBox(height: 8),
          for (final ride in pendingRides)
            _buildRideCard(ride),
          const SizedBox(height: 16),
        ],
        
        // Section for rides with assigned drivers
        if (assignedRides.isNotEmpty) ...[
          const Text(
            'Driver Assigned',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white
            ),
          ),
          const SizedBox(height: 8),
          for (final ride in assignedRides)
            _buildRideCard(ride),
          const SizedBox(height: 16),
        ],
        
        // Section for rides currently in progress
        if (inProgressRides.isNotEmpty) ...[
          const Text(
            'In Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white
            ),
          ),
          const SizedBox(height: 8),
          for (final ride in inProgressRides)
            _buildRideCard(ride),
        ],
      ],
    );
  }
  
  // Builds an individual ride card with details and appropriate actions
  Widget _buildRideCard(RideRequest ride) {
    // Color-coding based on ride status
    late Color statusColor;
    switch (ride.status) {
      case RideStatus.pending:
        statusColor = Colors.orange;
        break;
      case RideStatus.inQueue:
        statusColor = Colors.blue;
        break;
      case RideStatus.assigned:
        statusColor = Colors.purple;
        break;
      case RideStatus.inProgress:
        statusColor = Colors.green;
        break;
      case RideStatus.completed:
        statusColor = Colors.teal;
        break;
      case RideStatus.canceled:
        statusColor = Colors.red;
        break;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ride header with user name and status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ride.userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Color-coded status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getRideStatusText(ride.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Ride details - pickup, destination, distance, estimated time
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRideDetailRow(Icons.location_on, 'From', ride.pickup.name),
                      const SizedBox(height: 8),
                      _buildRideDetailRow(Icons.location_searching, 'To', ride.destination.name),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${ride.distance.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Est: ${ride.estimatedDurationMinutes} min',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Action buttons that vary based on ride status
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Show "Assign Driver" button for pending/queued rides
                if (ride.status == RideStatus.inQueue || ride.status == RideStatus.pending)
                  TextButton.icon(
                    icon: const Icon(Icons.person_add),
                    label: const Text('Assign Driver'),
                    onPressed: () => _showAssignDriverDialog(ride),
                  ),
                // Show "Start Ride" button for assigned rides
                if (ride.status == RideStatus.assigned)
                  TextButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Ride'),
                    onPressed: () => _rideService.startRide(ride),
                  ),
                // Show "Complete" button for in-progress rides
                if (ride.status == RideStatus.inProgress)
                  TextButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Complete'),
                    onPressed: () => _rideService.completeRide(ride),
                  ),
                const SizedBox(width: 8),
                // Cancel button available for all ride statuses
                TextButton.icon(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  label: const Text('Cancel', style: TextStyle(color: Colors.red)),
                  onPressed: () => _showRemoveRideDialog(ride),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper to build ride detail rows with icon, label, and value
  Widget _buildRideDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  // Dialog to create a new queue
  void _showAddQueueDialog() {
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Queue'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Queue Name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;
              
              // In a real app, this would create a new queue in the backend
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('New queue would be created here')),
              );
            },
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
  }
  
  // Dialog to add a new driver
  void _showAddDriverDialog() {
    // Controllers for the text fields
    final nameController = TextEditingController();
    final vehicleController = TextEditingController();
    final plateController = TextEditingController();
    int capacity = 4; // Default capacity
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        // Using StatefulBuilder to allow state changes in the dialog
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Driver'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Driver name input
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Driver Name',
                  ),
                  autofocus: true,
                ),
                // Vehicle model input
                TextField(
                  controller: vehicleController,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Model',
                  ),
                ),
                // License plate input
                TextField(
                  controller: plateController,
                  decoration: const InputDecoration(
                    labelText: 'License Plate',
                  ),
                ),
                const SizedBox(height: 16),
                // Capacity selector with +/- buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Capacity:'),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            if (capacity > 1) {
                              setState(() {
                                capacity--;
                              });
                            }
                          },
                        ),
                        Text('$capacity', style: const TextStyle(fontSize: 18)),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              capacity++;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                // Validate inputs before saving
                if (nameController.text.isEmpty ||
                    vehicleController.text.isEmpty ||
                    plateController.text.isEmpty) return;
                
                // In a real app, this would add a driver to the backend
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('New driver would be added here')),
                );
              },
              child: const Text('ADD'),
            ),
          ],
        ),
      ),
    );
  }
  
  // Placeholder for creating a new ride
  void _showCreateRideDialog() {
    // This would show a dialog to manually create a ride
    // For simplicity, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Manual ride creation would be implemented here')),
    );
  }
  
  // Dialog to assign a driver to a ride
  void _showAssignDriverDialog(RideRequest ride) {
    final availableDrivers = _rideService.availableDrivers;
    
    // Check if there are any available drivers
    if (availableDrivers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available drivers')),
      );
      return;
    }
    
    // Show dialog with list of available drivers
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Driver'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableDrivers.length,
            itemBuilder: (context, index) {
              final driver = availableDrivers[index];
              return ListTile(
                title: Text(driver.name),
                subtitle: Text('${driver.vehicleModel} - ${driver.availableSeats} seats available'),
                onTap: () {
                  Navigator.pop(context);
                  // In a real app, this would call an API to assign the driver
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${ride.userName} assigned to ${driver.name}')),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
        ],
      ),
    );
  }
  
  // Dialog to confirm removing a ride from the queue
  void _showRemoveRideDialog(RideRequest ride) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Ride'),
        content: Text('Are you sure you want to remove ${ride.userName}\'s ride?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('NO'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Cancel the ride and update the UI
              _rideService.cancelRide(ride);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${ride.userName}\'s ride removed')),
              );
            },
            child: const Text('YES'),
          ),
        ],
      ),
    );
  }
  
// Dialog to show all rides assigned to a specific driver
  void _showDriverRidesDialog(Driver driver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${driver.name}\'s Rides'),
        content: SizedBox(
          width: double.maxFinite,
          // Show list of assigned rides or "No assigned rides" message
          child: driver.assignedRides.isEmpty
              ? const Text('No assigned rides')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: driver.assignedRides.length,
                  itemBuilder: (context, index) {
                    final ride = driver.assignedRides[index];
                    return ListTile(
                      title: Text(ride.userName),
                      subtitle: Text('To: ${ride.destination.name}'),
                      trailing: Text(_getRideStatusText(ride.status)),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }
  
  // Helper method to convert driver status enum to human-readable text
  String _getDriverStatusText(DriverStatus status) {
    switch (status) {
      case DriverStatus.available:
        return 'Available';
      case DriverStatus.busy:
        return 'Busy';
      case DriverStatus.offline:
        return 'Offline';
      default:
        return 'Unknown';
    }
  }
  
  // Helper method to convert ride status enum to human-readable text
  String _getRideStatusText(RideStatus status) {
    switch (status) {
      case RideStatus.pending:
        return 'Pending';
      case RideStatus.inQueue:
        return 'In Queue';
      case RideStatus.assigned:
        return 'Assigned';
      case RideStatus.inProgress:
        return 'In Progress';
      case RideStatus.completed:
        return 'Completed';
      case RideStatus.canceled:
        return 'Canceled';
      default:
        return 'Unknown';
    }
  }
}
