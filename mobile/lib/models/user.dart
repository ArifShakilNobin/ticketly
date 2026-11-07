import '../utils/json_read.dart';

/// The signed-in passenger.
class User {
  const User({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.createdAt,
  });

  final String id;
  final String name;
  final String phone;
  final String? email;
  final DateTime? createdAt;

  factory User.fromJson(Map<String, dynamic>? json) {
    final data = asMap(json);
    return User(
      id: stringOr(data['id'], ''),
      name: stringOr(data['name'], ''),
      phone: stringOr(data['phone'], ''),
      email: stringOrNull(data['email']),
      createdAt: dateTimeOrNull(data['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };
}
