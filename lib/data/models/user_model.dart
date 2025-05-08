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

  // Helper method to check JSON value existence safely
  static T? _safeGet<T>(Map<String, dynamic> json, String key) {
    try {
      return json.containsKey(key) ? json[key] as T? : null;
    } catch (e) {
      print('Error extracting $key from JSON: $e');
      return null;
    }
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    try {
      // Print the raw JSON for debugging
      print('UserModel.fromJson raw data: $json');
      
      // Safely get values with null checks
      final id = _safeGet<dynamic>(json, 'id');
      final firstName = _safeGet<String>(json, 'first_name') ?? '';
      final lastName = _safeGet<String>(json, 'last_name') ?? '';
      final email = _safeGet<String>(json, 'email');
      final phone = _safeGet<String>(json, 'phone');
      final membershipType = _safeGet<String>(json, 'membership_type') ?? 'Basic';
      final lastCheckInStr = _safeGet<String>(json, 'last_check_in');
      final lastCheckoutStr = _safeGet<String>(json, 'last_checkout');
      final registrationDateStr = _safeGet<String>(json, 'registration_date');
      final notes = _safeGet<String>(json, 'notes');
      
      // Convert ID to string if needed
      final String strId = id == null ? '' : (id is int ? id.toString() : id.toString());
      
      return UserModel(
        id: strId,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        membershipType: membershipType,
        lastCheckIn: lastCheckInStr != null ? DateTime.parse(lastCheckInStr) : null,
        lastCheckout: lastCheckoutStr != null ? DateTime.parse(lastCheckoutStr) : null,
        registrationDate: registrationDateStr != null 
            ? DateTime.parse(registrationDateStr) 
            : DateTime.now(),
        notes: notes,
      );
    } catch (e) {
      print('Exception in UserModel.fromJson: $e');
      // Return a placeholder user model with minimal valid data
      return UserModel(
        id: 'error',
        firstName: 'Error',
        lastName: 'Loading',
        membershipType: 'Basic',
        registrationDate: DateTime.now(),
      );
    }
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