import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartgymai/domain/entities/sensor_data.dart';
import 'package:smartgymai/domain/entities/occupancy_record.dart';
import 'package:smartgymai/providers/repository_providers.dart';

// State class for sensor data
class SensorsState {
  final SensorData? latestSensorData;
  final OccupancyRecord? latestOccupancy;
  final List<OccupancyRecord> occupancyHistory;
  final bool isLoading;
  final String? errorMessage;

  SensorsState({
    this.latestSensorData,
    this.latestOccupancy,
    this.occupancyHistory = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  SensorsState copyWith({
    SensorData? latestSensorData,
    OccupancyRecord? latestOccupancy,
    List<OccupancyRecord>? occupancyHistory,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SensorsState(
      latestSensorData: latestSensorData ?? this.latestSensorData,
      latestOccupancy: latestOccupancy ?? this.latestOccupancy,
      occupancyHistory: occupancyHistory ?? this.occupancyHistory,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// State notifier for sensor data
class SensorsNotifier extends StateNotifier<SensorsState> {
  final Ref _ref;
  StreamSubscription? _sensorDataSubscription;
  StreamSubscription? _occupancySubscription;

  SensorsNotifier(this._ref) : super(SensorsState()) {
    // Load initial data
    _initialize();
  }

  Future<void> _initialize() async {
    await fetchLatestData();
    await fetchOccupancyHistory();
    _subscribeToRealTimeData();
  }

  void _subscribeToRealTimeData() {
    final sensorRepository = _ref.read(sensorRepositoryProvider);
    
    // Subscribe to sensor data updates
    _sensorDataSubscription = sensorRepository.sensorDataStream.listen(
      (sensorData) {
        state = state.copyWith(latestSensorData: sensorData);
      },
      onError: (error) {
        state = state.copyWith(
          errorMessage: 'Sensor data stream error: ${error.toString()}',
        );
      },
    );
    
    // Subscribe to occupancy updates
    _occupancySubscription = sensorRepository.occupancyStream.listen(
      (occupancy) {
        state = state.copyWith(
          latestOccupancy: occupancy,
          occupancyHistory: [occupancy, ...state.occupancyHistory],
        );
      },
      onError: (error) {
        state = state.copyWith(
          errorMessage: 'Occupancy stream error: ${error.toString()}',
        );
      },
    );
  }

  Future<void> fetchLatestData() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final sensorRepository = _ref.read(sensorRepositoryProvider);
      final latestSensorData = await sensorRepository.getLatestSensorData();
      final latestOccupancy = await sensorRepository.getLatestOccupancy();
      
      state = state.copyWith(
        latestSensorData: latestSensorData,
        latestOccupancy: latestOccupancy,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load latest data: ${e.toString()}',
      );
    }
  }

  Future<void> fetchOccupancyHistory({int days = 1}) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final sensorRepository = _ref.read(sensorRepositoryProvider);
      final now = DateTime.now();
      final start = now.subtract(Duration(days: days));
      
      final records = await sensorRepository.getOccupancyRecords(start, now);
      
      state = state.copyWith(
        occupancyHistory: records,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load occupancy history: ${e.toString()}',
      );
    }
  }

  // Comprehensive method to refresh all occupancy-related data
  Future<void> refreshOccupancyData() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final sensorRepository = _ref.read(sensorRepositoryProvider);
      
      // Get latest occupancy
      final latestOccupancy = await sensorRepository.getLatestOccupancy();
      
      // Get occupancy history
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 1));
      
      List<OccupancyRecord> records = [];
      try {
        records = await sensorRepository.getOccupancyRecords(start, now);
      } catch (historyError) {
        // If there's an error fetching history, continue with empty records
        // rather than failing the entire operation
      }
      
      // Update state with all new data
      state = state.copyWith(
        latestOccupancy: latestOccupancy,
        occupancyHistory: records,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to refresh occupancy data: ${e.toString()}',
      );
    }
  }

  Future<Map<String, dynamic>> getOccupancyAnalytics({int days = 7}) async {
    try {
      final sensorRepository = _ref.read(sensorRepositoryProvider);
      final now = DateTime.now();
      final start = now.subtract(Duration(days: days));
      
      return await sensorRepository.getOccupancyAnalytics(start, now);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to get occupancy analytics: ${e.toString()}',
      );
      return {};
    }
  }

  @override
  void dispose() {
    _sensorDataSubscription?.cancel();
    _occupancySubscription?.cancel();
    super.dispose();
  }
}

// Provider for the sensors state
final sensorsProvider = StateNotifierProvider<SensorsNotifier, SensorsState>((ref) {
  return SensorsNotifier(ref);
}); 