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
  
  // Topics - using new structure
  static const String topicPrefix = "UA/IOT/uniqueId";
  static const String sensorDataTopic = "$topicPrefix/sensorData";
  static const String commandsTopic = "$topicPrefix/commands";
  static const String rfidRegisterTopic = "$topicPrefix/registerCard";
  static const String memberCardSwipeTopic = "$topicPrefix/memberCardSwipe";
  
  // QOS Levels
  static const int qosAtMostOnce = 0;
  static const int qosAtLeastOnce = 1;
  static const int qosExactlyOnce = 2;
  
  // Payload fields
  static const String lightField = "light";
  static const String temperatureField = "temperature";
  static const String humidityField = "humidity";
  static const String parkingField = "parking";
  static const String motionField = "motion";
  static const String lightingField = "lighting";
  static const String acField = "ac";
  static const String gateField = "gate";
  static const String rfidIdField = "rfidId";
  static const String countField = "count";
} 