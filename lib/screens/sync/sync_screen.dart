// ============================================
// FILE: lib/screens/sync/sync_screen.dart
// ============================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ehr/providers/sync_provider.dart';
import 'package:ehr/providers/patient_provider.dart';
import 'package:ehr/providers/visit_provider.dart';
import 'package:ehr/providers/auth_provider.dart';
import 'package:ehr/constants/app_colors.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  @override
  void initState() {
    super.initState();
    _updatePendingCount();
  }

  Future<void> _updatePendingCount() async {
    final patientProvider = context.read<PatientProvider>();
    final visitProvider = context.read<VisitProvider>();
    final syncProvider = context.read<SyncProvider>();

    final unsyncedPatients = await patientProvider.getUnsyncedPatients();
    final unsyncedVisits = await visitProvider.getUnsyncedVisits();
    
    syncProvider.updatePendingSyncCount(
      unsyncedPatients.length + unsyncedVisits.length,
    );
  }

  Future<void> _performSync() async {
    final authProvider = context.read<AuthProvider>();
    final syncProvider = context.read<SyncProvider>();
    
    if (authProvider.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    await syncProvider.syncData(authProvider.userId!);

    if (syncProvider.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sync completed successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Reload data
      final patientProvider = context.read<PatientProvider>();
      final visitProvider = context.read<VisitProvider>();
      await patientProvider.loadPatients();
      await visitProvider.loadVisits();
      
      _updatePendingCount();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(syncProvider.error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Management'),
        backgroundColor: AppColors.primaryDark,
      ),
      body: Consumer<SyncProvider>(
        builder: (context, syncProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Connection Status Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: syncProvider.isOnline
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: syncProvider.isOnline ? Colors.green : Colors.orange,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        syncProvider.isOnline ? Icons.wifi : Icons.wifi_off,
                        size: 48,
                        color: syncProvider.isOnline ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        syncProvider.isOnline ? 'Connected' : 'Offline',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: syncProvider.isOnline ? Colors.green : Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        syncProvider.isOnline
                            ? 'Your device is connected to the internet'
                            : 'Your device is offline. Changes will sync when connected.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Sync Status Section
                _buildSectionTitle('Sync Status'),
                const SizedBox(height: 16),
                
                _buildInfoCard(
                  'Last Sync',
                  syncProvider.lastSyncTimeFormatted,
                  Icons.access_time,
                  Colors.blue,
                ),
                const SizedBox(height: 12),
                
                _buildInfoCard(
                  'Pending Items',
                  '${syncProvider.pendingSyncCount} records',
                  Icons.sync_problem,
                  Colors.orange,
                ),
                const SizedBox(height: 24),

                // Sync Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: syncProvider.isSyncing || !syncProvider.isOnline
                        ? null
                        : _performSync,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: syncProvider.isSyncing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.sync),
                    label: Text(
                      syncProvider.isSyncing
                          ? 'Syncing...'
                          : !syncProvider.isOnline
                              ? 'No Connection'
                              : 'Sync Now',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Information Section
                _buildSectionTitle('How Sync Works'),
                const SizedBox(height: 16),
                
                _buildInfoTile(
                  'Automatic Sync',
                  'When you reconnect to the internet, data will automatically sync.',
                  Icons.cloud_sync,
                ),
                const SizedBox(height: 12),
                
                _buildInfoTile(
                  'Offline Mode',
                  'You can add patients and record visits even without internet. They will sync later.',
                  Icons.cloud_off,
                ),
                const SizedBox(height: 12),
                
                _buildInfoTile(
                  'Data Safety',
                  'Your data is stored locally and backed up to the cloud when online.',
                  Icons.security,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryDark,
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String title, String description, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryDark, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
