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
      id: json['id'] != null ? (json['id'] is String ? int.parse(json['id']) : json['id']) : null,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      lightLevel: json['light_level'],
      temperature: json['temperature'],
      humidity: json['humidity'],
      motionDetected: json['motion_detected'] ?? false,
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
    // Handle payload format from UA/IOT topics
    final List<bool> parkingSpots = [];
    
    // Check if parkingSensor exists in the payload
    if (payload.containsKey('parkingSensor') && payload['parkingSensor'] is List) {
      final List parkingSensorData = payload['parkingSensor'] as List;
      parkingSpots.addAll(parkingSensorData.map((spot) => spot == 1 || spot == true).toList());
    }

    return SensorDataModel(
      timestamp: DateTime.now(),
      lightLevel: payload['lightSensor'] is num ? payload['lightSensor'] : null,
      temperature: payload['temperature'] is num ? payload['temperature']?.toDouble() : null,
      humidity: payload['humidity'] is num ? payload['humidity']?.toDouble() : null,
      motionDetected: payload['motionSensor'] == 1 || payload['motionSensor'] == true,
      parkingSpots: parkingSpots,
    );
  }
} 