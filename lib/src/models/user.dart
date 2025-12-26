import 'dart:convert';

class User {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
  });
  
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? avatar,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
    };
  }
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatar: json['avatar'] as String?,
    );
  }
  
  String toJsonString() => jsonEncode(toJson());
  
  factory User.fromJsonString(String source) => 
      User.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
