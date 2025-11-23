import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../presentation/providers/user_presence_provider.dart';

/// Service for managing user presence based on app lifecycle
class PresenceService with WidgetsBindingObserver {
  final Ref ref;
  final String userId;
  Timer? _heartbeatTimer;
  bool _isInitialized = false;

  PresenceService({required this.ref, required this.userId});

  /// Initialize presence tracking
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Set up lifecycle observer
      WidgetsBinding.instance.addObserver(this);

      // Initialize presence as online
      await ref.read(userPresenceRepositoryProvider).initializePresence(userId);

      // Start heartbeat timer to update lastSeen every 30 seconds
      _startHeartbeat();

      _isInitialized = true;
      debugPrint('✅ Presence service initialized for user: $userId');
    } catch (e) {
      debugPrint('❌ Failed to initialize presence service: $e');
    }
  }

  /// Clean up presence tracking
  Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      // Remove lifecycle observer
      WidgetsBinding.instance.removeObserver(this);

      // Stop heartbeat timer
      _stopHeartbeat();

      // Set user as offline
      await ref.read(userPresenceRepositoryProvider).cleanupPresence(userId);

      _isInitialized = false;
      debugPrint('✅ Presence service disposed for user: $userId');
    } catch (e) {
      debugPrint('❌ Failed to dispose presence service: $e');
    }
  }

  /// Handle app lifecycle state changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App is in foreground - set user as online
        _setPresenceStatus('online');
        _startHeartbeat();
        break;

      case AppLifecycleState.paused:
        // App is in background - set user as away
        _setPresenceStatus('away');
        _stopHeartbeat();
        break;

      case AppLifecycleState.inactive:
        // App is inactive (e.g., during phone call) - keep current status
        break;

      case AppLifecycleState.detached:
        // App is detached - set user as offline
        _setPresenceStatus('offline');
        _stopHeartbeat();
        break;

      case AppLifecycleState.hidden:
        // App is hidden - set user as away
        _setPresenceStatus('away');
        break;
    }
  }

  /// Set presence status
  Future<void> _setPresenceStatus(String status) async {
    try {
      await ref
          .read(userPresenceRepositoryProvider)
          .updatePresenceStatus(userId, status);
      debugPrint('🟢 User presence updated: $status');
    } catch (e) {
      debugPrint('❌ Failed to update presence status: $e');
    }
  }

  /// Start heartbeat timer to periodically update lastSeen
  void _startHeartbeat() {
    _stopHeartbeat(); // Stop existing timer if any

    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateLastSeen();
    });
  }

  /// Stop heartbeat timer
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Update last seen timestamp
  Future<void> _updateLastSeen() async {
    try {
      await ref.read(userPresenceRepositoryProvider).updateLastSeen(userId);
    } catch (e) {
      debugPrint('❌ Failed to update last seen: $e');
    }
  }
}

/// Provider for presence service
final presenceServiceProvider = Provider.family<PresenceService?, String>((
  ref,
  userId,
) {
  if (userId.isEmpty) return null;

  return PresenceService(ref: ref, userId: userId);
});
