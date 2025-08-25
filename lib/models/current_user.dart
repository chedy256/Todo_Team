import 'package:project/models/user_model.dart';

class CurrentUser extends User{
  final String token;

  CurrentUser({
    required super.id,
    required super.username,
    required super.email,
    required this.token,
  });



  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    return CurrentUser(
      id: json['user']['id'],
      username: json['user']['username'],
      email: json['user']['email'],
      token: json['token'],
    );
  }

  factory CurrentUser.fromAuthResponse(Map<String, dynamic> json,email,username) {
    return CurrentUser(
      id: json['id'],
      token: json['token'],
      email:email,
      username: username,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
    };
  }
}

