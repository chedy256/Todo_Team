import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/current_user.dart';

class SecureStorage {
  static final SecureStorage instance = SecureStorage._constructor();
  SecureStorage._constructor();

  final FlutterSecureStorage storage = FlutterSecureStorage(
    aOptions: const AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> writeCurrentUser(CurrentUser user) async {
    await storage.write(
      key: 'currentUser',
      value: '${user.id},${user.name},${user.email},${user.token}',
    );
  }
  // This function can be used to retrieve the current user from secure storage
  readCurrentUser() async{
    final value = await storage.read(key: 'currentUser');
    if (value != null) {
      final userData = value.split(',');
      return CurrentUser(
        id: int.parse(userData[0]),
        name: userData[1],
        email: userData[2],
        token: int.parse(userData[3]),
      );
    } else {
      return null;
    }
  }
  Future<void> deleteCurrentUser() async {
    await storage.delete(key: 'currentUser');
  }
}