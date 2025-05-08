import 'dart:async';
import 'dart:convert';

import 'package:smartgymai/core/constants/mqtt_constants.dart';
import 'package:smartgymai/data/models/occupancy_record_model.dart';
import 'package:smartgymai/data/models/sensor_data_model.dart';
import 'package:smartgymai/data/services/database_service.dart';
import 'package:smartgymai/data/services/mqtt_service.dart';
import 'package:smartgymai/domain/entities/occupancy_record.dart';
import 'package:smartgymai/domain/entities/sensor_data.dart';
import 'package:smartgymai/domain/repositories/sensor_repository.dart';

class SensorRepositoryImpl implements SensorRepository {
  final DatabaseService _databaseService;
  final MqttService _mqttService;
  
  final _sensorDataStreamController = StreamController<SensorData>.broadcast();
  final _occupancyStreamController = StreamController<OccupancyRecord>.broadcast();
  
  SensorRepositoryImpl(this._databaseService, this._mqttService) {
    _initialize();
  }
  
  void _initialize() {
    // Subscribe to sensor data MQTT topic
    _mqttService.subscribeTo(MqttConstants.sensorDataTopic).listen((data) {
      final sensorData = SensorDataModel.fromMqttPayload(data);
      saveSensorData(sensorData);
      _sensorDataStreamController.add(sensorData);
    });
    
    // Subscribe to occupancy MQTT topic
    _mqttService.subscribeTo(MqttConstants.occupancyTopic).listen((data) {
      if (data.containsKey('count')) {
        final occupancyRecord = OccupancyRecordModel(
          timestamp: DateTime.now(),
          count: data['count'],
          sensorReadings: data,
        );
        saveOccupancyRecord(occupancyRecord);
        _occupancyStreamController.add(occupancyRecord);
      }
    });
  }

  @override
  Stream<SensorData> get sensorDataStream => _sensorDataStreamController.stream;

  @override
  Stream<OccupancyRecord> get occupancyStream => _occupancyStreamController.stream;

  @override
  Future<List<SensorData>> getSensorDataHistory(DateTime start, DateTime end) async {
    final results = await _databaseService.query(
      '''
      SELECT * FROM sensor_data 
      WHERE timestamp BETWEEN @start AND @end
      ORDER BY timestamp DESC
      ''',
      substitutionValues: {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
      },
    );
    
    return results.map((data) => SensorDataModel.fromJson(data)).toList();
  }

  @override
  Future<SensorData?> getLatestSensorData() async {
    final results = await _databaseService.query(
      '''
      SELECT * FROM sensor_data 
      ORDER BY timestamp DESC 
      LIMIT 1
      ''',
    );
    
    if (results.isEmpty) {
      return null;
    }
    
    return SensorDataModel.fromJson(results.first);
  }

  @override
  Future<void> saveSensorData(SensorData sensorData) async {
    final sensorDataModel = sensorData is SensorDataModel
        ? sensorData
        : SensorDataModel.fromEntity(sensorData);
    
    await _databaseService.execute(
      '''
      INSERT INTO sensor_data (
        timestamp, light_level, temperature, humidity, 
        motion_detected, parking_spots
      ) VALUES (
        @timestamp, @light_level, @temperature, @humidity, 
        @motion_detected, @parking_spots
      )
      ''',
      substitutionValues: {
        'timestamp': sensorDataModel.timestamp.toIso8601String(),
        'light_level': sensorDataModel.lightLevel,
        'temperature': sensorDataModel.temperature,
        'humidity': sensorDataModel.humidity,
        'motion_detected': sensorDataModel.motionDetected,
        'parking_spots': json.encode(sensorDataModel.parkingSpots),
      },
    );
  }

  @override
  Future<List<OccupancyRecord>> getOccupancyRecords(DateTime start, DateTime end) async {
    final results = await _databaseService.query(
      '''
      SELECT * FROM occupancy_records 
      WHERE timestamp BETWEEN @start AND @end
      ORDER BY timestamp DESC
      ''',
      substitutionValues: {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
      },
    );
    
    return results.map((data) => OccupancyRecordModel.fromJson(data)).toList();
  }

  @override
  Future<OccupancyRecord?> getLatestOccupancy() async {
    final results = await _databaseService.query(
      '''
      SELECT * FROM occupancy_records 
      ORDER BY timestamp DESC 
      LIMIT 1
      ''',
    );
    
    if (results.isEmpty) {
      return null;
    }
    
    return OccupancyRecordModel.fromJson(results.first);
  }

  @override
  Future<void> saveOccupancyRecord(OccupancyRecord record) async {
    final recordModel = record is OccupancyRecordModel
        ? record
        : OccupancyRecordModel.fromEntity(record);
    
    await _databaseService.execute(
      '''
      INSERT INTO occupancy_records (
        timestamp, count, sensor_readings
      ) VALUES (
        @timestamp, @count, @sensor_readings
      )
      ''',
      substitutionValues: {
        'timestamp': recordModel.timestamp.toIso8601String(),
        'count': recordModel.count,
        'sensor_readings': recordModel.sensorReadings != null 
            ? json.encode(recordModel.sensorReadings) 
            : null,
      },
    );
  }

  @override
  Future<Map<String, dynamic>> getOccupancyAnalytics(DateTime start, DateTime end) async {
    final hourlyResults = await _databaseService.query(
      '''
      SELECT 
        date_trunc('hour', timestamp) AS hour,
        AVG(count) AS avg_count,
        MAX(count) AS max_count,
        MIN(count) AS min_count,
        COUNT(*) AS data_points
      FROM occupancy_records
      WHERE timestamp BETWEEN @start AND @end
      GROUP BY date_trunc('hour', timestamp)
      ORDER BY hour
      ''',
      substitutionValues: {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
      },
    );
    
    final dailyResults = await _databaseService.query(
      '''
      SELECT 
        date_trunc('day', timestamp) AS day,
        AVG(count) AS avg_count,
        MAX(count) AS max_count,
        MIN(count) AS min_count,
        COUNT(*) AS data_points
      FROM occupancy_records
      WHERE timestamp BETWEEN @start AND @end
      GROUP BY date_trunc('day', timestamp)
      ORDER BY day
      ''',
      substitutionValues: {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
      },
    );
    
    return {
      'hourly': hourlyResults,
      'daily': dailyResults,
    };
  }

  @override
  Future<Map<String, dynamic>> getPredictedOccupancy() async {
    // This is a simplified prediction model based on historical data
    // For a real app, you might use a more sophisticated prediction algorithm
    
    final dayOfWeek = DateTime.now().weekday;
    final hourOfDay = DateTime.now().hour;
    
    final historicalResults = await _databaseService.query(
      '''
      SELECT 
        AVG(count) AS predicted_count
      FROM occupancy_records
      WHERE EXTRACT(DOW FROM timestamp) = @day_of_week
        AND EXTRACT(HOUR FROM timestamp) = @hour_of_day
      GROUP BY 
        EXTRACT(DOW FROM timestamp),
        EXTRACT(HOUR FROM timestamp)
      ''',
      substitutionValues: {
        'day_of_week': dayOfWeek,
        'hour_of_day': hourOfDay,
      },
    );
    
    int predictedCount = 0;
    if (historicalResults.isNotEmpty && historicalResults.first['predicted_count'] != null) {
      predictedCount = historicalResults.first['predicted_count'].round();
    }
    
    return {
      'predicted_count': predictedCount,
      'day_of_week': dayOfWeek,
      'hour_of_day': hourOfDay,
    };
  }

  Future<void> dispose() async {
    await _sensorDataStreamController.close();
    await _occupancyStreamController.close();
  }
} 