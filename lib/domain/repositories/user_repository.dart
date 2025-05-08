import 'package:smartgymai/domain/entities/user.dart';

abstract class UserRepository {
  Future<List<User>> getAllUsers();
  Future<User?> getUserById(String id);
  Future<void> addUser(User user);
  Future<void> updateUser(User user);
  Future<void> deleteUser(String id);
  Future<User?> getUserByRfid(String rfidId);
  Future<bool> rfidExists(String rfidId);
} 