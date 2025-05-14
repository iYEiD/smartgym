import 'package:smartgymai/domain/entities/sensor_data.dart';

class SensorDataModel extends SensorData {
  const SensorDataModel({
    super.id,
    required super.timestamp,
    super.light,
    super.temperature,
    super.humidity,
    super.parking,
    super.motion,
    super.lighting,
    super.ac,
    super.gate,
  });

  factory SensorDataModel.fromJson(Map<String, dynamic> json) {
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

    return SensorDataModel(
      id: json['id'] != null ? (json['id'] is String ? int.parse(json['id']) : json['id']) : null,
      timestamp: timestamp,
      light: json['light'],
      temperature: json['temperature'] is num ? json['temperature'].toDouble() : null,
      humidity: json['humidity'] is num ? json['humidity'].toDouble() : null,
      parking: json['parking'],
      motion: json['motion'],
      lighting: json['lighting'],
      ac: json['ac'],
      gate: json['gate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'light': light,
      'temperature': temperature,
      'humidity': humidity,
      'parking': parking,
      'motion': motion,
      'lighting': lighting,
      'ac': ac,
      'gate': gate,
    };
  }

  factory SensorDataModel.fromEntity(SensorData entity) {
    return SensorDataModel(
      id: entity.id,
      timestamp: entity.timestamp,
      light: entity.light,
      temperature: entity.temperature,
      humidity: entity.humidity,
      parking: entity.parking,
      motion: entity.motion,
      lighting: entity.lighting,
      ac: entity.ac,
      gate: entity.gate,
    );
  }

  factory SensorDataModel.fromMqttPayload(Map<String, dynamic> payload) {
    return SensorDataModel(
      timestamp: DateTime.now(),
      light: payload['light'] is num ? payload['light'].toInt() : null,
      temperature: payload['temperature'] is num ? payload['temperature'].toDouble() : null,
      humidity: payload['humidity'] is num ? payload['humidity'].toDouble() : null,
      parking: payload['parking'] == 1 || payload['parking'] == true,
      motion: payload['motion'] == 1 || payload['motion'] == true,
      lighting: payload['lighting'] == 1 || payload['lighting'] == true,
      ac: payload['ac'] == 1 || payload['ac'] == true,
      gate: payload['gate'] == 1 || payload['gate'] == true,
    );
  }
} 