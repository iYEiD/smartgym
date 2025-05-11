import 'dart:async';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smartgymai/core/constants/mqtt_constants.dart';
import 'package:smartgymai/data/models/occupancy_record_model.dart';
import 'package:smartgymai/data/models/sensor_data_model.dart';
import 'package:smartgymai/data/services/database_service.dart';
import 'package:smartgymai/data/services/mqtt_service.dart';
import 'package:smartgymai/domain/entities/occupancy_record.dart';
import 'package:smartgymai/domain/entities/sensor_data.dart';
import 'package:smartgymai/domain/repositories/sensor_repository.dart';
import 'package:smartgymai/providers/repository_providers.dart';
import 'package:smartgymai/domain/entities/check_in_log.dart';

class SensorRepositoryImpl implements SensorRepository {
  final DatabaseService _databaseService;
  final MqttService _mqttService;
  final Logger _logger = Logger();
  final Ref _ref;
  
  final _sensorDataStreamController = StreamController<SensorData>.broadcast();
  final _occupancyStreamController = StreamController<OccupancyRecord>.broadcast();
  
  int? _currentOccupancy = 0;
  
  SensorRepositoryImpl(this._databaseService, this._mqttService, this._ref) {
    _initialize();
  }
  
  Future<void> _initialize() async {
    try {
      // First, load the latest data from the database
      await _updateUIWithLatestData();
      
      // Then subscribe to MQTT updates
      _mqttService.subscribeTo(MqttConstants.sensorDataTopic).listen((data) async {
        try {
          _logger.i('Processing incoming sensor data: $data');
          
          // Convert the data to SensorDataModel
          final sensorData = SensorDataModel.fromMqttPayload(data);
          _logger.i('Converted to SensorDataModel: ${sensorData.toJson()}');
          
          // Save the sensor data using raw SQL
          await _databaseService.execute(
            'INSERT INTO sensor_data (light, temperature, humidity, parking, motion, lighting, ac, gate, timestamp) VALUES (@light, @temperature, @humidity, @parking, @motion, @lighting, @ac, @gate, @timestamp)',
            substitutionValues: {
              'light': sensorData.light,
              'temperature': sensorData.temperature,
              'humidity': sensorData.humidity,
              'parking': sensorData.parking ?? false,
              'motion': sensorData.motion ?? false,
              'lighting': sensorData.lighting ?? false,
              'ac': sensorData.ac ?? false,
              'gate': sensorData.gate ?? false,
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
          _logger.i('Saved sensor data to database');
          
          // Get current occupancy count before updating
          final currentOccupancy = await _getCurrentOccupancy();
          
          // Update occupancy record with new sensor data
          await _databaseService.execute(
            'INSERT INTO occupancy_records (timestamp, count, sensor_readings) VALUES (@timestamp, @count, @sensor_readings)',
            substitutionValues: {
              'timestamp': DateTime.now().toIso8601String(),
              'count': currentOccupancy,
              'sensor_readings': json.encode({
                'light': sensorData.light,
                'temperature': sensorData.temperature,
                'humidity': sensorData.humidity,
              }),
            },
          );
          _logger.i('Saved occupancy record to database');
          
          // Fetch and update UI with latest data
          await _updateUIWithLatestData();
        } catch (e) {
          _logger.e('Error processing sensor data: $e');
        }
      });
      
      // Subscribe to member card swipe topic for automatic check-in/out
      _mqttService.subscribeTo(MqttConstants.memberCardSwipeTopic).listen((data) async {
        try {
          _logger.i('Member card swipe data received: $data');
          
          if (data.containsKey(MqttConstants.rfidIdField)) {
            final rfidId = data[MqttConstants.rfidIdField];
            if (rfidId != null && rfidId is String && rfidId.isNotEmpty) {
              await _handleMemberCardSwipe(rfidId);
            }
          }
        } catch (e) {
          _logger.e('Error processing member card swipe: $e');
        }
      });
      
      // Subscribe to RFID register topic for debugging
      _mqttService.subscribeTo(MqttConstants.rfidRegisterTopic).listen((data) {
        try {
          _logger.i('RFID register data received: $data');
        } catch (e) {
          _logger.e('Error processing RFID data: $e');
        }
      });
    } catch (e) {
      _logger.e('Error initializing sensor repository: $e');
    }
  }

  Future<int> _getCurrentOccupancy() async {
    try {
      final results = await _databaseService.query(
        'SELECT count FROM occupancy_records ORDER BY timestamp DESC LIMIT 1',
      );
      
      if (results.isNotEmpty && results.first['count'] != null) {
        return results.first['count'] as int;
      }
      return 0;
    } catch (e) {
      _logger.e('Error getting current occupancy: $e');
      return 0;
    }
  }

  Future<void> _updateUIWithLatestData() async {
    try {
      // Get the latest sensor data
      final sensorResults = await _databaseService.query(
        'SELECT * FROM sensor_data ORDER BY timestamp DESC LIMIT 1',
      );
      
      if (sensorResults.isNotEmpty) {
        // Convert timestamp to ISO string if it's a DateTime
        final data = Map<String, dynamic>.from(sensorResults.first);
        if (data['timestamp'] is DateTime) {
          data['timestamp'] = (data['timestamp'] as DateTime).toIso8601String();
        }
        
        final latestData = SensorDataModel.fromJson(data);
        _logger.i('Fetched latest sensor data: ${json.encode(latestData.toJson())}');
        _sensorDataStreamController.add(latestData);
      }
      
      // Get the latest occupancy data
      final occupancyResults = await _databaseService.query(
        'SELECT * FROM occupancy_records ORDER BY timestamp DESC LIMIT 1',
      );
      
      if (occupancyResults.isNotEmpty) {
        // Convert timestamp to ISO string if it's a DateTime
        final data = Map<String, dynamic>.from(occupancyResults.first);
        if (data['timestamp'] is DateTime) {
          data['timestamp'] = (data['timestamp'] as DateTime).toIso8601String();
        }
        
        final latestOccupancy = OccupancyRecordModel.fromJson(data);
        _logger.i('Fetched latest occupancy: ${json.encode(latestOccupancy.toJson())}');
        _occupancyStreamController.add(latestOccupancy);
        _currentOccupancy = latestOccupancy.count;
      }
    } catch (e) {
      _logger.e('Error updating UI with latest data: $e');
    }
  }

  @override
  Future<void> initialize() async {
    await _initialize();
    // Initial UI update with latest data
    await _updateUIWithLatestData();
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
        timestamp, light, temperature, humidity, 
        parking, motion, lighting, ac, gate
      ) VALUES (
        @timestamp, @light, @temperature, @humidity, 
        @parking, @motion, @lighting, @ac, @gate
      )
      ''',
      substitutionValues: {
        'timestamp': sensorDataModel.timestamp.toIso8601String(),
        'light': sensorDataModel.light,
        'temperature': sensorDataModel.temperature,
        'humidity': sensorDataModel.humidity,
        'parking': sensorDataModel.parking,
        'motion': sensorDataModel.motion,
        'lighting': sensorDataModel.lighting,
        'ac': sensorDataModel.ac,
        'gate': sensorDataModel.gate,
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

  Future<void> _handleMemberCardSwipe(String rfidId) async {
    try {
      // Get the repositories
      final userRepository = _ref.read(userRepositoryProvider);
      final checkInRepository = _ref.read(checkInRepositoryProvider);
      
      // Find the user by RFID
      final user = await userRepository.getUserByRfid(rfidId);
      
      if (user == null) {
        _logger.w('Unknown RFID card swiped: $rfidId');
        return;
      }
      
      // Check if the user is currently checked in
      if (user.isCurrentlyCheckedIn) {
        // User is checked in, so check them out
        _logger.i('Checking out user: ${user.fullName}');
        await checkInRepository.checkoutUser(user.id, DateTime.now());
        _logger.i('User checked out successfully');
      } else {
        // User is not checked in, so check them in
        _logger.i('Checking in user: ${user.fullName}');
        await checkInRepository.addCheckIn(
          CheckInLog(
            userId: user.id,
            checkInTime: DateTime.now(),
          ),
        );
        _logger.i('User checked in successfully');
      }
      
      // Update UI with latest data
      await _updateUIWithLatestData();
    } catch (e) {
      _logger.e('Error handling member card swipe: $e');
    }
  }

  Future<void> dispose() async {
    await _sensorDataStreamController.close();
    await _occupancyStreamController.close();
  }
} 