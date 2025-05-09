import 'package:smartgymai/data/models/check_in_log_model.dart';
import 'package:smartgymai/data/services/database_service.dart';
import 'package:smartgymai/domain/entities/check_in_log.dart';
import 'package:smartgymai/domain/repositories/check_in_repository.dart';

class CheckInRepositoryImpl implements CheckInRepository {
  final DatabaseService _databaseService;

  CheckInRepositoryImpl(this._databaseService);

  @override
  Future<List<CheckInLog>> getAllCheckInLogs() async {
    final results = await _databaseService.query(
      '''
      SELECT cl.*,
        u.first_name, u.last_name, u.membership_type, u.id as user_id
      FROM check_in_logs cl
      LEFT JOIN users u ON cl.user_id = u.id
      ORDER BY cl.check_in_time DESC
      ''',
    );
    
    return results.map((data) => CheckInLogModel.fromJson(data)).toList();
  }

  @override
  Future<List<CheckInLog>> getCheckInLogsByUserId(String userId) async {
    final results = await _databaseService.query(
      '''
      SELECT * FROM check_in_logs 
      WHERE user_id = @user_id
      ORDER BY check_in_time DESC
      ''',
      substitutionValues: {'user_id': userId},
    );
    
    return results.map((data) => CheckInLogModel.fromJson(data)).toList();
  }

  @override
  Future<List<CheckInLog>> getRecentCheckInLogs(int limit) async {
    final results = await _databaseService.query(
      '''
      SELECT cl.*,
        u.first_name, u.last_name, u.membership_type, u.id as user_id
      FROM check_in_logs cl
      LEFT JOIN users u ON cl.user_id = u.id
      ORDER BY cl.check_in_time DESC
      LIMIT @limit
      ''',
      substitutionValues: {'limit': limit},
    );
    
    return results.map((data) => CheckInLogModel.fromJson(data)).toList();
  }

  @override
  Future<List<CheckInLog>> getActiveCheckIns() async {
    final results = await _databaseService.query(
      '''
      SELECT cl.*,
        u.first_name, u.last_name, u.membership_type, u.id as user_id
      FROM check_in_logs cl
      LEFT JOIN users u ON cl.user_id = u.id
      WHERE cl.check_out_time IS NULL
      ORDER BY cl.check_in_time DESC
      ''',
    );
    
    return results.map((data) => CheckInLogModel.fromJson(data)).toList();
  }

  @override
  Future<void> addCheckIn(CheckInLog checkIn) async {
    final checkInModel = checkIn is CheckInLogModel
        ? checkIn
        : CheckInLogModel.fromEntity(checkIn);
    
    await _databaseService.execute(
      '''
      INSERT INTO check_in_logs (
        user_id, check_in_time, check_out_time, duration_minutes
      ) VALUES (
        @user_id, @check_in_time, @check_out_time, @duration_minutes
      )
      ''',
      substitutionValues: {
        'user_id': checkInModel.userId,
        'check_in_time': checkInModel.checkInTime.toIso8601String(),
        'check_out_time': checkInModel.checkoutTime?.toIso8601String(),
        'duration_minutes': checkInModel.durationMinutes,
      },
    );
    
    // Update the user's last check-in time
    await _databaseService.execute(
      '''
      UPDATE users 
      SET last_check_in = @check_in_time
      WHERE id = @user_id
      ''',
      substitutionValues: {
        'user_id': checkInModel.userId,
        'check_in_time': checkInModel.checkInTime.toIso8601String(),
      },
    );
  }

  @override
  Future<void> updateCheckIn(CheckInLog checkIn) async {
    final checkInModel = checkIn is CheckInLogModel
        ? checkIn
        : CheckInLogModel.fromEntity(checkIn);
    
    await _databaseService.execute(
      '''
      UPDATE check_in_logs 
      SET check_out_time = @check_out_time,
          duration_minutes = @duration_minutes
      WHERE id = @id
      ''',
      substitutionValues: {
        'id': checkInModel.id,
        'check_out_time': checkInModel.checkoutTime?.toIso8601String(),
        'duration_minutes': checkInModel.durationMinutes,
      },
    );
  }

  @override
  Future<void> checkoutUser(String userId, DateTime checkoutTime) async {
    // Find the most recent active check-in for this user
    final activeCheckIns = await _databaseService.query(
      '''
      SELECT * FROM check_in_logs 
      WHERE user_id = @user_id 
        AND check_out_time IS NULL
      ORDER BY check_in_time DESC
      LIMIT 1
      ''',
      substitutionValues: {'user_id': userId},
    );
    
    if (activeCheckIns.isEmpty) {
      return; // No active check-in found
    }
    
    final checkIn = CheckInLogModel.fromJson(activeCheckIns.first);
    final durationMinutes = checkoutTime.difference(checkIn.checkInTime).inMinutes;
    
    // Update the check-in record
    await _databaseService.execute(
      '''
      UPDATE check_in_logs 
      SET check_out_time = @check_out_time,
          duration_minutes = @duration_minutes
      WHERE id = @id
      ''',
      substitutionValues: {
        'id': checkIn.id,
        'check_out_time': checkoutTime.toIso8601String(),
        'duration_minutes': durationMinutes,
      },
    );
    
    // Update the user's last checkout time
    await _databaseService.execute(
      '''
      UPDATE users 
      SET last_checkout = @check_out_time
      WHERE id = @user_id
      ''',
      substitutionValues: {
        'user_id': userId,
        'check_out_time': checkoutTime.toIso8601String(),
      },
    );
  }
} 