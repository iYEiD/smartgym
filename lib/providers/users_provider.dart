import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartgymai/domain/entities/user.dart';
import 'package:smartgymai/domain/entities/check_in_log.dart';
import 'package:smartgymai/providers/repository_providers.dart';

// State class for users
class UsersState {
  final List<User> users;
  final bool isLoading;
  final String? errorMessage;

  UsersState({
    this.users = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  UsersState copyWith({
    List<User>? users,
    bool? isLoading,
    String? errorMessage,
  }) {
    return UsersState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// State notifier for users
class UsersNotifier extends StateNotifier<UsersState> {
  final Ref _ref;

  UsersNotifier(this._ref) : super(UsersState()) {
    // Load users initially when created
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final userRepository = _ref.read(userRepositoryProvider);
      final users = await userRepository.getAllUsers();
      
      state = state.copyWith(users: users, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false, 
        errorMessage: 'Failed to load users: ${e.toString()}'
      );
    }
  }

  Future<void> checkInUser(String userId) async {
    try {
      final checkInRepository = _ref.read(checkInRepositoryProvider);
      final userRepository = _ref.read(userRepositoryProvider);
      
      // Create a check-in record
      final now = DateTime.now();
      await checkInRepository.addCheckIn(
        // We don't need to provide an ID as it's auto-generated
        // in the database by the SERIAL type
        CheckInLog(
          userId: userId,
          checkInTime: now,
        ),
      );
      
      // Refresh users to update the UI
      await fetchUsers();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to check in user: ${e.toString()}'
      );
    }
  }

  Future<void> checkOutUser(String userId) async {
    try {
      final checkInRepository = _ref.read(checkInRepositoryProvider);
      
      // Check out the user
      final now = DateTime.now();
      await checkInRepository.checkoutUser(userId, now);
      
      // Refresh users to update the UI
      await fetchUsers();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to check out user: ${e.toString()}'
      );
    }
  }

  Future<User?> getUserById(String id) async {
    try {
      final userRepository = _ref.read(userRepositoryProvider);
      return await userRepository.getUserById(id);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to get user: ${e.toString()}'
      );
      return null;
    }
  }

  Future<void> addUser(User user) async {
    try {
      print('Adding user: ${user.id}, ${user.firstName} ${user.lastName}');
      
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final userRepository = _ref.read(userRepositoryProvider);
      await userRepository.addUser(user);
      
      print('User added successfully, fetching updated user list');
      
      // Refresh the list after adding
      final users = await userRepository.getAllUsers();
      
      state = state.copyWith(users: users, isLoading: false);
      print('User list updated: ${users.length} users');
    } catch (e) {
      print('Error adding user: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to add user: ${e.toString()}'
      );
    }
  }

  Future<void> updateUser(User user) async {
    try {
      final userRepository = _ref.read(userRepositoryProvider);
      await userRepository.updateUser(user);
      await fetchUsers(); // Refresh the list
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to update user: ${e.toString()}'
      );
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      final userRepository = _ref.read(userRepositoryProvider);
      await userRepository.deleteUser(id);
      await fetchUsers(); // Refresh the list
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to delete user: ${e.toString()}'
      );
    }
  }
}

// Provider for the users state
final usersProvider = StateNotifierProvider<UsersNotifier, UsersState>((ref) {
  return UsersNotifier(ref);
}); 