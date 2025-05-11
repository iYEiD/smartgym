import 'package:smartgymai/domain/entities/sensor_data.dart';
import 'package:smartgymai/domain/entities/occupancy_record.dart';

abstract class SensorRepository {
  Future<List<SensorData>> getSensorDataHistory(DateTime start, DateTime end);
  Future<SensorData?> getLatestSensorData();
  Future<void> saveSensorData(SensorData sensorData);
  
  // Occupancy related methods
  Future<List<OccupancyRecord>> getOccupancyRecords(DateTime start, DateTime end);
  Future<OccupancyRecord?> getLatestOccupancy();
  Future<void> saveOccupancyRecord(OccupancyRecord record);
  
  // Analytics methods
  Future<Map<String, dynamic>> getOccupancyAnalytics(DateTime start, DateTime end);
  Future<Map<String, dynamic>> getPredictedOccupancy();
  
  // Real-time connection
  Stream<SensorData> get sensorDataStream;
  Stream<OccupancyRecord> get occupancyStream;
} 