import 'package:ehr/model/patient.dart';
import 'package:ehr/providers/auth_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:ehr/services/database_helper.dart';
import 'package:uuid/uuid.dart';

class PatientProvider extends ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Patient> _patients = [];
  String? _currentUserUid;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Patient> get patients => _patients;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get patientCount => _patients.length;
  List<Patient> get unsyncedPatients => _patients.where((p) => !p.isSynced).toList();

  // Initialize provider with user
  void setCurrentUser(String firebaseUid) {
    _currentUserUid = firebaseUid;
    _clearError();
  }

  // Load all patients for current user
  Future<void> loadPatients() async {
    if (_currentUserUid == null) {
      _setError('User not logged in');
      return;
    }

    _setLoading(true);
    try {
      _patients = await _databaseHelper.getPatientsByUser(_currentUserUid!);
      _clearError();
    } catch (e) {
      _setError('Failed to load patients: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Add new patient
  Future<void> addPatient({
    required String firstName,
    required String lastName,
    required String dateOfBirth,
    required String gender,
    required String idNumber,
    required String phoneNumber,
    String? email,
    String? medicalHistory,
    String? allergies,
  }) async {
    if (_currentUserUid == null) {
      _setError('User not logged in');
      return;
    }

    _setLoading(true);
    try {
      final patient = Patient(
        id: const Uuid().v4(),
        firebaseUid: _currentUserUid!,
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        gender: gender,
        idNumber: idNumber,
        phoneNumber: phoneNumber,
        email: email,
        medicalHistory: medicalHistory,
        allergies: allergies,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isSynced: false,
      );

      await _databaseHelper.insertPatient(patient);
      _patients.insert(0, patient);
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to add patient: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Update existing patient
  Future<void> updatePatient(Patient patient) async {
    _setLoading(true);
    try {
      await _databaseHelper.updatePatient(patient);
      final index = _patients.indexWhere((p) => p.id == patient.id);
      if (index != -1) {
        _patients[index] = patient;
      }
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to update patient: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Delete patient
  Future<void> deletePatient(String id) async {
    _setLoading(true);
    try {
      await _databaseHelper.deletePatient(id);
      _patients.removeWhere((p) => p.id == id);
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete patient: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get patient by ID
  Future<Patient?> getPatientById(String id) async {
    try {
      return await _databaseHelper.getPatientById(id);
    } catch (e) {
      _setError('Failed to fetch patient: $e');
      return null;
    }
  }

  // Search patients
  Future<List<Patient>> searchPatients(String searchTerm) async {
    if (_currentUserUid == null) {
      _setError('User not logged in');
      return [];
    }

    try {
      return await _databaseHelper.searchPatients(_currentUserUid!, searchTerm);
    } catch (e) {
      _setError('Failed to search patients: $e');
      return [];
    }
  }

  // Get unsynced patients (for sync engine)
  Future<List<Patient>> getUnsyncedPatients() async {
    if (_currentUserUid == null) return [];

    try {
      return await _databaseHelper.getUnsyncedPatients(_currentUserUid!);
    } catch (e) {
      _setError('Failed to fetch unsynced patients: $e');
      return [];
    }
  }

  // Mark patient as synced
  Future<void> markAsSynced(String patientId) async {
    try {
      await _databaseHelper.markPatientAsSynced(patientId);
      final index = _patients.indexWhere((p) => p.id == patientId);
      if (index != -1) {
        _patients[index] = _patients[index].copyWith(isSynced: true);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to mark patient as synced: $e');
    }
  }

  // Clear patient data on logout
  Future<void> clearPatients() async {
    if (_currentUserUid == null) return;

    try {
      await _databaseHelper.deleteAllPatients(_currentUserUid!);
      _patients.clear();
      _currentUserUid = null;
      notifyListeners();
    } catch (e) {
      _setError('Failed to clear patients: $e');
    }
  }

  // Helper methods
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
      loadPatients();
    }
  }
}