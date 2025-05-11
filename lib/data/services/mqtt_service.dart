import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';

import 'package:smartgymai/core/config/app_config.dart';
import 'package:smartgymai/core/constants/mqtt_constants.dart';
import 'package:smartgymai/data/models/sensor_data_model.dart';

enum MqttConnectionState {
  idle,
  connecting,
  connected,
  disconnected,
  error,
}

class MqttService {
  MqttServerClient? _client;
  final String _identifier;
  final _topicControllers = <String, StreamController<Map<String, dynamic>>>{};
  final StreamController<MqttConnectionState> _connectionStateController = 
      StreamController<MqttConnectionState>.broadcast();
  final Logger _logger = Logger();

  MqttConnectionState _connectionState = MqttConnectionState.idle;
  String? _lastErrorMessage;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  
  // For diagnostics
  String? _lastReceivedTopic;
  String? _lastReceivedPayload;
  DateTime? _lastMessageTime;
  
  String? get lastErrorMessage => _lastErrorMessage;
  String? get lastReceivedTopic => _lastReceivedTopic;
  String? get lastReceivedPayload => _lastReceivedPayload;
  DateTime? get lastMessageTime => _lastMessageTime;
  int get reconnectAttempts => _reconnectAttempts;

  MqttService() : _identifier = 'smartgym_app_${DateTime.now().millisecondsSinceEpoch}';

  Stream<MqttConnectionState> get connectionStateStream => 
      _connectionStateController.stream;

  Stream<Map<String, dynamic>> subscribeTo(String topic) {
    if (!_topicControllers.containsKey(topic)) {
      _topicControllers[topic] = StreamController<Map<String, dynamic>>.broadcast();
      
      if (_connectionState == MqttConnectionState.connected) {
        _subscribeToTopic(topic);
      }
    }
    
    return _topicControllers[topic]!.stream;
  }

  Future<void> connect() async {
    if (_connectionState == MqttConnectionState.connected) return;

    try {
      _updateConnectionState(MqttConnectionState.connecting);
      
      // Get MQTT settings from AppConfig instead of hardcoding
      final mqttHost = AppConfig().mqttServerHost;
      final mqttPort = AppConfig().mqttServerPort;
      
      print('Connecting to MQTT broker at $mqttHost:$mqttPort');
      
      // Generate a unique ID each time to avoid connection conflicts
      final uuid = Uuid();
      final uniqueId = '${MqttConstants.clientIdentifier}${uuid.v4().substring(0, 8)}';
      
      _client = MqttServerClient(mqttHost, uniqueId);
      
      _client!.port = mqttPort;
      _client!.logging(on: true);
      _client!.keepAlivePeriod = 0; // Disable keepalive
      _client!.onConnected = _onConnected;
      _client!.onDisconnected = _onDisconnected;
      _client!.onSubscribed = _onSubscribed;
      _client!.onSubscribeFail = _onSubscribeFail;
      
      // Set connection timeout
      _client!.connectionMessage = MqttConnectMessage()
          .withClientIdentifier(uniqueId)
          .startClean();

      print('Attempting MQTT connection...');
      await _client!.connect();
      print('Connection attempt completed');
      
      if (_client!.connectionStatus!.returnCode == MqttConnectReturnCode.connectionAccepted) {
        print('MQTT connection successful');
        _updateConnectionState(MqttConnectionState.connected);
        _reconnectAttempts = 0;
        _lastErrorMessage = null;
        
        // Subscribe to topics immediately after successful connection
        print('Subscribing to topics...');
        _subscribeToAllTopics();
      } else {
        print('Failed to connect: ${_client!.connectionStatus!.returnCode}');
        throw Exception('Failed to connect: ${_client!.connectionStatus!.returnCode}');
      }
    } catch (e) {
      print('MQTT connection error: $e');
      _lastErrorMessage = 'MQTT Exception: $e';
      _disconnect();
      _updateConnectionState(MqttConnectionState.error);
    }
  }
  
  void _subscribeToAllTopics() {
    print('Subscribing to all topics...');
    // Subscribe to key MQTT topics
    _subscribeToTopic(MqttConstants.sensorDataTopic);
    _subscribeToTopic(MqttConstants.commandsTopic);
    _subscribeToTopic(MqttConstants.rfidRegisterTopic);
    _subscribeToTopic(MqttConstants.memberCardSwipeTopic);
    print('All topics subscribed');
  }

  void _subscribeToTopic(String topic) {
    if (_client?.connectionStatus?.returnCode != MqttConnectReturnCode.connectionAccepted) {
      print('Cannot subscribe to $topic: not connected to MQTT broker');
      return;
    }
    
    print('Subscribing to topic: $topic');
    _client!.subscribe(topic, MqttQos.atLeastOnce);
    
    // Make sure we have a controller for this topic
    if (!_topicControllers.containsKey(topic)) {
      _topicControllers[topic] = StreamController<Map<String, dynamic>>.broadcast();
    }
  }

  void _onConnected() {
    print('MQTT client connected callback');
    _updateConnectionState(MqttConnectionState.connected);
    
    // Start listening for messages
    _client!.updates!.listen(_onMessage);
  }

  void _onDisconnected() {
    _logger.w('MQTT client disconnected');
    _updateConnectionState(MqttConnectionState.disconnected);
    
    // Auto-reconnect if not manually disconnected
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      Future.delayed(Duration(seconds: 2 * _reconnectAttempts), () {
        connect();
      });
    }
  }

  void _onSubscribed(String topic) {
    _logger.i('Subscribed to: $topic');
  }

  void _onSubscribeFail(String topic) {
    _logger.e('Failed to subscribe to: $topic');
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final message in messages) {
      final topic = message.topic;
      final recMess = message.payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      
      print('Received message on topic: $topic');
      print('Raw payload: $payload');
      
      try {
        Map<String, dynamic> data;
        
        if (topic == MqttConstants.sensorDataTopic) {
          try {
            data = json.decode(payload);
            data['timestamp'] = DateTime.now().toIso8601String();
            print('Parsed sensor data: ${json.encode(data)}');
          } catch (e) {
            print('Error parsing sensor data JSON: $e');
            continue;
          }
        } else {
          try {
            data = json.decode(payload);
          } catch (e) {
            data = {
              'value': payload,
              'timestamp': DateTime.now().toIso8601String(),
            };
          }
        }
        
        if (_topicControllers.containsKey(topic)) {
          print('Adding data to topic controller: $topic');
          _topicControllers[topic]!.add(data);
        }
      } catch (e) {
        print('Error processing MQTT message: $e');
      }
    }
  }

  Future<void> publishMessage(String topic, Map<String, dynamic> message) async {
    
    try {
      final builder = MqttClientPayloadBuilder();
      builder.addString(json.encode(message));
      
      _logger.i('Publishing message to $topic: ${json.encode(message)}');
      
      _client!.publishMessage(
        topic, 
        MqttQos.atLeastOnce, 
        builder.payload!,
      );
    } catch (e) {
      _logger.e('Error publishing message: $e');
    }
  }
  
  // Publish a test message to verify the connection
  Future<bool> publishTestMessage() async {
    if (_client?.connectionStatus?.returnCode != MqttConnectReturnCode.connectionAccepted) {
      await connect();
      
      // If still not connected after trying to connect, return failure
      if (_client?.connectionStatus?.returnCode != MqttConnectReturnCode.connectionAccepted) {
        return false;
      }
    }
    
    try {
      final testTopic = 'UA/IOT/test/${_client!.clientIdentifier}';
      final testMessage = {
        'test': true,
        'timestamp': DateTime.now().toIso8601String(),
        'message': 'Connection test from smart gym app',
        'device': kIsWeb ? 'web' : Platform.operatingSystem,
      };
      
      final builder = MqttClientPayloadBuilder();
      builder.addString(json.encode(testMessage));
      
      _client!.publishMessage(
        testTopic, 
        MqttQos.atLeastOnce, 
        builder.payload!,
      );
      
      // Also publish to a well-known topic for easier monitoring
      _client!.publishMessage(
        'UA/IOT/test', 
        MqttQos.atLeastOnce, 
        builder.payload!,
      );
      
      return true;
    } catch (e) {
      _logger.e('Error publishing test message: $e');
      return false;
    }
  }

  void _disconnect() {
    try {
      _client?.disconnect();
    } catch (e) {
      _logger.e('Error disconnecting: $e');
    }
    _client = null;
  }

  void _updateConnectionState(MqttConnectionState state) {
    _connectionState = state;
    _connectionStateController.add(state);
  }
  
  // Get diagnostic information
  Map<String, String> getDiagnosticInfo() {
    final Map<String, String> info = {
      'broker': AppConfig().mqttServerHost,
      'port': AppConfig().mqttServerPort.toString(),
      'connectionState': _connectionState.toString(),
      'clientId': _client?.clientIdentifier ?? 'Not connected',
      'reconnectAttempts': _reconnectAttempts.toString(),
    };
    
    if (_client != null) {
      info['connectionStatus'] = _client!.connectionStatus.toString();
      info['keepAlive'] = _client!.keepAlivePeriod.toString();
      info['connectionCode'] = _client!.connectionStatus?.returnCode.toString() ?? 'Unknown';
    }
    
    if (_lastErrorMessage != null) {
      info['lastError'] = _lastErrorMessage!;
    }
    
    if (_lastReceivedTopic != null) {
      info['lastTopic'] = _lastReceivedTopic!;
      info['lastPayload'] = _lastReceivedPayload ?? 'Empty';
      info['lastMessageTime'] = _lastMessageTime?.toString() ?? 'Never';
    }
    
    return info;
  }
  
  // Test connection by connecting, subscribing to a test topic, and publishing a message
  Future<Map<String, dynamic>> testConnection() async {
    final result = <String, dynamic>{
      'success': false,
      'diagnostics': getDiagnosticInfo(),
    };
    
    try {
      // Disconnect first if already connected
      _disconnect();
      _reconnectAttempts = 0;
      
      // Try to connect
      await connect();
      
      // Use the return code to determine success, not the state
      if (_client?.connectionStatus?.returnCode == MqttConnectReturnCode.connectionAccepted) {
        // Wait a moment to ensure connection is stable
        await Future.delayed(const Duration(seconds: 1));
        
        // Try to publish a test message
        final testTopic = 'UA/IOT/test/${_client!.clientIdentifier}';
        final success = await publishTestMessage();
        
        result['success'] = success;
        result['publishedTestMessage'] = success;
        result['testTopic'] = testTopic;
        result['diagnostics'] = getDiagnosticInfo();
        
        return result;
      } else {
        result['error'] = 'Failed to connect to MQTT broker: ${_client?.connectionStatus?.returnCode}';
        return result;
      }
    } catch (e) {
      result['error'] = 'Test connection failed: $e';
      result['diagnostics'] = getDiagnosticInfo();
      return result;
    }
  }

  Future<void> dispose() async {
    _disconnect();
    
    for (final controller in _topicControllers.values) {
      await controller.close();
    }
    _topicControllers.clear();
    
    await _connectionStateController.close();
  }
} 