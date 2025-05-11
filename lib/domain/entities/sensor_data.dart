import 'package:equatable/equatable.dart';

class SensorData extends Equatable {
  final int? id;
  final DateTime timestamp;
  final int? light;
  final double? temperature;
  final double? humidity;
  final bool? parking;
  final bool? motion;
  final bool? lighting;
  final bool? ac;
  final bool? gate;

  const SensorData({
    this.id,
    required this.timestamp,
    this.light,
    this.temperature,
    this.humidity,
    this.parking,
    this.motion,
    this.lighting,
    this.ac,
    this.gate,
  });

  // Calculate number of available parking spots (1 dynamic + 5 static)
  int get availableParkingSpots => 
      (parking == true ? 1 : 0) + 5; // 5 static spots + 1 dynamic spot
      
  // Calculate percentage of available parking
  double get parkingAvailabilityPercentage => 
      (availableParkingSpots / 6) * 100; // Total of 6 spots

  SensorData copyWith({
    int? id,
    DateTime? timestamp,
    int? light,
    double? temperature,
    double? humidity,
    bool? parking,
    bool? motion,
    bool? lighting,
    bool? ac,
    bool? gate,
  }) {
    return SensorData(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      light: light ?? this.light,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      parking: parking ?? this.parking,
      motion: motion ?? this.motion,
      lighting: lighting ?? this.lighting,
      ac: ac ?? this.ac,
      gate: gate ?? this.gate,
    );
  }

  @override
  List<Object?> get props => [
    id, timestamp, light, temperature, 
    humidity, parking, motion, lighting, ac, gate
  ];
} 