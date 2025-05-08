import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:uuid/uuid.dart';

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

  MqttConnectionState _connectionState = MqttConnectionState.idle;

  MqttService() : _identifier = MqttConstants.clientIdentifier + const Uuid().v4();

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
      
      _client = MqttServerClient.withPort(
        MqttConstants.serverHost, 
        _identifier, 
        MqttConstants.serverPort,
      );
      
      _client!.logging(on: kDebugMode);
      _client!.keepAlivePeriod = MqttConstants.keepAlivePeriod;
      _client!.onConnected = _onConnected;
      _client!.onDisconnected = _onDisconnected;
      _client!.onSubscribed = _onSubscribed;
      _client!.onSubscribeFail = _onSubscribeFail;
      _client!.pongCallback = _pong;

      final connMessage = MqttConnectMessage()
          .withClientIdentifier(_identifier)
          .withWillQos(MqttQos.atLeastOnce)
          .startClean()
          .withWillRetain()
          .keepAliveFor(MqttConstants.keepAlivePeriod);
      
      _client!.connectionMessage = connMessage;

      await _client!.connect();
    } on SocketException catch (e) {
      print('MQTT SocketException: $e');
      _disconnect();
      _updateConnectionState(MqttConnectionState.error);
    } on Exception catch (e) {
      print('MQTT Exception: $e');
      _disconnect();
      _updateConnectionState(MqttConnectionState.error);
    }

    // Subscribe to predefined topics
    if (_client!.connectionStatus?.state == MqttConnectionState.connected) {
      _subscribeToTopic(MqttConstants.sensorDataTopic);
      _subscribeToTopic(MqttConstants.rfidRegisterTopic);
      _subscribeToTopic(MqttConstants.occupancyTopic);
    }
  }

  void _subscribeToTopic(String topic) {
    if (_client?.connectionStatus?.state != MqttConnectionState.connected) return;

    _client!.subscribe(topic, MqttQos.atLeastOnce);
  }

  void _onConnected() {
    _updateConnectionState(MqttConnectionState.connected);
    
    // Subscribe to all tracked topics
    for (final topic in _topicControllers.keys) {
      _subscribeToTopic(topic);
    }
    
    _client!.updates!.listen(_onMessage);
  }

  void _onDisconnected() {
    _updateConnectionState(MqttConnectionState.disconnected);
    _disconnect();
  }

  void _onSubscribed(String topic) {
    print('Subscribed to: $topic');
  }

  void _onSubscribeFail(String topic) {
    print('Failed to subscribe to: $topic');
  }

  void _pong() {
    print('Ping response received');
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final message in messages) {
      final topic = message.topic;
      final recMess = message.payload as MqttPublishMessage;
      final payload = 
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      
      try {
        final Map<String, dynamic> data = json.decode(payload);
        if (_topicControllers.containsKey(topic)) {
          _topicControllers[topic]!.add(data);
        }
      } catch (e) {
        print('Error parsing MQTT message: $e');
      }
    }
  }

  Future<void> publishMessage(String topic, Map<String, dynamic> message) async {
    if (_client?.connectionStatus?.state != MqttConnectionState.connected) {
      await connect();
    }
    
    final builder = MqttClientPayloadBuilder();
    builder.addString(json.encode(message));
    
    _client!.publishMessage(
      topic, 
      MqttQos.atLeastOnce, 
      builder.payload!,
    );
  }

  void _disconnect() {
    _client?.disconnect();
    _client = null;
  }

  void _updateConnectionState(MqttConnectionState state) {
    _connectionState = state;
    _connectionStateController.add(state);
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