
class Visit {
  final String? id;
  final String firebaseUid;
  final String patientId;
  final String patientName;
  final DateTime visitDate;
  final String chiefComplaint;
  final String diagnosis;
  final String treatment;
  final String? prescription;
  final String? notes;
  final String? nextFollowUp;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  Visit({
    this.id,
    required this.firebaseUid,
    required this.patientId,
    required this.patientName,
    required this.visitDate,
    required this.chiefComplaint,
    required this.diagnosis,
    required this.treatment,
    this.prescription,
    this.notes,
    this.nextFollowUp,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebaseUid': firebaseUid,
      'patientId': patientId,
      'patientName': patientName,
      'visitDate': visitDate.toIso8601String(),
      'chiefComplaint': chiefComplaint,
      'diagnosis': diagnosis,
      'treatment': treatment,
      'prescription': prescription,
      'notes': notes,
      'nextFollowUp': nextFollowUp,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Visit.fromJson(Map<String, dynamic> json) {
    return Visit(
      id: json['id'],
      firebaseUid: json['firebaseUid'],
      patientId: json['patientId'],
      patientName: json['patientName'] ?? '',
      visitDate: DateTime.parse(json['visitDate']),
      chiefComplaint: json['chiefComplaint'] ?? '',
      diagnosis: json['diagnosis'] ?? '',
      treatment: json['treatment'] ?? '',
      prescription: json['prescription'],
      notes: json['notes'],
      nextFollowUp: json['nextFollowUp'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firebaseUid': firebaseUid,
      'patientId': patientId,
      'patientName': patientName,
      'visitDate': visitDate.toIso8601String(),
      'chiefComplaint': chiefComplaint,
      'diagnosis': diagnosis,
      'treatment': treatment,
      'prescription': prescription,
      'notes': notes,
      'nextFollowUp': nextFollowUp,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory Visit.fromMap(Map<String, dynamic> map) {
    return Visit(
      id: map['id'],
      firebaseUid: map['firebaseUid'],
      patientId: map['patientId'],
      patientName: map['patientName'] ?? '',
      visitDate: DateTime.parse(map['visitDate']),
      chiefComplaint: map['chiefComplaint'] ?? '',
      diagnosis: map['diagnosis'] ?? '',
      treatment: map['treatment'] ?? '',
      prescription: map['prescription'],
      notes: map['notes'],
      nextFollowUp: map['nextFollowUp'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      isSynced: map['isSynced'] == 1,
    );
  }

  Visit copyWith({
    String? id,
    String? firebaseUid,
    String? patientId,
    String? patientName,
    DateTime? visitDate,
    String? chiefComplaint,
    String? diagnosis,
    String? treatment,
    String? prescription,
    String? notes,
    String? nextFollowUp,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return Visit(
      id: id ?? this.id,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      visitDate: visitDate ?? this.visitDate,
      chiefComplaint: chiefComplaint ?? this.chiefComplaint,
      diagnosis: diagnosis ?? this.diagnosis,
      treatment: treatment ?? this.treatment,
      prescription: prescription ?? this.prescription,
      notes: notes ?? this.notes,
      nextFollowUp: nextFollowUp ?? this.nextFollowUp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
