import 'package:ehr/services/sync.service.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class SyncProvider extends ChangeNotifier {
  final SyncService _syncService = SyncService();
  final Connectivity _connectivity = Connectivity();
  
  bool _isOnline = false;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String? _error;
  int _pendingSyncCount = 0;
  StreamSubscription? _connectivitySubscription;

  // Getters
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get error => _error;
  int get pendingSyncCount => _pendingSyncCount;
  
  String get lastSyncTimeFormatted {
    if (_lastSyncTime == null) return 'Never';
    final now = DateTime.now();
    final difference = now.difference(_lastSyncTime!);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} mins ago';
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    return '${difference.inDays} days ago';
  }

  SyncProvider() {
    _initConnectivity();
    _listenToConnectivity();
  }

  Future<void> _initConnectivity() async {
    _isOnline = await _syncService.isOnline();
    notifyListeners();
  }

  void _listenToConnectivity() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) async {
      final wasOffline = !_isOnline;
      _isOnline = result != ConnectivityResult.none;
      notifyListeners();

      // Auto-sync when connectivity is restored
      if (wasOffline && _isOnline && _pendingSyncCount > 0) {
        await Future.delayed(const Duration(seconds: 2));
        // Auto-sync will be triggered from outside
      }
    });
  }

  Future<void> syncData(String firebaseUid) async {
    if (!_isOnline) {
      _setError('No internet connection');
      return;
    }

    if (_isSyncing) {
      _setError('Sync already in progress');
      return;
    }

    _setIsSyncing(true);
    _clearError();

    try {
      final result = await _syncService.fullSync(firebaseUid);
      
      if (result.success) {
        _lastSyncTime = DateTime.now();
        _pendingSyncCount = 0;
        _clearError();
      } else {
        _setError(result.message);
      }
    } catch (e) {
      _setError('Sync failed: $e');
    } finally {
      _setIsSyncing(false);
    }
  }

  void updatePendingSyncCount(int count) {
    _pendingSyncCount = count;
    notifyListeners();
  }

  void _setIsSyncing(bool value) {
    _isSyncing = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}