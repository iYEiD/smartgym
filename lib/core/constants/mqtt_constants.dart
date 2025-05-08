class MqttConstants {
  // Server configuration
  static const String serverHost = 'test.mosquitto.org';
  static const int serverPort = 1883;
  static const int secureServerPort = 8883;
  static const bool useWebSocket = false;
  static const int webSocketPort = 8884;
  static const int keepAlivePeriod = 20;
  static const bool useTls = false;
  
  // Client identifiers
  static const String clientIdentifier = 'smartgym_app_';
  
  // Topics
  static const String sensorDataTopic = "UA/IOT/sensorData";
  static const String rfidRegisterTopic = "UA/IOT/registerCard";
  static const String rfidAuthTopic = "UA/IOT/authCard";
  static const String occupancyTopic = "UA/IOT/occupancy";
  
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