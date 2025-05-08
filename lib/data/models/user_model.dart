import 'package:smartgymai/domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    super.email,
    super.phone,
    required super.membershipType,
    super.lastCheckIn,
    super.lastCheckout,
    required super.registrationDate,
    super.notes,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'],
      phone: json['phone'],
      membershipType: json['membership_type'],
      lastCheckIn: json['last_check_in'] != null 
          ? DateTime.parse(json['last_check_in']) 
          : null,
      lastCheckout: json['last_checkout'] != null 
          ? DateTime.parse(json['last_checkout']) 
          : null,
      registrationDate: DateTime.parse(json['registration_date']),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'membership_type': membershipType,
      'last_check_in': lastCheckIn?.toIso8601String(),
      'last_checkout': lastCheckout?.toIso8601String(),
      'registration_date': registrationDate.toIso8601String(),
      'notes': notes,
    };
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      firstName: user.firstName,
      lastName: user.lastName,
      email: user.email,
      phone: user.phone,
      membershipType: user.membershipType,
      lastCheckIn: user.lastCheckIn,
      lastCheckout: user.lastCheckout,
      registrationDate: user.registrationDate,
      notes: user.notes,
    );
  }
} 