import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartgymai/domain/entities/check_in_log.dart';
import 'package:smartgymai/domain/entities/user.dart';
import 'package:smartgymai/providers/repository_providers.dart';
import 'package:smartgymai/providers/sensors_provider.dart';

// State class for activity logs
class ActivitiesState {
  final List<CheckInLog> activities;
  final bool isLoading;
  final String? errorMessage;

  ActivitiesState({
    this.activities = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ActivitiesState copyWith({
    List<CheckInLog>? activities,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ActivitiesState(
      activities: activities ?? this.activities,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// State notifier for activity logs
class ActivitiesNotifier extends StateNotifier<ActivitiesState> {
  final Ref _ref;

  ActivitiesNotifier(this._ref) : super(ActivitiesState()) {
    // Load activities initially
    fetchActivities();
  }

  Future<void> fetchActivities() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final checkInRepository = _ref.read(checkInRepositoryProvider);
      final activities = await checkInRepository.getAllCheckInLogs();
      
      state = state.copyWith(activities: activities, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load activities: ${e.toString()}',
      );
    }
  }

  Future<void> fetchUserActivities(String userId) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final checkInRepository = _ref.read(checkInRepositoryProvider);
      final activities = await checkInRepository.getCheckInLogsByUserId(userId);
      
      state = state.copyWith(activities: activities, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load user activities: ${e.toString()}',
      );
    }
  }

  Future<void> fetchRecentActivities({int limit = 20}) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final checkInRepository = _ref.read(checkInRepositoryProvider);
      final activities = await checkInRepository.getRecentCheckInLogs(limit);
      
      state = state.copyWith(activities: activities, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load recent activities: ${e.toString()}',
      );
    }
  }

  Future<void> fetchActiveCheckIns() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final checkInRepository = _ref.read(checkInRepositoryProvider);
      final activities = await checkInRepository.getActiveCheckIns();
      
      state = state.copyWith(activities: activities, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load active check-ins: ${e.toString()}',
      );
    }
  }

  Future<void> checkInUser(User user) async {
    try {
      final checkInRepository = _ref.read(checkInRepositoryProvider);
      
      // Create a check-in record
      final now = DateTime.now();
      await checkInRepository.addCheckIn(
        CheckInLog(
          userId: user.id,
          checkInTime: now,
        ),
      );
      
      // Refresh activities to update the UI
      await fetchActivities();
      
      // Refresh sensors data to update occupancy information
      await _ref.read(sensorsProvider.notifier).refreshOccupancyData();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to check in user: ${e.toString()}',
      );
    }
  }

  Future<void> checkOutUser(String userId) async {
    try {
      final checkInRepository = _ref.read(checkInRepositoryProvider);
      
      // Check out the user
      final now = DateTime.now();
      await checkInRepository.checkoutUser(userId, now);
      
      // Refresh activities to update the UI
      await fetchActivities();
      
      // Refresh sensors data to update occupancy information
      await _ref.read(sensorsProvider.notifier).refreshOccupancyData();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to check out user: ${e.toString()}',
      );
    }
  }
}

// Provider for the activities state
final activitiesProvider = StateNotifierProvider<ActivitiesNotifier, ActivitiesState>((ref) {
  return ActivitiesNotifier(ref);
}); 