import 'package:smartgymai/domain/entities/sensor_data.dart';

class SensorDataModel extends SensorData {
  const SensorDataModel({
    super.id,
    required super.timestamp,
    super.lightLevel,
    super.temperature,
    super.humidity,
    super.motionDetected,
    required super.parkingSpots,
  });

  factory SensorDataModel.fromJson(Map<String, dynamic> json) {
    final parkingSpotsData = json['parking_spots'] is List
        ? List<bool>.from(json['parking_spots'])
        : <bool>[];

    return SensorDataModel(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      lightLevel: json['light_level'],
      temperature: json['temperature'],
      humidity: json['humidity'],
      motionDetected: json['motion_detected'],
      parkingSpots: parkingSpotsData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'light_level': lightLevel,
      'temperature': temperature,
      'humidity': humidity,
      'motion_detected': motionDetected,
      'parking_spots': parkingSpots,
    };
  }

  factory SensorDataModel.fromEntity(SensorData entity) {
    return SensorDataModel(
      id: entity.id,
      timestamp: entity.timestamp,
      lightLevel: entity.lightLevel,
      temperature: entity.temperature,
      humidity: entity.humidity,
      motionDetected: entity.motionDetected,
      parkingSpots: entity.parkingSpots,
    );
  }

  factory SensorDataModel.fromMqttPayload(Map<String, dynamic> payload) {
    final List<bool> parkingSpots = [];
    
    if (payload['parkingSensor'] is List) {
      final List parkingSensorData = payload['parkingSensor'] as List;
      parkingSpots.addAll(parkingSensorData.map((spot) => spot as bool));
    }

    return SensorDataModel(
      timestamp: DateTime.now(),
      lightLevel: payload['lightSensor'],
      temperature: payload['temperature']?.toDouble(),
      humidity: payload['humidity']?.toDouble(),
      motionDetected: payload['motionSensor'],
      parkingSpots: parkingSpots,
    );
  }
} 