import 'dart:async';
import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:logger/logger.dart';
import 'package:smartgymai/core/config/app_config.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  
  DatabaseService._internal();
  
  final Logger _logger = Logger();
  PostgreSQLConnection? _connection;
  
  // Get credentials from app_config or use default values from docker-compose
  String get _host {
    // For Android emulator, use 10.0.2.2 to access host machine
    // For iOS simulator, use localhost or 127.0.0.1
    if (kIsWeb) return AppConfig().dbHost;
    
    if (Platform.isAndroid) {
      // Replace localhost/postgres with 10.0.2.2 for Android emulator
      final configHost = AppConfig().dbHost;
      if (configHost == 'postgres' || configHost == 'localhost' || configHost == '127.0.0.1') {
        return '192.168.1.10'; //ipreplacehere
      }
      return configHost;
    }
    
    return AppConfig().dbHost;
  }
  
  int get _port => AppConfig().dbPort; // 5432
  String get _database => AppConfig().dbName; // 'smartgym_db'
  String get _username => AppConfig().dbUser; // 'smartgym'
  String get _password => AppConfig().dbPassword; // 'smartgym123'

  Future<PostgreSQLConnection> get connection async {
    if (_connection != null && !_connection!.isClosed) {
      return _connection!;
    }
    
    await _connect();
    return _connection!;
  }

  Future<void> _connect() async {
    try {
      _logger.i('Connecting to PostgreSQL at $_host:$_port as $_username');
      
      // Close existing connection if open
      if (_connection != null && !_connection!.isClosed) {
        await _connection!.close();
      }
      
      _connection = PostgreSQLConnection(
        _host,
        _port,
        _database,
        username: _username,
        password: _password,
        timeoutInSeconds: 15, // Reduced from 30 to detect issues faster
        queryTimeoutInSeconds: 10,
        timeZone: 'UTC',
        useSSL: false,
      );
      
      // Connect with timeout handling
      await _connection!.open().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException(
            'Connection timed out. Check if database is running and accessible at $_host:$_port\n'
            'For Android emulator, use 10.0.2.2 instead of localhost.',
          );
        },
      );
      
      // Simple test query to verify connection works
      final result = await _connection!.query('SELECT 1 as test');
      _logger.i('Connected to PostgreSQL database. Test query result: ${result.first.first}');
    } on SocketException catch (e) {
      final String errorMsg = 'Socket error connecting to PostgreSQL: ${e.message}\n'
          'Host: $_host, Port: $_port\n'
          'For Android emulator, make sure to use 10.0.2.2 instead of localhost/postgres and that Docker is running.';
      _logger.e(errorMsg);
      throw Exception(errorMsg);
    } on TimeoutException catch (e) {
      _logger.e('Timeout connecting to PostgreSQL: $e');
      rethrow;
    } catch (e) {
      final String errorMsg = 'Failed to connect to PostgreSQL: $e\n'
          'Connection details: $_host:$_port/$_database as $_username\n'
          'Possible solutions:\n'
          '1. Check if Docker containers are running\n'
          '2. For Android emulator, use 10.0.2.2 instead of localhost/postgres\n'
          '3. Verify database credentials in settings';
      _logger.e(errorMsg);
      throw Exception(errorMsg);
    }
  }

  Future<void> close() async {
    if (_connection != null && !_connection!.isClosed) {
      await _connection!.close();
      _logger.i('Closed PostgreSQL connection');
    }
  }

  Future<List<Map<String, dynamic>>> query(
    String sql, {
    Map<String, dynamic>? substitutionValues,
  }) async {
    try {
      final conn = await connection;
      final results = await conn.mappedResultsQuery(
        sql,
        substitutionValues: substitutionValues,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Database query timed out. The database might be overloaded or the query is too complex.');
        },
      );
      
      return results.map((row) {
        // Extract the first (and usually only) table from the result
        final tableName = row.keys.first;
        return row[tableName]!;
      }).toList();
    } on PostgreSQLException catch (e) {
      _logger.e('PostgreSQL query error: $e');
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      _logger.e('PostgreSQL query error: $e');
      rethrow;
    }
  }

  Future<int> execute(
    String sql, {
    Map<String, dynamic>? substitutionValues,
  }) async {
    try {
      final conn = await connection;
      return await conn.execute(
        sql,
        substitutionValues: substitutionValues,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Database execute command timed out.');
        },
      );
    } catch (e) {
      _logger.e('PostgreSQL execute error: $e');
      rethrow;
    }
  }

  Future<T> transaction<T>(Future<T> Function(PostgreSQLExecutionContext) function) async {
    final conn = await connection;
    return await conn.transaction(function);
  }
  
  // Helper method for diagnostics
  Future<Map<String, String>> getDiagnosticInfo() async {
    final Map<String, String> info = {
      'host': _host,
      'port': _port.toString(),
      'database': _database,
      'username': _username,
      'configuredHost': AppConfig().dbHost,
      'platform': kIsWeb ? 'Web' : Platform.operatingSystem,
      'isAndroid': Platform.isAndroid.toString(),
    };
    
    try {
      // Check if we can establish connection
      final conn = await connection.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Connection diagnostic timed out');
        },
      );
      
      info['connectionStatus'] = conn.isClosed ? 'Closed' : 'Open';
      
      // Try a simple query
      try {
        final result = await conn.query('SELECT version()').timeout(
          const Duration(seconds: 3),
        );
        info['serverVersion'] = result.first.first.toString();
        info['connectionSuccessful'] = 'true';
      } catch (e) {
        info['queryError'] = e.toString();
        info['connectionSuccessful'] = 'false';
      }
    } catch (e) {
      info['connectionError'] = e.toString();
      info['connectionSuccessful'] = 'false';
    }
    
    return info;
  }
} 