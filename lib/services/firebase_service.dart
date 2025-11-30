import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ehr/model/patient.dart';
import 'package:ehr/model/visit.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============ PATIENT SYNC OPERATIONS ============

  Future<void> syncPatientToFirestore(Patient patient) async {
    try {
      await _firestore
          .collection('users')
          .doc(patient.firebaseUid)
          .collection('patients')
          .doc(patient.id)
          .set(patient.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error syncing patient to Firestore: $e');
    }
  }

  Future<List<Patient>> getFirestorePatients(String firebaseUid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(firebaseUid)
          .collection('patients')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Patient.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Error fetching patients from Firestore: $e');
    }
  }

  Future<void> deletePatientFromFirestore(String firebaseUid, String patientId) async {
    try {
      await _firestore
          .collection('users')
          .doc(firebaseUid)
          .collection('patients')
          .doc(patientId)
          .delete();
    } catch (e) {
      throw Exception('Error deleting patient from Firestore: $e');
    }
  }

  // ============ VISIT SYNC OPERATIONS ============

  Future<void> syncVisitToFirestore(Visit visit) async {
    try {
      await _firestore
          .collection('users')
          .doc(visit.firebaseUid)
          .collection('visits')
          .doc(visit.id)
          .set(visit.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error syncing visit to Firestore: $e');
    }
  }

  Future<List<Visit>> getFirestoreVisits(String firebaseUid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(firebaseUid)
          .collection('visits')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Visit.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Error fetching visits from Firestore: $e');
    }
  }

  Future<void> deleteVisitFromFirestore(String firebaseUid, String visitId) async {
    try {
      await _firestore
          .collection('users')
          .doc(firebaseUid)
          .collection('visits')
          .doc(visitId)
          .delete();
    } catch (e) {
      throw Exception('Error deleting visit from Firestore: $e');
    }
  }

  // ============ BATCH OPERATIONS ============

  Future<void> batchSyncPatients(List<Patient> patients) async {
    try {
      final batch = _firestore.batch();

      for (var patient in patients) {
        final docRef = _firestore
            .collection('users')
            .doc(patient.firebaseUid)
            .collection('patients')
            .doc(patient.id);
        batch.set(docRef, patient.toJson(), SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error batch syncing patients: $e');
    }
  }

  Future<void> batchSyncVisits(List<Visit> visits) async {
    try {
      final batch = _firestore.batch();

      for (var visit in visits) {
        final docRef = _firestore
            .collection('users')
            .doc(visit.firebaseUid)
            .collection('visits')
            .doc(visit.id);
        batch.set(docRef, visit.toJson(), SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error batch syncing visits: $e');
    }
  }
}
