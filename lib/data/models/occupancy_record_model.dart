import 'package:smartgymai/domain/entities/occupancy_record.dart';

class OccupancyRecordModel extends OccupancyRecord {
  const OccupancyRecordModel({
    super.id,
    required super.timestamp,
    required super.count,
    super.sensorReadings,
  });

  factory OccupancyRecordModel.fromJson(Map<String, dynamic> json) {
    return OccupancyRecordModel(
      id: json['id'] != null ? (json['id'] is String ? int.parse(json['id']) : json['id']) : null,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      count: json['count'] ?? 0,
      sensorReadings: json['sensor_readings'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'count': count,
      'sensor_readings': sensorReadings,
    };
  }

  factory OccupancyRecordModel.fromEntity(OccupancyRecord entity) {
    return OccupancyRecordModel(
      id: entity.id,
      timestamp: entity.timestamp,
      count: entity.count,
      sensorReadings: entity.sensorReadings,
    );
  }
} 