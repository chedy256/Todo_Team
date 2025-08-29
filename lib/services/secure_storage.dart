import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static final SecureStorage instance = SecureStorage._constructor();
  SecureStorage._constructor();

  final FlutterSecureStorage storage = FlutterSecureStorage(
    aOptions: const AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> writeToken(String token) async {
    await storage.write(
      key: 'token',
      value: token,
    );
    await storage.write(
      key: 'expiry',
      value: DateTime.now().add(Duration(hours: 12)).toIso8601String(),
    );
  }
  Future <String?> readToken() async{
    final String? value = await storage.read(key: 'token');
    if (value != null) {
      return value;
    } else {
      return null;
    }
  }
  Future <String?> readExpiry() async{
    final String? value = await storage.read(key: 'expiry');
    if (value != null) {
      return value;
    } else {
      return null;
    }
  }
  Future<void> deleteToken() async {
    await storage.delete(key: 'token');
    await storage.delete(key: 'expiry');
  }
}