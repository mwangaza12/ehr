import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ehr/model/patient.dart';
import 'package:ehr/providers/visit_provider.dart';
import 'package:ehr/constants/app_colors.dart';

class NewVisitScreen extends StatefulWidget {
  final Patient patient;

  const NewVisitScreen({
    super.key,
    required this.patient,
  });

  @override
  State<NewVisitScreen> createState() => _NewVisitScreenState();
}

class _NewVisitScreenState extends State<NewVisitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _chiefComplaintController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _prescriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _followUpController = TextEditingController();

  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _chiefComplaintController.dispose();
    _diagnosisController.dispose();
    _treatmentController.dispose();
    _prescriptionController.dispose();
    _notesController.dispose();
    _followUpController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final visitProvider = context.read<VisitProvider>();

    await visitProvider.addVisit(
      patientId: widget.patient.id!,
      patientName: widget.patient.fullName,
      visitDate: _selectedDate,
      chiefComplaint: _chiefComplaintController.text.trim(),
      diagnosis: _diagnosisController.text.trim(),
      treatment: _treatmentController.text.trim(),
      prescription: _prescriptionController.text.trim().isEmpty
          ? null
          : _prescriptionController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      nextFollowUp: _followUpController.text.trim().isEmpty
          ? null
          : _followUpController.text.trim(),
    );

    if (visitProvider.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visit recorded successfully')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(visitProvider.error ?? 'Error recording visit'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Consultation'),
        backgroundColor: AppColors.primaryDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryDark,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Patient',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.patient.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ID: ${widget.patient.idNumber}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Visit Date
              _buildSectionTitle('Consultation Details'),
              const SizedBox(height: 16),
              TextFormField(
                decoration: _buildInputDecoration('Visit Date')
                    .copyWith(
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ),
                controller: TextEditingController(
                  text:
                      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),

              // Chief Complaint
              TextFormField(
                controller: _chiefComplaintController,
                decoration: _buildInputDecoration('Chief Complaint'),
                maxLines: 3,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Chief complaint is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Diagnosis
              TextFormField(
                controller: _diagnosisController,
                decoration: _buildInputDecoration('Diagnosis'),
                maxLines: 3,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Diagnosis is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Treatment
              TextFormField(
                controller: _treatmentController,
                decoration: _buildInputDecoration('Treatment Plan'),
                maxLines: 3,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Treatment plan is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Additional Information Section
              _buildSectionTitle('Additional Information'),
              const SizedBox(height: 16),

              // Prescription
              TextFormField(
                controller: _prescriptionController,
                decoration: _buildInputDecoration('Prescription (Optional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: _buildInputDecoration('Additional Notes (Optional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Follow-up
              TextFormField(
                controller: _followUpController,
                decoration: _buildInputDecoration('Next Follow-up (Optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              // Submit Button
              Consumer<VisitProvider>(
                builder: (context, visitProvider, _) {
                  return SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: visitProvider.isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: visitProvider.isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Save Consultation',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
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


