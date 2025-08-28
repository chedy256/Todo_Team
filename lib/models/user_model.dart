class User {
  final int id;
  final String username,email;
  User({required this.id ,required this.username,required this.email});
  int get getId => id;
  String get getName => username;
  String get getEmail => email;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
        id: json['id'],
        username: json['username'],
        email: json['email']
    );
  }

  // Add a method to convert User to JSON for API requests if needed
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
    };
  }
}
