import 'package:smartgymai/domain/entities/check_in_log.dart';

abstract class CheckInRepository {
  Future<List<CheckInLog>> getAllCheckInLogs();
  Future<List<CheckInLog>> getCheckInLogsByUserId(String userId);
  Future<List<CheckInLog>> getRecentCheckInLogs(int limit);
  Future<List<CheckInLog>> getActiveCheckIns();
  Future<void> addCheckIn(CheckInLog checkIn);
  Future<void> updateCheckIn(CheckInLog checkIn);
  Future<void> checkoutUser(String userId, DateTime checkoutTime);
} 