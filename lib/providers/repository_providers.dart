import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:smartgymai/data/services/database_service.dart';
import 'package:smartgymai/data/services/mqtt_service.dart';
import 'package:smartgymai/data/repositories/user_repository_impl.dart';
import 'package:smartgymai/data/repositories/check_in_repository_impl.dart';
import 'package:smartgymai/data/repositories/sensor_repository_impl.dart';
import 'package:smartgymai/domain/repositories/user_repository.dart';
import 'package:smartgymai/domain/repositories/check_in_repository.dart';
import 'package:smartgymai/domain/repositories/sensor_repository.dart';

// Logger provider
final loggerProvider = Provider<Logger>((ref) {
  return Logger();
});

// Service providers
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final mqttServiceProvider = Provider<MqttService>((ref) {
  final mqttService = MqttService();
  // Connect to MQTT broker when someone starts watching this provider
  mqttService.connect();
  
  // Dispose of the MQTT service when no longer needed
  ref.onDispose(() {
    mqttService.dispose();
  });
  
  return mqttService;
});

// Repository providers
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return UserRepositoryImpl(databaseService);
});

final checkInRepositoryProvider = Provider<CheckInRepository>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return CheckInRepositoryImpl(databaseService);
});

final sensorRepositoryProvider = Provider<SensorRepository>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  final mqttService = ref.watch(mqttServiceProvider);
  final logger = ref.watch(loggerProvider);
  return SensorRepositoryImpl(databaseService, mqttService, logger);
}); 