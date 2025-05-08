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
      
      _logger.i('Connecting to MQTT broker at $mqttHost:$mqttPort');
      
      // Generate a unique ID each time to avoid connection conflicts
      final uuid = Uuid();
      final uniqueId = '${MqttConstants.clientIdentifier}${uuid.v4().substring(0, 8)}';
      
      _client = MqttServerClient(mqttHost, uniqueId);
      
      _client!.port = mqttPort;
      _client!.logging(on: true); // Enable logging for debugging
      _client!.keepAlivePeriod = 20;
      _client!.onConnected = _onConnected;
      _client!.onDisconnected = _onDisconnected;
      _client!.onSubscribed = _onSubscribed;
      _client!.onSubscribeFail = _onSubscribeFail;
      _client!.pongCallback = _pong;
      
      // Set connection timeout
      _client!.connectionMessage = MqttConnectMessage()
          .withClientIdentifier(uniqueId)
          .startClean()
          .withWillQos(MqttQos.atLeastOnce)
          .withWillTopic('UA/IOT/clients/$uniqueId/status')
          .withWillMessage('offline')
          .withWillRetain();

      // Connect with timeout
      await _client!.connect().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          _logger.e('MQTT connection timeout');
          throw TimeoutException('Connection to MQTT broker timed out');
        },
      );
      
      // Check the connection result properly - only the returnCode matters
      if (_client!.connectionStatus!.returnCode == MqttConnectReturnCode.connectionAccepted) {
        _logger.i('MQTT connection successful: ${_client!.connectionStatus}');
        _reconnectAttempts = 0;
        _lastErrorMessage = null;
      } else {
        throw Exception('Failed to connect: ${_client!.connectionStatus!.returnCode}');
      }
    } on SocketException catch (e) {
      _lastErrorMessage = 'Network error: ${e.message}';
      _logger.e('MQTT SocketException: $_lastErrorMessage');
      _disconnect();
      _updateConnectionState(MqttConnectionState.error);
    } on TimeoutException catch (e) {
      _lastErrorMessage = 'Connection timeout: ${e.message}';
      _logger.e('MQTT TimeoutException: $_lastErrorMessage');
      _disconnect();
      _updateConnectionState(MqttConnectionState.error);
    } on Exception catch (e) {
      _lastErrorMessage = 'MQTT Exception: $e';
      _logger.e(_lastErrorMessage!);
      _disconnect();
      _updateConnectionState(MqttConnectionState.error);
      
      // Try to reconnect after error
      if (_reconnectAttempts < _maxReconnectAttempts) {
        _reconnectAttempts++;
        _logger.i('Attempting to reconnect: attempt $_reconnectAttempts of $_maxReconnectAttempts');
        Future.delayed(Duration(seconds: 2 * _reconnectAttempts), () {
          connect();
        });
      }
    }

    // Subscribe to predefined topics if connected
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      _subscribeToAllTopics();
    }
  }
  
  void _subscribeToAllTopics() {
    // Subscribe to key MQTT topics
    _subscribeToTopic(MqttConstants.sensorDataTopic);
    _subscribeToTopic(MqttConstants.rfidRegisterTopic);
    _subscribeToTopic(MqttConstants.rfidAuthTopic);
    _subscribeToTopic(MqttConstants.occupancyTopic);
    
    // Subscribe to wildcard topic to catch all messages for debugging
    _subscribeToTopic('UA/IOT/#');
  }

  void _subscribeToTopic(String topic) {
    if (_client?.connectionStatus?.state != MqttConnectionState.connected) return;
    
    _logger.i('Subscribing to topic: $topic');
    _client!.subscribe(topic, MqttQos.atLeastOnce);
    
    // Make sure we have a controller for this topic
    if (!_topicControllers.containsKey(topic)) {
      _topicControllers[topic] = StreamController<Map<String, dynamic>>.broadcast();
    }
  }

  void _onConnected() {
    _logger.i('MQTT client connected');
    _updateConnectionState(MqttConnectionState.connected);
    
    // Subscribe to all tracked topics
    _subscribeToAllTopics();
    
    // Start listening for messages
    _client!.updates!.listen(_onMessage);
    
    // Publish a message to indicate we're online
    try {
      final builder = MqttClientPayloadBuilder();
      builder.addString(json.encode({
        'status': 'online',
        'clientId': _client!.clientIdentifier,
        'timestamp': DateTime.now().toIso8601String(),
      }));
      
      _client!.publishMessage(
        'UA/IOT/clients/${_client!.clientIdentifier}/status',
        MqttQos.atLeastOnce,
        builder.payload!,
        retain: true,
      );
    } catch (e) {
      _logger.e('Error publishing online status: $e');
    }
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

  void _pong() {
    _logger.d('Ping response received');
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final message in messages) {
      final topic = message.topic;
      final recMess = message.payload as MqttPublishMessage;
      final payload = 
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      
      // Update diagnostic info
      _lastReceivedTopic = topic;
      _lastReceivedPayload = payload;
      _lastMessageTime = DateTime.now();
      
      _logger.i('Received message on topic: $topic - $payload');
      
      try {
        // For UA/IOT topics, messages might be simple strings like RFID card IDs
        Map<String, dynamic> data;
        
        if (topic == MqttConstants.rfidRegisterTopic || topic == MqttConstants.rfidAuthTopic) {
          // For RFID topics, the payload might just be a card ID string
          data = {
            MqttConstants.rfidIdField: payload.trim(),
            'timestamp': DateTime.now().toIso8601String(),
          };
        } else {
          // For other topics try to parse as JSON
          try {
            data = json.decode(payload);
          } catch (e) {
            // If not valid JSON, create a simple map with the payload as a value
            data = {
              'value': payload,
              'timestamp': DateTime.now().toIso8601String(),
            };
          }
        }
        
        if (_topicControllers.containsKey(topic)) {
          _topicControllers[topic]!.add(data);
        }
        
        // Also add to wildcard controller if it exists and this isn't already the wildcard
        if (topic != 'UA/IOT/#' && _topicControllers.containsKey('UA/IOT/#')) {
          _topicControllers['UA/IOT/#']!.add({
            'topic': topic,
            ...data,
          });
        }
      } catch (e) {
        _logger.e('Error parsing MQTT message: $e');
      }
    }
  }

  Future<void> publishMessage(String topic, Map<String, dynamic> message) async {
    if (_client?.connectionStatus?.state != MqttConnectionState.connected) {
      await connect();
      
      // If still not connected after trying to connect, return
      if (_client?.connectionStatus?.state != MqttConnectionState.connected) {
        _logger.e('Cannot publish message: not connected to MQTT broker');
        return;
      }
    }
    
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