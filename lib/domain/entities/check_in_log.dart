import 'package:equatable/equatable.dart';

class CheckInLog extends Equatable {
  final int? id;
  final String userId;
  final DateTime checkInTime;
  final DateTime? checkoutTime;
  final int? durationMinutes;

  const CheckInLog({
    this.id,
    required this.userId,
    required this.checkInTime,
    this.checkoutTime,
    this.durationMinutes,
  });

  bool get isActive => checkoutTime == null;

  CheckInLog copyWith({
    int? id,
    String? userId,
    DateTime? checkInTime,
    DateTime? checkoutTime,
    int? durationMinutes,
  }) {
    return CheckInLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      checkInTime: checkInTime ?? this.checkInTime,
      checkoutTime: checkoutTime ?? this.checkoutTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }

  @override
  List<Object?> get props => [
    id, userId, checkInTime, checkoutTime, durationMinutes
  ];
} 