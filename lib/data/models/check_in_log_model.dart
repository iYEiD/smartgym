import 'package:smartgymai/domain/entities/check_in_log.dart';

class CheckInLogModel extends CheckInLog {
  final String? firstName;
  final String? lastName;
  final String? membershipType;

  const CheckInLogModel({
    super.id,
    required super.userId,
    required super.checkInTime,
    super.checkoutTime,
    super.durationMinutes,
    this.firstName,
    this.lastName,
    this.membershipType,
  });

  factory CheckInLogModel.fromJson(Map<String, dynamic> json) {
    // Debug print to see what's coming in
    // print('CheckInLogModel.fromJson: $json');
    
    return CheckInLogModel(
      id: json['id'] != null ? (json['id'] is String ? int.parse(json['id']) : json['id']) : null,
      userId: json['user_id'] != null ? (json['user_id'] is int ? json['user_id'].toString() : json['user_id']) : '',
      checkInTime: json['check_in_time'] != null 
          ? DateTime.parse(json['check_in_time']) 
          : DateTime.now(),
      checkoutTime: json['check_out_time'] != null 
          ? DateTime.parse(json['check_out_time']) 
          : null,
      durationMinutes: json['duration_minutes'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      membershipType: json['membership_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'check_in_time': checkInTime.toIso8601String(),
      'check_out_time': checkoutTime?.toIso8601String(),
      'duration_minutes': durationMinutes,
      'first_name': firstName,
      'last_name': lastName,
      'membership_type': membershipType,
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
  
  String get fullName => (firstName != null && lastName != null) 
      ? '$firstName $lastName' 
      : 'Unknown User';
} 