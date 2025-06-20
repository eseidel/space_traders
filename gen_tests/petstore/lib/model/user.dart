import 'package:meta/meta.dart';

@immutable
class User {
  const User({
    this.id,
    this.username,
    this.firstName,
    this.lastName,
    this.email,
    this.password,
    this.phone,
    this.userStatus,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int?,
      username: json['username'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      email: json['email'] as String?,
      password: json['password'] as String?,
      phone: json['phone'] as String?,
      userStatus: json['userStatus'] as int?,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static User? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return User.fromJson(json);
  }

  final int? id;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? password;
  final String? phone;
  final int? userStatus;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
      'phone': phone,
      'userStatus': userStatus,
    };
  }

  @override
  int get hashCode => Object.hash(
    id,
    username,
    firstName,
    lastName,
    email,
    password,
    phone,
    userStatus,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        id == other.id &&
        username == other.username &&
        firstName == other.firstName &&
        lastName == other.lastName &&
        email == other.email &&
        password == other.password &&
        phone == other.phone &&
        userStatus == other.userStatus;
  }
}
