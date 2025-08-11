import 'package:project/models/user_model.dart';

class CurrentUser extends User{
  late final int id;
  //final String password;//for refresh token maybe
  late final token;

  CurrentUser({required this.id, required super.name, required super.email, required this.token});//get from auth

}