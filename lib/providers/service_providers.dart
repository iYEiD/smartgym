import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartgymai/data/services/database_service.dart';
import 'package:smartgymai/data/services/mqtt_service.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final mqttServiceProvider = Provider<MqttService>((ref) {
  return MqttService();
}); 