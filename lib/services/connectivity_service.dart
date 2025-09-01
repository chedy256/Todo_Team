import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:project/models/api_model.dart';
import 'package:project/services/online_service.dart';

class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._constructor();
  ConnectivityService._constructor();

  // connectivity check by pinging 8.8.8.8
  Future<bool> canReachInternet() async {
    try {
      final result = await InternetAddress.lookup('8.8.8.8');
      return result.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  /// Check if the API server is reachable
  Future<bool> isServerReachable() async {
    try {
      final uri = Uri.parse("${ApiService.baseUrl}/${ApiModel.status}");
      final socket = await Socket.connect(uri.host, uri.port, timeout: Duration(seconds: 15));
      socket.destroy();
      return true;
    } catch (e) {
      debugPrint('Server unreachable: $e');
      return false;
    }
  }

  /// Comprehensive connectivity check
  Future<bool> isOnline() async {
    final canReach = await canReachInternet();
    if (!canReach) return false;

    final serverReachable = await isServerReachable();
    return serverReachable;
  }
}
