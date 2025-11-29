import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ehr/model/patient.dart';
import 'package:ehr/model/visit.dart';
import 'package:ehr/providers/visit_provider.dart';
import 'package:ehr/constants/app_colors.dart';
import 'new_visit_screen.dart';

class VisitHistoryScreen extends StatefulWidget {
  final Patient patient;

  const VisitHistoryScreen({
    super.key,
    required this.patient,
  });

  @override
  State<VisitHistoryScreen> createState() => _VisitHistoryScreenState();
}

class _VisitHistoryScreenState extends State<VisitHistoryScreen> {
  late Future<List<Visit>> _visitsFuture;

  @override
  void initState() {
    super.initState();
    _visitsFuture = context.read<VisitProvider>().getPatientVisits(widget.patient.id!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultation History'),
        backgroundColor: AppColors.primaryDark,
      ),
      body: FutureBuilder<List<Visit>>(
        future: _visitsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  const Text('Error loading visits'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _visitsFuture = context.read<VisitProvider>()
                            .getPatientVisits(widget.patient.id!);
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final visits = snapshot.data ?? [];

          if (visits.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No consultations recorded'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NewVisitScreen(patient: widget.patient),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Record First Consultation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: visits.length,
            itemBuilder: (context, index) {
              final visit = visits[index];
              return VisitCard(
                visit: visit,
                onTap: () => _showVisitDetails(context, visit),
                onDelete: () => _showDeleteDialog(context, visit),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryDark,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewVisitScreen(patient: widget.patient),
          ),
        ).then((_) {
          setState(() {
            _visitsFuture = context.read<VisitProvider>()
                .getPatientVisits(widget.patient.id!);
          });
        }),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showVisitDetails(BuildContext context, Visit visit) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Consultation Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),
              _buildDetailRow('Date', visit.visitDate.toString().split(' ')[0]),
              _buildDetailRow('Chief Complaint', visit.chiefComplaint),
              _buildDetailRow('Diagnosis', visit.diagnosis),
              _buildDetailRow('Treatment', visit.treatment),
              if (visit.prescription != null)
                _buildDetailRow('Prescription', visit.prescription!),
              if (visit.notes != null) _buildDetailRow('Notes', visit.notes!),
              if (visit.nextFollowUp != null)
                _buildDetailRow('Next Follow-up', visit.nextFollowUp!),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: visit.isSynced ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: visit.isSynced ? Colors.green : Colors.orange,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      visit.isSynced ? Icons.cloud_done : Icons.cloud_off,
                      size: 14,
                      color: visit.isSynced ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      visit.isSynced ? 'Synced' : 'Not Synced',
                      style: TextStyle(
                        fontSize: 12,
                        color: visit.isSynced ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Visit visit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Consultation'),
        content: const Text('Are you sure you want to delete this consultation record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<VisitProvider>().deleteVisit(visit.id!);
              Navigator.pop(context);
              setState(() {
                _visitsFuture = context.read<VisitProvider>()
                    .getPatientVisits(widget.patient.id!);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Consultation deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class VisitCard extends StatelessWidget {
  final Visit visit;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const VisitCard({
    super.key,
    required this.visit,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 8),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    visit.visitDate.toString().split(' ')[0],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!visit.isSynced)
                    Tooltip(
                      message: 'Not synced to cloud',
                      child: Icon(
                        Icons.cloud_off,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Complaint: ${visit.chiefComplaint}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Diagnosis: ${visit.diagnosis}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.visibility),
                      label: const Text('View'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}