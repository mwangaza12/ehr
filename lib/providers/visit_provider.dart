import 'package:ehr/model/visit.dart';
import 'package:ehr/providers/auth_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:ehr/services/database_helper.dart';

class VisitProvider extends ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Visit> _visits = [];
  String? _currentUserUid;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Visit> get visits => _visits;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get visitCount => _visits.length;
  List<Visit> get unsyncedVisits => _visits.where((v) => !v.isSynced).toList();

  void setCurrentUser(String firebaseUid) {
    _currentUserUid = firebaseUid;
    _clearError();
  }

  Future<void> loadVisits() async {
    if (_currentUserUid == null) {
      _setError('User not logged in');
      return;
    }

    _setLoading(true);
    try {
      _visits = await _databaseHelper.getVisitsByUser(_currentUserUid!);
      _clearError();
    } catch (e) {
      _setError('Failed to load visits: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<List<Visit>> getPatientVisits(String patientId) async {
    try {
      return await _databaseHelper.getVisitsByPatient(patientId);
    } catch (e) {
      _setError('Failed to fetch patient visits: $e');
      return [];
    }
  }

  Future<void> addVisit({
    required String patientId,
    required String patientName,
    required DateTime visitDate,
    required String chiefComplaint,
    required String diagnosis,
    required String treatment,
    String? prescription,
    String? notes,
    String? nextFollowUp,
  }) async {
    if (_currentUserUid == null) {
      _setError('User not logged in');
      return;
    }

    _setLoading(true);
    try {
      final visit = Visit(
        id: const Uuid().v4(),
        firebaseUid: _currentUserUid!,
        patientId: patientId,
        patientName: patientName,
        visitDate: visitDate,
        chiefComplaint: chiefComplaint,
        diagnosis: diagnosis,
        treatment: treatment,
        prescription: prescription,
        notes: notes,
        nextFollowUp: nextFollowUp,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isSynced: false,
      );

      await _databaseHelper.insertVisit(visit);
      _visits.insert(0, visit);
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to add visit: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateVisit(Visit visit) async {
    _setLoading(true);
    try {
      await _databaseHelper.updateVisit(visit);
      final index = _visits.indexWhere((v) => v.id == visit.id);
      if (index != -1) {
        _visits[index] = visit;
      }
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to update visit: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteVisit(String id) async {
    _setLoading(true);
    try {
      await _databaseHelper.deleteVisit(id);
      _visits.removeWhere((v) => v.id == id);
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete visit: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<List<Visit>> getUnsyncedVisits() async {
    if (_currentUserUid == null) return [];

    try {
      return await _databaseHelper.getUnsyncedVisits(_currentUserUid!);
    } catch (e) {
      _setError('Failed to fetch unsynced visits: $e');
      return [];
    }
  }

  Future<void> markAsSynced(String visitId) async {
    try {
      await _databaseHelper.markVisitAsSynced(visitId);
      final index = _visits.indexWhere((v) => v.id == visitId);
      if (index != -1) {
        _visits[index] = _visits[index].copyWith(isSynced: true);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to mark visit as synced: $e');
    }
  }

  Future<void> clearVisits() async {
    _visits.clear();
    notifyListeners();
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
  void initializeWithAuth(AuthProvider authProvider) {
    if (authProvider.isLoggedIn && authProvider.userId != null) {
      setCurrentUser(authProvider.userId!);
      loadVisits();
    }
  }
}