import 'package:smartgymai/domain/entities/check_in_log.dart';

class CheckInLogModel extends CheckInLog {
  const CheckInLogModel({
    super.id,
    required super.userId,
    required super.checkInTime,
    super.checkoutTime,
    super.durationMinutes,
  });

  factory CheckInLogModel.fromJson(Map<String, dynamic> json) {
    return CheckInLogModel(
      id: json['id'] != null ? (json['id'] is String ? int.parse(json['id']) : json['id']) : null,
      userId: json['user_id'] != null ? (json['user_id'] is int ? json['user_id'].toString() : json['user_id']) : '',
      checkInTime: json['check_in_time'] != null 
          ? DateTime.parse(json['check_in_time']) 
          : DateTime.now(),
      checkoutTime: json['checkout_time'] != null 
          ? DateTime.parse(json['checkout_time']) 
          : null,
      durationMinutes: json['duration_minutes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'check_in_time': checkInTime.toIso8601String(),
      'checkout_time': checkoutTime?.toIso8601String(),
      'duration_minutes': durationMinutes,
    };
  }

  factory CheckInLogModel.fromEntity(CheckInLog entity) {
    return CheckInLogModel(
      id: entity.id,
      userId: entity.userId,
      checkInTime: entity.checkInTime,
      checkoutTime: entity.checkoutTime,
      durationMinutes: entity.durationMinutes,
    );
  }
} 