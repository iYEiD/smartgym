import 'dart:convert';
import 'package:smartgymai/domain/entities/occupancy_record.dart';

class OccupancyRecordModel extends OccupancyRecord {
  const OccupancyRecordModel({
    super.id,
    required super.timestamp,
    required super.count,
    super.sensorReadings,
  });

  factory OccupancyRecordModel.fromJson(Map<String, dynamic> json) {
    DateTime timestamp;
    try {
      if (json['timestamp'] is String) {
        timestamp = DateTime.parse(json['timestamp']);
      } else if (json['timestamp'] is DateTime) {
        timestamp = json['timestamp'];
      } else {
        timestamp = DateTime.now();
      }
    } catch (e) {
      // Fallback to current time if parsing fails
      timestamp = DateTime.now();
    }
    
    Map<String, dynamic>? sensorReadings;
    try {
      if (json['sensor_readings'] is String) {
        sensorReadings = jsonDecode(json['sensor_readings']);
      } else if (json['sensor_readings'] is Map) {
        sensorReadings = Map<String, dynamic>.from(json['sensor_readings']);
      }
    } catch (e) {
      sensorReadings = null;
    }
    
    return OccupancyRecordModel(
      id: json['id'] != null ? (json['id'] is String ? int.parse(json['id']) : json['id']) : null,
      timestamp: timestamp,
      count: json['count'] ?? 0,
      sensorReadings: sensorReadings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'count': count,
      'sensor_readings': sensorReadings != null ? jsonEncode(sensorReadings) : null,
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