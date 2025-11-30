import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ehr/services/database_helper.dart';
import 'package:ehr/services/firebase_service.dart';
import 'package:ehr/model/visit.dart';

class SyncService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final FirebaseService _firebaseService = FirebaseService();
  final Connectivity _connectivity = Connectivity();

  // Check if device is online
  Future<bool> isOnline() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  // Sync all unsynced data for a user
  Future<SyncResult> syncAllData(String firebaseUid) async {
    if (!await isOnline()) {
      return SyncResult(
        success: false,
        message: 'No internet connection',
        patientsSynced: 0,
        visitsSynced: 0,
      );
    }

    int patientsSynced = 0;
    int visitsSynced = 0;
    String? errorMessage;

    try {
      // Sync patients
      final unsyncedPatients = await _databaseHelper.getUnsyncedPatients(firebaseUid);
      if (unsyncedPatients.isNotEmpty) {
        await _firebaseService.batchSyncPatients(unsyncedPatients);
        
        // Mark patients as synced in local database
        for (var patient in unsyncedPatients) {
          await _databaseHelper.markPatientAsSynced(patient.id!);
          patientsSynced++;
        }
      }

      // Sync visits
      final unsyncedVisits = await _databaseHelper.getUnsyncedVisits(firebaseUid);
      if (unsyncedVisits.isNotEmpty) {
        await _firebaseService.batchSyncVisits(unsyncedVisits);
        
        // Mark visits as synced in local database
        for (var visit in unsyncedVisits) {
          await _databaseHelper.markVisitAsSynced(visit.id!);
          visitsSynced++;
        }
      }

      return SyncResult(
        success: true,
        message: 'Sync completed successfully',
        patientsSynced: patientsSynced,
        visitsSynced: visitsSynced,
      );
    } catch (e) {
      errorMessage = 'Sync failed: $e';
      return SyncResult(
        success: false,
        message: errorMessage,
        patientsSynced: patientsSynced,
        visitsSynced: visitsSynced,
      );
    }
  }

  // Download data from Firestore to local database
  Future<DownloadResult> downloadAllData(String firebaseUid) async {
    if (!await isOnline()) {
      return DownloadResult(
        success: false,
        message: 'No internet connection',
        patientsDownloaded: 0,
        visitsDownloaded: 0,
      );
    }

    int patientsDownloaded = 0;
    int visitsDownloaded = 0;

    try {
      // Download patients from Firestore
      final firestorePatients = await _firebaseService.getFirestorePatients(firebaseUid);
      for (var patient in firestorePatients) {
        final localPatient = await _databaseHelper.getPatientById(patient.id!);
        
        if (localPatient == null) {
          // Insert new patient from cloud
          await _databaseHelper.insertPatient(patient.copyWith(isSynced: true));
          patientsDownloaded++;
        } else {
          // Compare timestamps and update if cloud version is newer
          if (patient.updatedAt.isAfter(localPatient.updatedAt)) {
            await _databaseHelper.updatePatient(patient.copyWith(isSynced: true));
            patientsDownloaded++;
          }
        }
      }

      // Download visits from Firestore
      final firestoreVisits = await _firebaseService.getFirestoreVisits(firebaseUid);
      for (var visit in firestoreVisits) {
        final localVisits = await _databaseHelper.getVisitsByUser(firebaseUid);
        final existingVisit = localVisits.firstWhere(
          (v) => v.id == visit.id,
          orElse: () => Visit(
            firebaseUid: '',
            patientId: '',
            patientName: '',
            visitDate: DateTime.now(),
            chiefComplaint: '',
            diagnosis: '',
            treatment: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        if (existingVisit.firebaseUid.isEmpty) {
          // Insert new visit from cloud
          await _databaseHelper.insertVisit(visit.copyWith(isSynced: true));
          visitsDownloaded++;
        } else if (visit.updatedAt.isAfter(existingVisit.updatedAt)) {
          // Update if cloud version is newer
          await _databaseHelper.updateVisit(visit.copyWith(isSynced: true));
          visitsDownloaded++;
        }
      }

      return DownloadResult(
        success: true,
        message: 'Download completed successfully',
        patientsDownloaded: patientsDownloaded,
        visitsDownloaded: visitsDownloaded,
      );
    } catch (e) {
      return DownloadResult(
        success: false,
        message: 'Download failed: $e',
        patientsDownloaded: patientsDownloaded,
        visitsDownloaded: visitsDownloaded,
      );
    }
  }

  // Full two-way sync
  Future<FullSyncResult> fullSync(String firebaseUid) async {
    if (!await isOnline()) {
      return FullSyncResult(
        success: false,
        message: 'No internet connection',
        uploadResult: SyncResult(success: false, message: 'Skipped', patientsSynced: 0, visitsSynced: 0),
        downloadResult: DownloadResult(success: false, message: 'Skipped', patientsDownloaded: 0, visitsDownloaded: 0),
      );
    }

    try {
      // First upload local changes
      final uploadResult = await syncAllData(firebaseUid);
      
      // Then download remote changes
      final downloadResult = await downloadAllData(firebaseUid);

      return FullSyncResult(
        success: uploadResult.success && downloadResult.success,
        message: 'Full sync completed',
        uploadResult: uploadResult,
        downloadResult: downloadResult,
      );
    } catch (e) {
      return FullSyncResult(
        success: false,
        message: 'Full sync failed: $e',
        uploadResult: SyncResult(success: false, message: 'Error', patientsSynced: 0, visitsSynced: 0),
        downloadResult: DownloadResult(success: false, message: 'Error', patientsDownloaded: 0, visitsDownloaded: 0),
      );
    }
  }
}

// Result classes
class SyncResult {
  final bool success;
  final String message;
  final int patientsSynced;
  final int visitsSynced;

  SyncResult({
    required this.success,
    required this.message,
    required this.patientsSynced,
    required this.visitsSynced,
  });
}

class DownloadResult {
  final bool success;
  final String message;
  final int patientsDownloaded;
  final int visitsDownloaded;

  DownloadResult({
    required this.success,
    required this.message,
    required this.patientsDownloaded,
    required this.visitsDownloaded,
  });
}

class FullSyncResult {
  final bool success;
  final String message;
  final SyncResult uploadResult;
  final DownloadResult downloadResult;

  FullSyncResult({
    required this.success,
    required this.message,
    required this.uploadResult,
    required this.downloadResult,
  });
}
