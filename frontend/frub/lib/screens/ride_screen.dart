import 'package:flutter/material.dart';
import '../models/ride_models.dart';
import '../services/ride_service.dart';
import '../services/user_service.dart';
import 'queue_status_screen.dart';

class RideScreen extends StatefulWidget {
  const RideScreen({super.key});

  @override
  State<RideScreen> createState() => _RideScreenState();
}

class _RideScreenState extends State<RideScreen> {
  final _rideService = RideService();
  final _userService = UserService();
  final _pickupController = TextEditingController(text: 'LXA House');
  final _destinationController = TextEditingController();
  
  List<Location> _locations = [];
  Location? _selectedPickup;
  Location? _selectedDestination;
  bool _isLoadingLocations = true;
  bool _isRequestingRide = false;
  
  // Check if user has an active ride
  RideRequest? _activeRide;
  
  @override
  void initState() {
    super.initState();
    _loadLocations();
    _checkForActiveRide();
    
    // Initialize ride service if needed
    if (_rideService.queues.isEmpty) {
      _rideService.initWithDummyData();
    }
    
    // Listen for ride updates
    _rideService.ridesStream.listen((rides) {
      _checkForActiveRide();
    });
  }
  
  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    super.dispose();
  }
  
  // Load available locations
  void _loadLocations() {
    setState(() {
      _isLoadingLocations = true;
    });
    
    // In a real app, this would be an API call
    // For now, we'll use the dummy locations from rides in the service
    Future.delayed(const Duration(milliseconds: 500), () {
      final rides = _rideService.allRides;
      final locationSet = <String>{};
      final locations = <Location>[];
      
      // Collect unique locations
      for (final ride in rides) {
        if (!locationSet.contains(ride.pickup.name)) {
          locationSet.add(ride.pickup.name);
          locations.add(ride.pickup);
        }
        if (!locationSet.contains(ride.destination.name)) {
          locationSet.add(ride.destination.name);
          locations.add(ride.destination);
        }
      }
      
      // Default LXA House if not in the list
      if (!locationSet.contains('LXA House')) {
        locations.add(Location(name: 'LXA House', latitude: 42.7284, longitude: -73.6918));
      }
      
      // Add McDonald's if not in the list
      if (!locationSet.contains("McDonald's")) {
        locations.add(Location(name: "McDonald's", latitude: 42.7330, longitude: -73.6890));
      }
      
      // Set as available locations
      setState(() {
        _locations = locations;
        _selectedPickup = locations.firstWhere((loc) => loc.name == 'LXA House', 
            orElse: () => locations.first);
        _isLoadingLocations = false;
      });
    });
  }
  
  // Check if the current user has an active ride
  void _checkForActiveRide() {
    if (_userService.currentUser == null) return;
    
    final currentUserId = _userService.currentUser!.email;
    final userRide = _rideService.getUserCurrentRide(currentUserId);
    
    setState(() {
      _activeRide = userRide?.id.isEmpty == true ? null : userRide;
    });
  }
  
  // Request a ride
  void _requestRide() {
    if (_selectedPickup == null || _destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select pickup and destination locations'))
      );
      return;
    }
    
    if (_selectedPickup!.name == _destinationController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pickup and destination cannot be the same'))
      );
      return;
    }
    
    setState(() {
      _isRequestingRide = true;
    });
    
    // In a real app, this would be an API call
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      
      // Create destination location
      final destination = Location(name: _destinationController.text);
      
      // Create the ride request
      final currentUser = _userService.currentUser!;
      final ride = _rideService.createRideRequest(
        userId: currentUser.email,
        userName: currentUser.name.isEmpty ? 'New User' : currentUser.name,
        pickup: _selectedPickup!,
        destination: destination,
      );
      
      setState(() {
        _activeRide = ride;
        _isRequestingRide = false;
      });
      
      // Show confirmation and navigate to queue status
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride request added to queue!'))
      );
      
      // Navigate to queue status
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => QueueStatusScreen(rideId: ride.id)),
      );
    });
  }
  
  // Cancel the active ride
  void _cancelRide() {
    if (_activeRide == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Ride?'),
        content: const Text('Are you sure you want to cancel your ride request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('NO'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _rideService.cancelRide(_activeRide!);
              setState(() {
                _activeRide = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ride canceled'))
              );
            },
            child: const Text('YES'),
          ),
        ],
      ),
    );
  }
  
  // View the active ride status
  void _viewRideStatus() {
    if (_activeRide == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QueueStatusScreen(rideId: _activeRide!.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4B0082),
      appBar: AppBar(
        title: const Text('Get A Ride'),
        backgroundColor: const Color(0xFF4B0082),
      ),
      body: _activeRide != null
          ? _buildActiveRideView()
          : _buildRequestRideView(),
    );
  }
  
  Widget _buildRequestRideView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Where are you going?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          
          // Pickup location
          const Text(
            'Pickup Location',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          _buildLocationDropdown(
            hint: 'Select pickup location',
            value: _selectedPickup,
            onChanged: (location) {
              setState(() {
                _selectedPickup = location;
                if (location != null) {
                  _pickupController.text = location.name;
                }
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Destination
          const Text(
            'Destination',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _destinationController,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Enter destination',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    // Show dropdown of predefined locations
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => Container(
                        color: Colors.white,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _locations.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(_locations[index].name),
                              onTap: () {
                                setState(() {
                                  _destinationController.text = _locations[index].name;
                                });
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Request ride button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _isRequestingRide ? null : _requestRide,
              child: _isRequestingRide
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : const Text(
                      'Join Queue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          
          // Map placeholder
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map,
                    size: 50,
                    color: Colors.white70,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Map View',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActiveRideView() {
    final statusText = _getRideStatusText();
    final isPending = _activeRide!.status == RideStatus.pending || 
                      _activeRide!.status == RideStatus.inQueue;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active ride card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Active Ride',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4B0082),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildRideDetail(Icons.location_on, 'From', _activeRide!.pickup.name),
                const SizedBox(height: 8),
                _buildRideDetail(Icons.location_searching, 'To', _activeRide!.destination.name),
                const SizedBox(height: 8),
                _buildRideDetail(
                  Icons.access_time, 
                  'Requested', 
                  _formatDateTime(_activeRide!.requestTime)
                ),
                
                // Show wait time if in queue
                if (isPending) ...[
                  const SizedBox(height: 8),
                  _buildRideDetail(
                    Icons.hourglass_empty, 
                    'Estimated Wait', 
                    '${_activeRide!.estimatedWaitMinutes} minutes'
                  ),
                  if (_activeRide!.position != null) ...[
                    const SizedBox(height: 8),
                    _buildRideDetail(
                      Icons.people, 
                      'Queue Position', 
                      '${_activeRide!.position}'
                    ),
                  ],
                ],
                
                // Show driver details if assigned
                if (_activeRide!.driverId != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildDriverDetails(),
                ],
                
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _cancelRide,
                        child: const Text('Cancel Ride'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4B0082),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _viewRideStatus,
                        child: const Text('View Status'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Map placeholder
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map,
                      size: 50,
                      color: Colors.white70,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Ride Map View',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLocationDropdown({
    required String hint,
    required Location? value,
    required Function(Location?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Location>(
          isExpanded: true,
          hint: Text(hint),
          value: value,
          onChanged: _isLoadingLocations ? null : onChanged,
          items: _isLoadingLocations
              ? [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Loading locations...'),
                  )
                ]
              : _locations.map((location) {
                  return DropdownMenuItem(
                    value: location,
                    child: Text(location.name),
                  );
                }).toList(),
        ),
      ),
    );
  }
  
  Widget _buildRideDetail(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
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
  
  Widget _buildDriverDetails() {
    // Find driver from the ride service
    final driverId = _activeRide!.driverId;
    if (driverId == null) return const SizedBox.shrink();
    
    final drivers = _rideService.drivers;
    final driver = drivers.firstWhere(
      (d) => d.id == driverId,
      orElse: () => Driver(
        id: '', 
        name: 'Unknown Driver', 
        vehicleModel: 'Unknown Vehicle', 
        licensePlate: 'Unknown',
        capacity: 0,
      ),
    );
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Driver',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driver.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${driver.vehicleModel} - ${driver.licensePlate}',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.phone, color: Color(0xFF4B0082)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Calling driver...')),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
  
  String _getRideStatusText() {
    switch (_activeRide!.status) {
      case RideStatus.pending:
        return 'Pending';
      case RideStatus.inQueue:
        return 'In Queue';
      case RideStatus.assigned:
        return 'Driver Assigned';
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
  
  Color _getStatusColor() {
    switch (_activeRide!.status) {
      case RideStatus.pending:
        return Colors.orange;
      case RideStatus.inQueue:
        return Colors.blue;
      case RideStatus.assigned:
        return Colors.purple;
      case RideStatus.inProgress:
        return Colors.green;
      case RideStatus.completed:
        return Colors.teal;
      case RideStatus.canceled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.month}/${dateTime.day} at $hour:$minute $period';
  }
}