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
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      count: json['count'],
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