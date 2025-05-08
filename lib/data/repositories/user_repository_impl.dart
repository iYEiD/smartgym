import 'package:uuid/uuid.dart';
import 'package:smartgymai/data/models/user_model.dart';
import 'package:smartgymai/data/services/database_service.dart';
import 'package:smartgymai/domain/entities/user.dart';
import 'package:smartgymai/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final DatabaseService _databaseService;

  UserRepositoryImpl(this._databaseService);

  @override
  Future<List<User>> getAllUsers() async {
    try {
      final results = await _databaseService.query(
        'SELECT * FROM users ORDER BY last_name, first_name',
      );
      
      print('User query results count: ${results.length}');
      
      // Debug each result to find nulls
      List<User> users = [];
      for (var i = 0; i < results.length; i++) {
        final data = results[i];
        print('Processing user $i: id=${data['id']}, firstName=${data['first_name']}, lastName=${data['last_name']}');
        try {
          final user = UserModel.fromJson(data);
          users.add(user);
        } catch (e) {
          print('Error processing user at index $i: $e');
          print('Raw data: $data');
        }
      }
      
      return users;
    } catch (e) {
      print('Error in getAllUsers: $e');
      rethrow;
    }
  }

  @override
  Future<User?> getUserById(String id) async {
    final results = await _databaseService.query(
      'SELECT * FROM users WHERE id = @id',
      substitutionValues: {'id': id},
    );
    
    if (results.isEmpty) {
      return null;
    }
    
    return UserModel.fromJson(results.first);
  }

  @override
  Future<void> addUser(User user) async {
    final userModel = user is UserModel 
        ? user 
        : UserModel.fromEntity(user);
    
    final userId = user.id.isEmpty ? const Uuid().v4() : user.id;
    
    await _databaseService.execute(
      '''
      INSERT INTO users (
        id, first_name, last_name, email, phone, 
        membership_type, last_check_in, last_checkout, 
        registration_date, notes
      ) VALUES (
        @id, @first_name, @last_name, @email, @phone, 
        @membership_type, @last_check_in, @last_checkout, 
        @registration_date, @notes
      )
      ''',
      substitutionValues: {
        'id': userId,
        'first_name': userModel.firstName,
        'last_name': userModel.lastName,
        'email': userModel.email,
        'phone': userModel.phone,
        'membership_type': userModel.membershipType,
        'last_check_in': userModel.lastCheckIn?.toIso8601String(),
        'last_checkout': userModel.lastCheckout?.toIso8601String(),
        'registration_date': userModel.registrationDate.toIso8601String(),
        'notes': userModel.notes,
      },
    );
  }

  @override
  Future<void> updateUser(User user) async {
    final userModel = user is UserModel 
        ? user 
        : UserModel.fromEntity(user);
    
    await _databaseService.execute(
      '''
      UPDATE users SET
        first_name = @first_name,
        last_name = @last_name,
        email = @email,
        phone = @phone,
        membership_type = @membership_type,
        last_check_in = @last_check_in,
        last_checkout = @last_checkout,
        notes = @notes
      WHERE id = @id
      ''',
      substitutionValues: {
        'id': userModel.id,
        'first_name': userModel.firstName,
        'last_name': userModel.lastName,
        'email': userModel.email,
        'phone': userModel.phone,
        'membership_type': userModel.membershipType,
        'last_check_in': userModel.lastCheckIn?.toIso8601String(),
        'last_checkout': userModel.lastCheckout?.toIso8601String(),
        'notes': userModel.notes,
      },
    );
  }

  @override
  Future<void> deleteUser(String id) async {
    await _databaseService.execute(
      'DELETE FROM users WHERE id = @id',
      substitutionValues: {'id': id},
    );
  }

  @override
  Future<User?> getUserByRfid(String rfidId) async {
    // Assuming the RFID ID is stored in the user's ID field
    // In a real app, you might have a separate field for RFID
    final results = await _databaseService.query(
      'SELECT * FROM users WHERE id = @rfid_id',
      substitutionValues: {'rfid_id': rfidId},
    );
    
    if (results.isEmpty) {
      return null;
    }
    
    return UserModel.fromJson(results.first);
  }

  @override
  Future<bool> rfidExists(String rfidId) async {
    final user = await getUserByRfid(rfidId);
    return user != null;
  }
} 