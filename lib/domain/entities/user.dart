import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String membershipType;
  final DateTime? lastCheckIn;
  final DateTime? lastCheckout;
  final DateTime registrationDate;
  final String? notes;

  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    required this.membershipType,
    this.lastCheckIn,
    this.lastCheckout,
    required this.registrationDate,
    this.notes,
  });

  String get fullName => '$firstName $lastName';

  bool get isCurrentlyCheckedIn => lastCheckIn != null && 
      (lastCheckout == null || lastCheckIn!.isAfter(lastCheckout!));

  @override
  List<Object?> get props => [
    id, firstName, lastName, email, phone, 
    membershipType, lastCheckIn, lastCheckout, 
    registrationDate, notes
  ];
} 