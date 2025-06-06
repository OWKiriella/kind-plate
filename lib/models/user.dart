class User {
  final String id;
  final String name;
  final String email;
  final String role;
  
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });
  
  // If you're using JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
    };
  }
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
    );
  }
} 