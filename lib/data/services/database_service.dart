import 'dart:async';
import 'package:postgres/postgres.dart';
import 'package:logger/logger.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  
  DatabaseService._internal();
  
  final Logger _logger = Logger();
  PostgreSQLConnection? _connection;
  
  final String _host = 'localhost'; // Change to your Postgres server address
  final int _port = 5432;
  final String _database = 'smartgym_db';
  final String _username = 'smartgym';
  final String _password = 'smartgym123';

  Future<PostgreSQLConnection> get connection async {
    if (_connection != null && !_connection!.isClosed) {
      return _connection!;
    }
    
    await _connect();
    return _connection!;
  }

  Future<void> _connect() async {
    try {
      _connection = PostgreSQLConnection(
        _host,
        _port,
        _database,
        username: _username,
        password: _password,
        timeoutInSeconds: 30,
        queryTimeoutInSeconds: 30,
        timeZone: 'UTC',
        useSSL: false,
      );
      
      await _connection!.open();
      _logger.i('Connected to PostgreSQL database');
    } catch (e) {
      _logger.e('Failed to connect to PostgreSQL database: $e');
      rethrow;
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
      );
      
      return results.map((row) {
        // Extract the first (and usually only) table from the result
        final tableName = row.keys.first;
        return row[tableName]!;
      }).toList();
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
} 