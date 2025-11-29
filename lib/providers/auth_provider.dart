// ============================================
// FILE: lib/providers/auth_provider.dart
// ============================================

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get userId => _currentUser?.uid;
  String? get userEmail => _currentUser?.email;

  AuthProvider() {
    // Initialize with current Firebase user if any
    _initializeUser();
    
    // Listen to Firebase auth state changes
    _firebaseAuth.authStateChanges().listen((User? user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  void _initializeUser() {
    _currentUser = _firebaseAuth.currentUser;
  }

  Future<void> loginWithEmail(String email, String password) async {
    _setLoading(true);
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _clearError();
    } catch (e) {
      _setError('Login failed: ${_formatError(e)}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> registerWithEmail(String email, String password) async {
    _setLoading(true);
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _clearError();
    } catch (e) {
      _setError('Registration failed: ${_formatError(e)}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _firebaseAuth.signOut();
      _currentUser = null;
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Logout failed: ${_formatError(e)}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      _clearError();
    } catch (e) {
      _setError('Reset failed: ${_formatError(e)}');
    } finally {
      _setLoading(false);
    }
  }

  String _formatError(dynamic error) {
    if (error is FirebaseAuthException) {
      return error.message ?? 'An error occurred';
    }
    return error.toString();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}