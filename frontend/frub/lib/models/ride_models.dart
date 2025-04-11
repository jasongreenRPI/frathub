// Models for ride sharing system

enum RideStatus {
  pending,
  inQueue,
  assigned,
  inProgress,
  completed,
  canceled
}

enum DriverStatus {
  offline,
  available,
  busy
}

// Class for location of user
class Location {
  final String name;
  final double? latitude;
  final double? longitude;

  Location({
    required this.name,
    this.latitude,
    this.longitude,
  });

  // Simplified method to calculate distance (usually would use proper geolocation)
  double distanceTo(Location other) {
    // Dummy calculation - in a real app, use proper geolocation
    if (latitude == null || longitude == null || other.latitude == null || other.longitude == null) {
      return 5.0; // Default distance in km
    }
    
    // Very simplified distance calculation
    final latDiff = (latitude! - other.latitude!).abs();
    final longDiff = (longitude! - other.longitude!).abs();
    return (latDiff + longDiff) * 111.0; // Rough conversion to km
  }
}

// Class for each individual driver
class Driver {
  final String id;
  final String name;
  final String vehicleModel;
  final String licensePlate;
  final int capacity;
  DriverStatus status;
  Location? currentLocation;
  List<RideRequest> assignedRides;

  Driver({
    required this.id,
    required this.name,
    required this.vehicleModel,
    required this.licensePlate,
    required this.capacity,
    this.status = DriverStatus.offline,
    this.currentLocation,
    List<RideRequest>? assignedRides,
  }) : assignedRides = assignedRides ?? [];

  bool get isAvailable => status == DriverStatus.available && assignedRides.length < capacity;
  
  int get availableSeats => capacity - assignedRides.length;
}

class RideRequest {
  final String id;
  final String userId;
  final String userName;
  final Location pickup;
  final Location destination;
  final DateTime requestTime;
  RideStatus status;
  String? driverId;
  DateTime? assignedTime;
  DateTime? pickupTime;
  DateTime? completionTime;
  int estimatedWaitMinutes;
  int? position; // Position in queue

  RideRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.pickup,
    required this.destination,
    required this.requestTime,
    this.status = RideStatus.pending,
    this.driverId,
    this.assignedTime,
    this.pickupTime,
    this.completionTime,
    this.estimatedWaitMinutes = 0,
    this.position,
  });

  // Calculate ride distance
  double get distance => pickup.distanceTo(destination);
  
  // Calculate estimated ride duration (very simplified)
  int get estimatedDurationMinutes => (distance / 0.5).round(); // Assuming 0.5 km/min
}


// Class for the RideQueue
class RideQueue {
  final String id;
  final String name;
  final List<RideRequest> requests;
  
  RideQueue({
    required this.id,
    required this.name, 
    List<RideRequest>? requests,
  }) : requests = requests ?? [];
  
  int get length => requests.length;
  
  bool get isEmpty => requests.isEmpty;
  
  int get totalWaitTime {
    if (isEmpty) return 0;
    return requests.map((r) => r.estimatedWaitMinutes).reduce((a, b) => a + b);
  }
  
  double get averageWaitTime {
    if (isEmpty) return 0;
    return totalWaitTime / length;
  }
}