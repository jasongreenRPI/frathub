import 'dart:async';
import '../models/ride_models.dart';
import '../services/user_service.dart';

class RideService {
  // Singleton pattern
  static final RideService _instance = RideService._internal();
  factory RideService() => _instance;
  RideService._internal();

  // State
  final List<Driver> _drivers = [];
  final List<RideQueue> _queues = [];
  final List<RideRequest> _allRides = [];
  
  // Stream controllers for real-time updates
  final _driversStreamController = StreamController<List<Driver>>.broadcast();
  final _queuesStreamController = StreamController<List<RideQueue>>.broadcast();
  final _ridesStreamController = StreamController<List<RideRequest>>.broadcast();
  
  // Getters for streams
  Stream<List<Driver>> get driversStream => _driversStreamController.stream;
  Stream<List<RideQueue>> get queuesStream => _queuesStreamController.stream;
  Stream<List<RideRequest>> get ridesStream => _ridesStreamController.stream;
  
  // Getters for data
  List<Driver> get drivers => List.unmodifiable(_drivers);
  List<RideQueue> get queues => List.unmodifiable(_queues);
  List<RideRequest> get allRides => List.unmodifiable(_allRides);
  
  // Get available drivers
  List<Driver> get availableDrivers => _drivers.where((d) => d.isAvailable).toList();

// Initialize with dummy data
void initWithDummyData() {
  // Only initialize if not already initialized
  if (_queues.isNotEmpty || _drivers.isNotEmpty) {
    return;
  }
  
  // Clear existing data
  _drivers.clear();
  _queues.clear();
  _allRides.clear();
  
  // Add dummy locations
  final locations = [
    Location(name: 'LXA House', latitude: 42.7284, longitude: -73.6918),
    Location(name: 'Troy Campus', latitude: 42.7300, longitude: -73.6820),
    Location(name: 'Downtown', latitude: 42.7270, longitude: -73.6940),
    Location(name: 'Shopping Mall', latitude: 42.7400, longitude: -73.7000),
    Location(name: 'Airport', latitude: 42.7500, longitude: -73.8000),
    Location(name: "McDonald's", latitude: 42.7330, longitude: -73.6890),
    Location(name: 'Train Station', latitude: 42.7280, longitude: -73.7100),
    Location(name: 'Coffee Shop', latitude: 42.7290, longitude: -73.6930),
    Location(name: 'University Library', latitude: 42.7310, longitude: -73.6840),
    Location(name: 'Gym', latitude: 42.7320, longitude: -73.6920),
    Location(name: 'Movie Theater', latitude: 42.7350, longitude: -73.6970),
  ];
  
  // Add dummy drivers
  _drivers.addAll([
    Driver(
      id: 'd1',
      name: 'John Driver',
      vehicleModel: 'Toyota Camry',
      licensePlate: 'ABC123',
      capacity: 4,
      status: DriverStatus.available,
      currentLocation: locations[0],
    ),
    Driver(
      id: 'd2',
      name: 'Sarah Smith',
      vehicleModel: 'Honda Civic',
      licensePlate: 'XYZ789',
      capacity: 4,
      status: DriverStatus.available,
      currentLocation: locations[1],
    ),
    Driver(
      id: 'd3',
      name: 'Michael Brown',
      vehicleModel: 'Ford Explorer',
      licensePlate: 'DEF456',
      capacity: 6,
      status: DriverStatus.offline,
      currentLocation: locations[2],
    ),
    Driver(
      id: 'd4',
      name: 'Lisa Johnson',
      vehicleModel: 'Chevrolet Malibu',
      licensePlate: 'GHI789',
      capacity: 4,
      status: DriverStatus.busy,
      currentLocation: locations[3],
    ),
  ]);
  
  // Create main queue
  final mainQueue = RideQueue(id: 'q1', name: 'Main Queue');
  
  // Create ride requests for other users (not the current user)
  final now = DateTime.now();
  
  // Get the current user email to avoid adding them to the queue automatically
  final userService = UserService();
  final currentUserEmail = userService.currentUser?.email ?? '';
  
  // Add dummy entries to the main queue (all rides will now go here)
  final mainQueueRides = [
    RideRequest(
      id: 'r1',
      userId: 'other_user1',
      userName: 'Alex Rider',
      pickup: locations[0], // LXA House
      destination: locations[3], // Shopping Mall
      requestTime: now.subtract(const Duration(minutes: 45)),
      status: RideStatus.inQueue,
      estimatedWaitMinutes: 10,
      position: 1,
    ),
    RideRequest(
      id: 'r2',
      userId: 'other_user2',
      userName: 'Emma Wilson',
      pickup: locations[0], // LXA House
      destination: locations[4], // Airport
      requestTime: now.subtract(const Duration(minutes: 40)),
      status: RideStatus.inQueue,
      estimatedWaitMinutes: 15,
      position: 2,
    ),
    RideRequest(
      id: 'r3',
      userId: 'other_user3',
      userName: 'David Miller',
      pickup: locations[0], // LXA House
      destination: locations[6], // Train Station
      requestTime: now.subtract(const Duration(minutes: 35)),
      status: RideStatus.inQueue,
      estimatedWaitMinutes: 20,
      position: 3,
    ),
    RideRequest(
      id: 'r4',
      userId: 'other_user4',
      userName: 'Sophia Garcia',
      pickup: locations[0], // LXA House
      destination: locations[5], // McDonald's
      requestTime: now.subtract(const Duration(minutes: 30)),
      status: RideStatus.inQueue,
      estimatedWaitMinutes: 25,
      position: 4,
    ),
  ];
  
  // Rides in progress
  final inProgressRides = [
    RideRequest(
      id: 'r12',
      userId: 'other_user12',
      userName: 'Isabella Scott',
      pickup: locations[0], // LXA House
      destination: locations[5], // McDonald's
      requestTime: now.subtract(const Duration(minutes: 50)),
      status: RideStatus.inProgress,
      driverId: 'd4',
      assignedTime: now.subtract(const Duration(minutes: 45)),
      pickupTime: now.subtract(const Duration(minutes: 40)),
      estimatedWaitMinutes: 0,
    ),
  ];
  
  // Add rides to the main queue
  mainQueue.requests.addAll(mainQueueRides);
  
  // Add to the assigned driver
  _drivers[3].assignedRides.add(inProgressRides[0]);
  
  // Save all data - only adding mainQueue
  _queues.add(mainQueue);
  _allRides.addAll([...mainQueueRides, ...inProgressRides]);
  
  // Notify listeners
  _notifyListeners();
  
  // Setup automatic wait time updates
  _setupWaitTimeUpdates();
  }
  
  // Get user's current ride
  RideRequest? getUserCurrentRide(String userId) {
    return _allRides.firstWhere(
      (ride) => 
        ride.userId == userId && 
        ride.status != RideStatus.completed && 
        ride.status != RideStatus.canceled,
      orElse: () => RideRequest(
        id: '',
        userId: '',
        userName: '',
        pickup: Location(name: ''),
        destination: Location(name: ''),
        requestTime: DateTime.now(),
      ),
    );
    
    // If no matching ride or empty ID returned, there is no current ride
    //return ride.id.isEmpty ? null : ride;
  }
  
  // Create a new ride request
  RideRequest createRideRequest({
    required String userId,
    required String userName,
    required Location pickup,
    required Location destination,
  }) {
    // Check if user already has an active ride and cancel it
    final existingRide = getUserCurrentRide(userId);
    if (existingRide != null && existingRide.id.isNotEmpty) {
      cancelRide(existingRide);
    }
    
    final id = 'r${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    
    // Get the main queue (since we only have one queue now)
    final queue = _queues.first;
    
    // Position in queue will always be 5 for the user (as requested)
    final position = queue.length + 1;
    
    // Calculate wait time based on position
    int waitTime = 5; // Default base time

    if (queue.requests.isNotEmpty) {
    // Get the last person's wait time
    final lastPersonWaitTime = queue.requests.last.estimatedWaitMinutes;
    
    // Add additional time based on your algorithm (e.g., 5 minutes per position)
    final additionalTime = 5; // Time increment between positions
    
    // Calculate total wait time
    waitTime = lastPersonWaitTime + additionalTime;
  }
    
    // Create the request
  final request = RideRequest(
    id: id,
    userId: userId,
    userName: userName,
    pickup: pickup,
    destination: destination,
    requestTime: now,
    status: RideStatus.pending,
    estimatedWaitMinutes: waitTime,
    position: position,
  );
    
    // Add to all rides
    _allRides.add(request);
    
    // Add to queue
    _addToQueue(request, queue);
    
    // Assign driver if available
    _tryAssignDriver(request);
    
    // Notify listeners
    _notifyListeners();
    
    return request;
  }
  
 void _addToQueue(RideRequest ride, RideQueue queue) {
  // Set the ride status to in queue
  ride.status = RideStatus.inQueue;
  
  // Set position based on queue length
  ride.position = queue.length + 1;
  
  // Add to queue
  queue.requests.add(ride);
  
  // Update wait times for all rides in queue
  _updateQueueWaitTimes(queue);
  
  // Notify listeners
  _notifyListeners();
}
  
  // Try to assign a driver to a ride request
  void _tryAssignDriver(RideRequest ride) {
    // Only try to assign if the ride is in queue
    if (ride.status != RideStatus.inQueue) return;
    
    // Find available drivers
    final availableDrivers = _drivers.where((d) => d.isAvailable).toList();
    if (availableDrivers.isEmpty) return;
    
    // Find the closest driver
    Driver? closestDriver;
    double shortestDistance = double.infinity;
    
    for (final driver in availableDrivers) {
      if (driver.currentLocation != null) {
        final distance = driver.currentLocation!.distanceTo(ride.pickup);
        if (distance < shortestDistance) {
          shortestDistance = distance;
          closestDriver = driver;
        }
      }
    }
    
    // If we found a driver, assign the ride
    if (closestDriver != null) {
      _assignRideToDriver(ride, closestDriver);
    }
  }
  
  // Assign a ride to a driver
  void _assignRideToDriver(RideRequest ride, Driver driver) {
    // Update the ride
    ride.status = RideStatus.assigned;
    ride.driverId = driver.id;
    ride.assignedTime = DateTime.now();
    ride.estimatedWaitMinutes = 5; // Assume it takes 5 minutes for pickup
    
    // Update the driver
    driver.assignedRides.add(ride);
    if (driver.assignedRides.length >= driver.capacity) {
      driver.status = DriverStatus.busy;
    }
    
    // Remove from queue
    for (final queue in _queues) {
      queue.requests.remove(ride);
      
      // Update positions for remaining rides
      for (int i = 0; i < queue.requests.length; i++) {
        queue.requests[i].position = i + 1;
      }
      
      // Update wait times
      _updateQueueWaitTimes(queue);
    }
    
    // Notify listeners
    _notifyListeners();
  }
  
  // Start a ride
  void startRide(RideRequest ride) {
    if (ride.status != RideStatus.assigned) return;
    
    ride.status = RideStatus.inProgress;
    ride.pickupTime = DateTime.now();
    
    _notifyListeners();
  }
  
  // Complete a ride
  void completeRide(RideRequest ride) {
    if (ride.status != RideStatus.inProgress) return;
    
    ride.status = RideStatus.completed;
    ride.completionTime = DateTime.now();
    
    // Update driver status
    if (ride.driverId != null) {
      final driver = _drivers.firstWhere((d) => d.id == ride.driverId);
      driver.assignedRides.remove(ride);
      
      // If driver still has capacity, set to available
      if (driver.assignedRides.length < driver.capacity) {
        driver.status = DriverStatus.available;
      }
    }
    
    _notifyListeners();
  }
  
  // Cancel a ride
  void cancelRide(RideRequest ride) {
    if (ride.status == RideStatus.completed) return;
    
    ride.status = RideStatus.canceled;
    
    // Remove from queue if needed
    for (final queue in _queues) {
      if (queue.requests.contains(ride)) {
        queue.requests.remove(ride);
        
        // Update positions
        for (int i = 0; i < queue.requests.length; i++) {
          queue.requests[i].position = i + 1;
        }
        
        // Update wait times
        _updateQueueWaitTimes(queue);
      }
    }
    
    // Update driver if assigned
    if (ride.driverId != null) {
      final driver = _drivers.firstWhere((d) => d.id == ride.driverId);
      driver.assignedRides.remove(ride);
      
      // If driver has capacity, set to available
      if (driver.assignedRides.length < driver.capacity) {
        driver.status = DriverStatus.available;
      }
    }
    
    _notifyListeners();
  }
  
  // Update driver status
  void updateDriverStatus(String driverId, DriverStatus newStatus) {
    final driver = _drivers.firstWhere((d) => d.id == driverId);
    
    // If going offline, cancel all assigned rides
    if (newStatus == DriverStatus.offline && driver.assignedRides.isNotEmpty) {
      // Move rides back to queue
      for (final ride in List.from(driver.assignedRides)) {
        if (ride.status == RideStatus.assigned) {
          ride.status = RideStatus.pending;
          ride.driverId = null;
          ride.assignedTime = null;
          
          // Add back to appropriate queue
          final queue = _queues.first; // Always use main queue now
          _addToQueue(ride, queue);
        }
      }
      
      driver.assignedRides.clear();
    }
    
    driver.status = newStatus;
    _notifyListeners();
  }
  
  // Find the appropriate queue for a ride - simplified to always return main queue
  RideQueue _findAppropriateQueue(Location pickup, Location destination) {
    // We only have one queue now - the main queue
    return _queues.first;
  }
  
  // Calculate estimated wait time
  int _calculateEstimatedWaitTime(RideQueue queue, Location pickup) {
    final baseWaitTime = 5; // Base wait time in minutes
    
    // Add time based on queue length
    final queueFactor = queue.length * 5;
    
    // Adjust based on number of available drivers
    final availableDriversCount = _drivers.where((d) => d.isAvailable).length;
    final driverFactor = availableDriversCount > 0 ? 0 : 10; // Add 10 min if no drivers
    
    // Adjust based on pickup location distance from nearest driver
    double minDistance = double.infinity;
    for (final driver in _drivers.where((d) => d.isAvailable)) {
      if (driver.currentLocation != null) {
        final distance = driver.currentLocation!.distanceTo(pickup);
        if (distance < minDistance) {
          minDistance = distance;
        }
      }
    }
    
    // 1 minute per 0.5 km distance
    final distanceFactor = (minDistance == double.infinity) ? 15 : (minDistance / 0.5).round();
    
    // Calculate total wait time
    return baseWaitTime + queueFactor + driverFactor + distanceFactor;
  }
  
  // Update wait times for all rides in a queue
  void _updateQueueWaitTimes(RideQueue queue) {
    // Sort queue by position first to ensure accuracy
    queue.requests.sort((a, b) => 
      (a.position ?? 999).compareTo(b.position ?? 999)
    );
    
    for (int i = 0; i < queue.requests.length; i++) {
      final request = queue.requests[i];
      
      // Make sure position matches index+1
      request.position = i + 1;
      
      // Base wait time depends on position
      final positionFactor = i * 5;
      
      // Get other factors from general calculation
      final baseWaitTime = _calculateEstimatedWaitTime(queue, request.pickup);
      
      // Update the wait time
      request.estimatedWaitMinutes = baseWaitTime + positionFactor;
    }
  }
  
  // Periodically update wait times
  void _setupWaitTimeUpdates() {
    // Update every minute
    Timer.periodic(const Duration(minutes: 1), (timer) {
      // Update wait times in all queues
      for (final queue in _queues) {
        _updateQueueWaitTimes(queue);
      }
      
      // Decrease wait time for assigned rides
      for (final ride in _allRides) {
        if (ride.status == RideStatus.assigned && ride.estimatedWaitMinutes > 0) {
          ride.estimatedWaitMinutes -= 1;
        }
      }
      
      _notifyListeners();
    });
  }
  
  // Notify all listeners of changes
  void _notifyListeners() {
    _driversStreamController.add(_drivers);
    _queuesStreamController.add(_queues);
    _ridesStreamController.add(_allRides);
  }
  
  // Dispose of stream controllers
  void dispose() {
    _driversStreamController.close();
    _queuesStreamController.close();
    _ridesStreamController.close();
  }
}