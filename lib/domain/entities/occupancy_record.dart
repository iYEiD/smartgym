import 'package:equatable/equatable.dart';

class OccupancyRecord extends Equatable {
  final int? id;
  final DateTime timestamp;
  final int count;
  final Map<String, dynamic>? sensorReadings;

  const OccupancyRecord({
    this.id,
    required this.timestamp,
    required this.count,
    this.sensorReadings,
  });

  OccupancyRecord copyWith({
    int? id,
    DateTime? timestamp,
    int? count,
    Map<String, dynamic>? sensorReadings,
  }) {
    return OccupancyRecord(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      count: count ?? this.count,
      sensorReadings: sensorReadings ?? this.sensorReadings,
    );
  }

  @override
  List<Object?> get props => [id, timestamp, count, sensorReadings];
} 