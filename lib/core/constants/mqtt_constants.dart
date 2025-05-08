class MqttConstants {
  // Server configuration
  static const String serverHost = 'broker.hivemq.com'; // Use a real broker for production
  static const int serverPort = 1883;
  static const int secureServerPort = 8883;
  static const bool useWebSocket = false;
  static const int webSocketPort = 8884;
  static const int keepAlivePeriod = 60;
  static const bool useTls = false;
  
  // Client identifiers
  static const String clientIdentifier = 'smartgym_admin_app_';
  
  // Topics
  static const String sensorDataTopic = "/ua/edu/lb/iot2025/sensordata";
  static const String rfidRegisterTopic = "/ua/edu/lb/iot2025/rfidregister";
  static const String rfidAuthTopic = "/ua/edu/lb/iot2025/rfidauth";
  static const String occupancyTopic = "/ua/edu/lb/iot2025/occupancy";
  
  // QOS Levels
  static const int qosAtMostOnce = 0;
  static const int qosAtLeastOnce = 1;
  static const int qosExactlyOnce = 2;
  
  // Payload fields
  static const String lightSensorField = "lightSensor";
  static const String temperatureField = "temperature";
  static const String humidityField = "humidity";
  static const String motionSensorField = "motionSensor";
  static const String parkingSensorField = "parkingSensor";
  static const String rfidIdField = "rfidId";
  static const String countField = "count";
} 