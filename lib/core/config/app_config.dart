import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  
  AppConfig._internal();
  
  late SharedPreferences _prefs;
  bool _initialized = false;
  
  // Default configuration values
  static const String _mqttServerHostKey = 'mqtt_server_host';
  static const String _mqttServerPortKey = 'mqtt_server_port';
  static const String _mqttUseSecureKey = 'mqtt_use_secure';
  static const String _dbHostKey = 'db_host';
  static const String _dbPortKey = 'db_port';
  static const String _dbNameKey = 'db_name';
  static const String _dbUserKey = 'db_user';
  static const String _dbPasswordKey = 'db_password';
  static const String _dbUseSecureKey = 'db_use_secure';
  static const String _gymNameKey = 'gym_name';
  static const String _gymCapacityKey = 'gym_capacity';
  static const String _dashboardRefreshRateKey = 'dashboard_refresh_rate';
  
  // Default values
  static const String _defaultMqttHost = 'test.mosquitto.org';
  static const int _defaultMqttPort = 1883;
  static const bool _defaultMqttUseSecure = false;
  static const String _defaultDbHost = '192.168.1.10'; // Use 10.0.2.2 to access host from Android emulator, replace with ip
  static const int _defaultDbPort = 5432;
  static const String _defaultDbName = 'smartgym_db';
  static const String _defaultDbUser = 'smartgym';
  static const String _defaultDbPassword = 'smartgym123';
  static const bool _defaultDbUseSecure = false;
  static const String _defaultGymName = 'Smart Gym';
  static const int _defaultGymCapacity = 100;
  static const int _defaultDashboardRefreshRate = 30; // seconds
  
  Future<void> initialize() async {
    if (_initialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
    
    // Set default values if not already set
    await _setDefaultsIfNeeded();
  }
  
  Future<void> _setDefaultsIfNeeded() async {
    // MQTT settings
    if (!_prefs.containsKey(_mqttServerHostKey)) {
      await _prefs.setString(_mqttServerHostKey, _defaultMqttHost);
    }
    
    if (!_prefs.containsKey(_mqttServerPortKey)) {
      await _prefs.setInt(_mqttServerPortKey, _defaultMqttPort);
    }
    
    if (!_prefs.containsKey(_mqttUseSecureKey)) {
      await _prefs.setBool(_mqttUseSecureKey, _defaultMqttUseSecure);
    }
    
    // Database settings
    if (!_prefs.containsKey(_dbHostKey)) {
      await _prefs.setString(_dbHostKey, _defaultDbHost);
    }
    
    if (!_prefs.containsKey(_dbPortKey)) {
      await _prefs.setInt(_dbPortKey, _defaultDbPort);
    }
    
    if (!_prefs.containsKey(_dbNameKey)) {
      await _prefs.setString(_dbNameKey, _defaultDbName);
    }
    
    if (!_prefs.containsKey(_dbUserKey)) {
      await _prefs.setString(_dbUserKey, _defaultDbUser);
    }
    
    if (!_prefs.containsKey(_dbPasswordKey)) {
      await _prefs.setString(_dbPasswordKey, _defaultDbPassword);
    }
    
    if (!_prefs.containsKey(_dbUseSecureKey)) {
      await _prefs.setBool(_dbUseSecureKey, _defaultDbUseSecure);
    }
    
    // Gym settings
    if (!_prefs.containsKey(_gymNameKey)) {
      await _prefs.setString(_gymNameKey, _defaultGymName);
    }
    
    if (!_prefs.containsKey(_gymCapacityKey)) {
      await _prefs.setInt(_gymCapacityKey, _defaultGymCapacity);
    }
    
    // App settings
    if (!_prefs.containsKey(_dashboardRefreshRateKey)) {
      await _prefs.setInt(_dashboardRefreshRateKey, _defaultDashboardRefreshRate);
    }
  }
  
  // MQTT getters and setters
  String get mqttServerHost => _prefs.getString(_mqttServerHostKey) ?? _defaultMqttHost;
  Future<void> setMqttServerHost(String host) async => await _prefs.setString(_mqttServerHostKey, host);
  
  int get mqttServerPort => _prefs.getInt(_mqttServerPortKey) ?? _defaultMqttPort;
  Future<void> setMqttServerPort(int port) async => await _prefs.setInt(_mqttServerPortKey, port);
  
  bool get mqttUseSecure => _prefs.getBool(_mqttUseSecureKey) ?? _defaultMqttUseSecure;
  Future<void> setMqttUseSecure(bool useSecure) async => await _prefs.setBool(_mqttUseSecureKey, useSecure);
  
  // Database getters and setters
  String get dbHost => _prefs.getString(_dbHostKey) ?? _defaultDbHost;
  Future<void> setDbHost(String host) async => await _prefs.setString(_dbHostKey, host);
  
  int get dbPort => _prefs.getInt(_dbPortKey) ?? _defaultDbPort;
  Future<void> setDbPort(int port) async => await _prefs.setInt(_dbPortKey, port);
  
  String get dbName => _prefs.getString(_dbNameKey) ?? _defaultDbName;
  Future<void> setDbName(String name) async => await _prefs.setString(_dbNameKey, name);
  
  String get dbUser => _prefs.getString(_dbUserKey) ?? _defaultDbUser;
  Future<void> setDbUser(String user) async => await _prefs.setString(_dbUserKey, user);
  
  String get dbPassword => _prefs.getString(_dbPasswordKey) ?? _defaultDbPassword;
  Future<void> setDbPassword(String password) async => await _prefs.setString(_dbPasswordKey, password);
  
  bool get dbUseSecure => _prefs.getBool(_dbUseSecureKey) ?? _defaultDbUseSecure;
  Future<void> setDbUseSecure(bool useSecure) async => await _prefs.setBool(_dbUseSecureKey, useSecure);
  
  // Gym settings getters and setters
  String get gymName => _prefs.getString(_gymNameKey) ?? _defaultGymName;
  Future<void> setGymName(String name) async => await _prefs.setString(_gymNameKey, name);
  
  int get gymCapacity => _prefs.getInt(_gymCapacityKey) ?? _defaultGymCapacity;
  Future<void> setGymCapacity(int capacity) async => await _prefs.setInt(_gymCapacityKey, capacity);
  
  // App settings getters and setters
  int get dashboardRefreshRate => _prefs.getInt(_dashboardRefreshRateKey) ?? _defaultDashboardRefreshRate;
  Future<void> setDashboardRefreshRate(int rate) async => await _prefs.setInt(_dashboardRefreshRateKey, rate);
  
  // Reset all settings to defaults
  Future<void> resetToDefaults() async {
    await _prefs.remove(_mqttServerHostKey);
    await _prefs.remove(_mqttServerPortKey);
    await _prefs.remove(_mqttUseSecureKey);
    await _prefs.remove(_dbHostKey);
    await _prefs.remove(_dbPortKey);
    await _prefs.remove(_dbNameKey);
    await _prefs.remove(_dbUserKey);
    await _prefs.remove(_dbPasswordKey);
    await _prefs.remove(_dbUseSecureKey);
    await _prefs.remove(_gymNameKey);
    await _prefs.remove(_gymCapacityKey);
    await _prefs.remove(_dashboardRefreshRateKey);
    
    await _setDefaultsIfNeeded();
  }
} 