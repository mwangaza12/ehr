
class Patient {
  final String? id;
  final String firebaseUid;
  final String firstName;
  final String lastName;
  final String dateOfBirth;
  final String gender;
  final String idNumber;
  final String phoneNumber;
  final String? email;
  final String? medicalHistory;
  final String? allergies;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  Patient({
    this.id,
    required this.firebaseUid,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.gender,
    required this.idNumber,
    required this.phoneNumber,
    this.email,
    this.medicalHistory,
    this.allergies,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebaseUid': firebaseUid,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'idNumber': idNumber,
      'phoneNumber': phoneNumber,
      'email': email,
      'medicalHistory': medicalHistory,
      'allergies': allergies,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      firebaseUid: json['firebaseUid'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      dateOfBirth: json['dateOfBirth'] ?? '',
      gender: json['gender'] ?? '',
      idNumber: json['idNumber'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'],
      medicalHistory: json['medicalHistory'],
      allergies: json['allergies'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firebaseUid': firebaseUid,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'idNumber': idNumber,
      'phoneNumber': phoneNumber,
      'email': email,
      'medicalHistory': medicalHistory,
      'allergies': allergies,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'],
      firebaseUid: map['firebaseUid'],
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      dateOfBirth: map['dateOfBirth'] ?? '',
      gender: map['gender'] ?? '',
      idNumber: map['idNumber'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      email: map['email'],
      medicalHistory: map['medicalHistory'],
      allergies: map['allergies'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      isSynced: map['isSynced'] == 1,
    );
  }

  Patient copyWith({
    String? id,
    String? firebaseUid,
    String? firstName,
    String? lastName,
    String? dateOfBirth,
    String? gender,
    String? idNumber,
    String? phoneNumber,
    String? email,
    String? medicalHistory,
    String? allergies,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return Patient(
      id: id ?? this.id,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      idNumber: idNumber ?? this.idNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      allergies: allergies ?? this.allergies,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}