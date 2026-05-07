class User {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String website;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.website,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as int,
    name: json['name'] as String,
    email: json['email'] as String,
    phone: json['phone'] as String? ?? '',
    website: json['website'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'website': website,
  };

  @override
  String toString() => 'User(id: $id, name: $name, email: $email)';
}
