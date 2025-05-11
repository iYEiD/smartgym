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
    
    // Handle ID which could be String, int or null
    int? id;
    if (json['id'] != null) {
      id = json['id'] is String ? int.parse(json['id']) : json['id'] as int;
    }
    
    // Handle user_id which could be String, int or null
    String userId = '';
    if (json['user_id'] != null) {
      userId = json['user_id'] is int ? json['user_id'].toString() : json['user_id'] as String;
    }
    
    // Handle check_in_time which could be String or DateTime
    DateTime checkInTime;
    final checkInTimeRaw = json['check_in_time'];
    if (checkInTimeRaw is DateTime) {
      checkInTime = checkInTimeRaw;
    } else if (checkInTimeRaw is String) {
      checkInTime = DateTime.parse(checkInTimeRaw);
    } else {
      checkInTime = DateTime.now();
    }
    
    // Handle check_out_time which could be String or DateTime
    DateTime? checkoutTime;
    final checkoutTimeRaw = json['check_out_time'] ?? json['checkout_time']; // Handle both column names
    if (checkoutTimeRaw is DateTime) {
      checkoutTime = checkoutTimeRaw;
    } else if (checkoutTimeRaw is String) {
      checkoutTime = DateTime.parse(checkoutTimeRaw);
    }
    
    return CheckInLogModel(
      id: id,
      userId: userId,
      checkInTime: checkInTime,
      checkoutTime: checkoutTime,
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