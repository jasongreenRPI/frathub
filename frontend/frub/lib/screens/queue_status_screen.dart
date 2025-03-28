import 'dart:async';
import 'package:flutter/material.dart';
import '../models/ride_models.dart';
import '../services/ride_service.dart';

class QueueStatusScreen extends StatefulWidget {
  final String rideId;
  
  const QueueStatusScreen({
    super.key,
    required this.rideId,
  });

  @override
  State<QueueStatusScreen> createState() => _QueueStatusScreenState();
}

class _QueueStatusScreenState extends State<QueueStatusScreen> {
  final _rideService = RideService();
  RideRequest? _ride;
  RideQueue? _queue;
  List<RideRequest> _allQueueRides = [];
  Timer? _refreshTimer;
  bool _isRefreshing = false;
  
  @override
  void initState() {
    super.initState();
    _loadRideData();
    
    // Set up a timer to refresh data automatically
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadRideData();
    });
    
    // Listen for updates on all rides
    _rideService.ridesStream.listen((rides) {
      _loadRideData();
    });
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
  
  void _loadRideData() {
    if (_isRefreshing) return;
  
    setState(() {
      _isRefreshing = true;
    });
    
    // Get the ride by ID
    final allRides = _rideService.allRides;
    final ride = allRides.firstWhere(
      (r) => r.id == widget.rideId,
      orElse: () => RideRequest(
        id: '',
        userId: '',
        userName: '',
        pickup: Location(name: ''),
        destination: Location(name: ''),
        requestTime: DateTime.now(),
      ),
    );
    
    // Check if ride was found (has a valid ID)
    if (ride.id.isEmpty) {
      setState(() {
        _ride = null;
        _queue = null;
        _allQueueRides = [];
        _isRefreshing = false;
      });
      
      // Show error and navigate back after a delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ride not found or has been cancelled')),
          );
          Navigator.pop(context);
        }
      });
      return;
    }
    
    // Check if ride was canceled or completed
    if (ride.status == RideStatus.canceled || ride.status == RideStatus.completed) {
      setState(() {
        _ride = ride;
        _queue = null;
        _allQueueRides = [];
        _isRefreshing = false;
      });
      
      // Show message and navigate back after a delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ride was ${ride.status == RideStatus.canceled ? 'cancelled' : 'completed'}')),
          );
          Navigator.pop(context);
        }
      });
      return;
    }
    
    // Important change - we now have only one queue, so get it directly
    final mainQueue = _rideService.queues.isNotEmpty ? _rideService.queues.first : null;
    
   // Get ALL rides in the main queue 
  List<RideRequest> queueRides = [];
  if (mainQueue != null) {
    // Use the queue's requests directly
    queueRides = List.from(mainQueue.requests);
    
    // Sort queue rides by position
    queueRides.sort((a, b) => 
      (a.position ?? 999).compareTo(b.position ?? 999)
    );
    
    // Check if user's ride is already in the queue list
    bool userRideInQueue = queueRides.any((r) => r.id == widget.rideId);
    
    // If user's ride is not in the queue list yet, add it at the end
    if (!userRideInQueue && ride.status == RideStatus.pending) {
      // Create a copy of the ride with the position set to the end
      final userRide = ride;
      userRide.position = queueRides.length + 1;
      queueRides.add(userRide);
    }
    
    // Update state
  setState(() {
    _ride = ride;
    _queue = mainQueue;
    _allQueueRides = queueRides;
    _isRefreshing = false;
  });
    
   // Debug print
  print('Queue name: ${mainQueue?.name ?? 'None'}');
  print('Queue length: ${queueRides.length}');
  for (var ride in queueRides) {
    print('Queue item: ${ride.userName} - ${ride.destination.name} - position: ${ride.position}');
  }
  }
  }
  
  void _cancelRide() {
    if (_ride == null) return;
    
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
              _rideService.cancelRide(_ride!);
              Navigator.pop(context); // Go back to previous screen
            },
            child: const Text('YES'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4B0082),
      appBar: AppBar(
        title: Text(_queue?.name ?? 'Queue Status'),
        backgroundColor: const Color(0xFF4B0082),
      ),
      body: _ride == null
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _buildQueueDetails(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF4B0082),
        onPressed: _loadRideData,
        child: const Icon(Icons.refresh),
      ),
    );
  }
  
  Widget _buildQueueDetails() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Queue list - taking up most of the screen space
          Expanded(
            child: _buildQueueList(),
          ),
          
          const SizedBox(height: 16),
          
          // Wait time indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Estimated Wait: ${_ride?.estimatedWaitMinutes ?? 0} minutes',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Leave button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF240041),
                foregroundColor: Colors.white,
              ),
              onPressed: _cancelRide,
              child: const Text(
                'Leave Queue',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQueueList() {
  List<RideRequest> displayQueue = List.from(_allQueueRides);
  
  // If the user's ride is not in the displayed queue, add it
  bool userRideInQueue = displayQueue.any((r) => r.id == widget.rideId);
  if (!userRideInQueue && _ride != null) {
    // Create a copy of the user's ride to add to the display
    final userRide = _ride!;
    
    // Set position to the end of the queue
    userRide.position = displayQueue.length + 1;
    
    // Calculate wait time based on the last person in queue
    if (displayQueue.isNotEmpty) {
      final lastPersonWaitTime = displayQueue.last.estimatedWaitMinutes;
      userRide.estimatedWaitMinutes = lastPersonWaitTime + 5; // Add 5 minutes to last person's wait
    }
    
    // Add to the display queue
    displayQueue.add(userRide);
  }
  
  if (displayQueue.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 64, color: Colors.white.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'No rides in queue',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  // Show all rides including user's ride
  return ListView.builder(
    itemCount: displayQueue.length,
    itemBuilder: (context, index) {
      final request = displayQueue[index];
      final isCurrentRide = request.id == widget.rideId;
      
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          // Use a darker color for the current user's ride
          color: isCurrentRide ? const Color(0xFF240041) : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            backgroundColor: isCurrentRide ? Colors.white : const Color(0xFF4B0082),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: isCurrentRide ? const Color(0xFF4B0082) : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            isCurrentRide ? 'Your Ride' : request.userName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isCurrentRide ? Colors.white : Colors.black,
            ),
          ),
          subtitle: Text(
            'To: ${request.destination.name}',
            style: TextStyle(
              color: isCurrentRide ? Colors.white70 : Colors.grey[600],
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${request.estimatedWaitMinutes} min',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCurrentRide ? Colors.white : Colors.black,
                ),
              ),
              if (isCurrentRide) ...[
                const SizedBox(width: 8),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
}