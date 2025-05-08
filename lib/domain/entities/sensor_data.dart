import 'package:equatable/equatable.dart';

class SensorData extends Equatable {
  final int? id;
  final DateTime timestamp;
  final int? lightLevel;
  final double? temperature;
  final double? humidity;
  final bool? motionDetected;
  final List<bool> parkingSpots;

  const SensorData({
    this.id,
    required this.timestamp,
    this.lightLevel,
    this.temperature,
    this.humidity,
    this.motionDetected,
    required this.parkingSpots,
  });

  // Calculate number of available parking spots
  int get availableParkingSpots => 
      parkingSpots.where((spot) => spot == true).length;
      
  // Calculate percentage of available parking
  double get parkingAvailabilityPercentage => 
      parkingSpots.isEmpty ? 0 : availableParkingSpots / parkingSpots.length * 100;

  SensorData copyWith({
    int? id,
    DateTime? timestamp,
    int? lightLevel,
    double? temperature,
    double? humidity,
    bool? motionDetected,
    List<bool>? parkingSpots,
  }) {
    return SensorData(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      lightLevel: lightLevel ?? this.lightLevel,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      motionDetected: motionDetected ?? this.motionDetected,
      parkingSpots: parkingSpots ?? this.parkingSpots,
    );
  }

  @override
  List<Object?> get props => [
    id, timestamp, lightLevel, temperature, 
    humidity, motionDetected, parkingSpots
  ];
} 