import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Connectivity status enum
enum ConnectivityStatus { online, offline }

/// Provider for connectivity status
final connectivityStatusProvider =
    StateNotifierProvider<ConnectivityStatusNotifier, ConnectivityStatus>(
      (ref) => ConnectivityStatusNotifier(),
    );

/// Notifier that monitors network connectivity
class ConnectivityStatusNotifier extends StateNotifier<ConnectivityStatus> {
  late final Connectivity _connectivity;

  ConnectivityStatusNotifier() : super(ConnectivityStatus.online) {
    _connectivity = Connectivity();
    _checkConnectivity();
    _monitorConnectivity();
  }

  /// Check initial connectivity status
  Future<void> _checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _updateConnectionStatus(results);
  }

  /// Monitor connectivity changes
  void _monitorConnectivity() {
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  /// Update connection status based on connectivity results
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet)) {
      state = ConnectivityStatus.online;
    } else {
      state = ConnectivityStatus.offline;
    }
  }

  /// Check if currently online
  bool get isOnline => state == ConnectivityStatus.online;

  /// Check if currently offline
  bool get isOffline => state == ConnectivityStatus.offline;
}
