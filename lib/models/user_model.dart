class User {
  final int id;
  final String username,email;
  User({required this.id ,required this.username,required this.email});
  int get getId => id;
  String get getName => username;
  String get getEmail => email;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
        id: json['user']['id'],
        username: json['user']['username'],
        email: json['user']['email']
    );
  }
}

// Fallback users list for compatibility
List<User> users = [
  User(id: 1, username: 'Bilel', email: 'bilel@email.com'),
  User(id: 2, username: 'Yacine', email: 'yacine@email.com'),
  User(id: 3, username: 'Mohamed', email: 'mohamed@email.com'),
  User(id: 4, username: 'Samira', email: 'samira@email.com'),
  User(id: 5, username: 'Marwa', email: 'marwa@email.com'),
  User(id: 6, username: 'Ferdaous', email: 'ferdous@email.com'),
  User(id: 7, username: 'Samir', email: 'samir@email.com'),
  User(id: 8, username: 'admin', email: 'admin@email.com'),
];