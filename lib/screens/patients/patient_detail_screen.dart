import 'package:ehr/screens/patients/new_visit_screen.dart';
import 'package:ehr/screens/patients/visit_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ehr/model/patient.dart';
import 'package:ehr/providers/patient_provider.dart';
import 'package:ehr/constants/app_colors.dart';

class PatientDetailScreen extends StatefulWidget {
  final Patient patient;

  const PatientDetailScreen({
    super.key,
    required this.patient,
  });

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  late Patient _editingPatient;
  bool _isEditMode = false;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _medicalHistoryController = TextEditingController();
  final _allergiesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _editingPatient = widget.patient;
    _populateFields();
  }

  void _populateFields() {
    _firstNameController.text = _editingPatient.firstName;
    _lastNameController.text = _editingPatient.lastName;
    _phoneNumberController.text = _editingPatient.phoneNumber;
    _emailController.text = _editingPatient.email ?? '';
    _medicalHistoryController.text = _editingPatient.medicalHistory ?? '';
    _allergiesController.text = _editingPatient.allergies ?? '';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _medicalHistoryController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final patientProvider = context.read<PatientProvider>();

    final updatedPatient = _editingPatient.copyWith(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phoneNumber: _phoneNumberController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      medicalHistory: _medicalHistoryController.text.trim().isEmpty
          ? null
          : _medicalHistoryController.text.trim(),
      allergies:
          _allergiesController.text.trim().isEmpty ? null : _allergiesController.text.trim(),
    );

    await patientProvider.updatePatient(updatedPatient);

    if (patientProvider.error == null) {
      setState(() {
        _editingPatient = updatedPatient;
        _isEditMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(patientProvider.error ?? 'Error updating patient'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Details'),
        backgroundColor: AppColors.primaryDark,
        actions: [
          if (!_isEditMode)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditMode = true;
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Avatar
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primaryDark.withOpacity(0.2),
                    radius: 48,
                    child: Text(
                      _editingPatient.firstName[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _editingPatient.fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _editingPatient.isSynced
                          ? Colors.green.withOpacity(0.2)
                          : Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _editingPatient.isSynced ? Colors.green : Colors.orange,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _editingPatient.isSynced ? Icons.cloud_done : Icons.cloud_off,
                          size: 14,
                          color: _editingPatient.isSynced ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _editingPatient.isSynced ? 'Synced' : 'Not Synced',
                          style: TextStyle(
                            fontSize: 12,
                            color: _editingPatient.isSynced ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VisitHistoryScreen(patient: _editingPatient),
                  ),
                );
              },
              icon: const Icon(Icons.history),
              label: const Text('View Consultation History'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NewVisitScreen(patient: _editingPatient),
                  ),
                );
              },
              icon: const Icon(Icons.add_circle),
              label: const Text('New Consultation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),

            if (_isEditMode) ...[
              // Edit Mode
              _buildSectionTitle('Edit Patient Information'),
              const SizedBox(height: 16),
              TextField(
                controller: _firstNameController,
                decoration: _buildInputDecoration('First Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _lastNameController,
                decoration: _buildInputDecoration('Last Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneNumberController,
                decoration: _buildInputDecoration('Phone Number'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: _buildInputDecoration('Email'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _medicalHistoryController,
                decoration: _buildInputDecoration('Medical History'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _allergiesController,
                decoration: _buildInputDecoration('Allergies'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _populateFields();
                        setState(() {
                          _isEditMode = false;
                        });
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Consumer<PatientProvider>(
                      builder: (context, patientProvider, _) {
                        return ElevatedButton(
                          onPressed:
                              patientProvider.isLoading ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryDark,
                          ),
                          child: patientProvider.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('Save'),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ] else ...[
              // View Mode
              _buildInfoSection('Personal Information', [
                _buildInfoRow('Full Name', _editingPatient.fullName),
                _buildInfoRow('Date of Birth', _editingPatient.dateOfBirth),
                _buildInfoRow('Gender', _editingPatient.gender),
                _buildInfoRow('ID Number', _editingPatient.idNumber),
              ]),
              const SizedBox(height: 24),
              _buildInfoSection('Contact Information', [
                _buildInfoRow('Phone', _editingPatient.phoneNumber),
                if (_editingPatient.email != null)
                  _buildInfoRow('Email', _editingPatient.email!),
              ]),
              if (_editingPatient.medicalHistory != null ||
                  _editingPatient.allergies != null) ...[
                const SizedBox(height: 24),
                _buildInfoSection('Medical Information', [
                  if (_editingPatient.medicalHistory != null)
                    _buildInfoRow('Medical History', _editingPatient.medicalHistory!),
                  if (_editingPatient.allergies != null)
                    _buildInfoRow('Allergies', _editingPatient.allergies!),
                ]),
              ],
              const SizedBox(height: 24),
              _buildInfoSection('System Information', [
                _buildInfoRow(
                  'Created',
                  _editingPatient.createdAt.toString().split('.')[0],
                ),
                _buildInfoRow(
                  'Updated',
                  _editingPatient.updatedAt.toString().split('.')[0],
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryDark,
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 8,
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: children.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey.shade200,
            ),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.all(12),
              child: children[index],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primaryDark, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}