import 'package:flutter/material.dart';
import 'package:project/services/connectivity_service.dart';

class ConnectivityStatusWidget extends StatefulWidget {
  const ConnectivityStatusWidget({super.key});

  @override
  State<ConnectivityStatusWidget> createState() => _ConnectivityStatusWidgetState();
}

class _ConnectivityStatusWidgetState extends State<ConnectivityStatusWidget> {
  final ConnectivityService _connectivityService = ConnectivityService.instance;
  bool _isOnline = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    // Check connectivity every 30 seconds
    _startPeriodicCheck();
  }

  void _startPeriodicCheck() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _checkConnectivity();
        _startPeriodicCheck();
      }
    });
  }

  Future<void> _checkConnectivity() async {
    try {
      final isOnline = await _connectivityService.isOnline();
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isOnline = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Row(
        children: [
          Text(
            'Vérification...',
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          ),
          const SizedBox(width: 18),
        ],
      );
    }

    return Row(
      children: [
        Text(
          _isOnline ? _isLoading? 'Sychonisation':'En ligne' : 'Hors ligne',
          style: TextStyle(
            color: _isOnline ? _isLoading? Colors.orange : Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 6),
        Icon(
          _isOnline ? _isLoading? Icons.refresh: Icons.wifi : Icons.wifi_off,
          color: _isOnline ? _isLoading? Colors.orange : Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 18),
      ],
    );
  }
}
