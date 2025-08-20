class User {
  final int id;
  final String name,email;
  User({required this.id ,required this.name,required this.email});
  int get getId => id;
  String get getName => name;
  String get getEmail => email;
}

// Fallback users list for compatibility
List<User> users = [
  User(id: 1, name: 'Bilel', email: 'bilel@email.com'),
  User(id: 2, name: 'Yacine', email: 'yacine@email.com'),
  User(id: 3, name: 'Mohamed', email: 'mohamed@email.com'),
  User(id: 4, name: 'Samira', email: 'samira@email.com'),
  User(id: 5, name: 'Marwa', email: 'marwa@email.com'),
  User(id: 6, name: 'Ferdaous', email: 'ferdous@email.com'),
  User(id: 7, name: 'Samir', email: 'samir@email.com'),
  User(id: 8, name: 'admin', email: 'admin@email.com'),
];