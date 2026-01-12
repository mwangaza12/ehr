import 'package:ehr/model/patient.dart';
import 'package:ehr/model/visit.dart';
import 'package:ehr/providers/auth_provider.dart';
import 'package:ehr/providers/patient_provider.dart';
import 'package:ehr/providers/visit_provider.dart';
import 'package:ehr/providers/sync_provider.dart';
import 'package:ehr/widgets/sync_button.dart';
import 'package:ehr/screens/sync/sync_screen.dart';
import 'package:flutter/material.dart';
import 'package:ehr/constants/app_colors.dart';
import 'package:provider/provider.dart';
import '../patients/patients_page.dart';
import '../ai/ai_assistant_page.dart';
import '../profile/profile_page.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int currentIndex = 0;
  late final List<Widget> screens;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });

    screens = [
      HomeDashboard(onShowQuickActions: _showQuickActions),
      const PatientsPage(),
      const AiAssistantPage(),
      const ProfilePage(),
    ];
  }

  Future<void> _initializeData() async {
    final authProvider = context.read<AuthProvider>();
    final patientProvider = context.read<PatientProvider>();
    final visitProvider = context.read<VisitProvider>();

    if (authProvider.isLoggedIn && authProvider.userId != null) {
      patientProvider.setCurrentUser(authProvider.userId!);
      visitProvider.setCurrentUser(authProvider.userId!);
      
      await patientProvider.loadPatients();
      await visitProvider.loadVisits();
    }
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                      _buildQuickActionItem(
                        icon: Icons.person_add_alt_1,
                        title: 'New Patient',
                        color: AppColors.primaryDark,
                        onTap: () {
                          Navigator.pop(context);
                          // Navigate to new patient
                        },
                      ),
                      _buildQuickActionItem(
                        icon: Icons.medical_services,
                        title: 'New Visit',
                        color: const Color(0xFF4ECDC4),
                        onTap: () {
                          Navigator.pop(context);
                          // Navigate to new visit
                        },
                      ),
                      _buildQuickActionItem(
                        icon: Icons.note_add,
                        title: 'Clinical Note',
                        color: const Color(0xFFFFA726),
                        onTap: () {
                          Navigator.pop(context);
                          // Create clinical note
                        },
                      ),
                      _buildQuickActionItem(
                        icon: Icons.medication,
                        title: 'Prescription',
                        color: const Color(0xFFFF6B6B),
                        onTap: () {
                          Navigator.pop(context);
                          // Create prescription
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 40),
      child: FloatingActionButton(
        onPressed: _showQuickActions,
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => setState(() => currentIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primaryDark,
          unselectedItemColor: Colors.grey.shade600,
          showUnselectedLabels: true,
          elevation: 0,
          backgroundColor: Colors.white,
          selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: currentIndex == 0 ? AppColors.primaryDark.withOpacity(0.1) : Colors.transparent,
                ),
                child: Icon(
                  currentIndex == 0 ? Icons.dashboard : Icons.dashboard_outlined,
                  size: 24,
                ),
              ),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: currentIndex == 1 ? AppColors.primaryDark.withOpacity(0.1) : Colors.transparent,
                ),
                child: Icon(
                  currentIndex == 1 ? Icons.people : Icons.people_outline,
                  size: 24,
                ),
              ),
              label: "Patients",
            ),
            const BottomNavigationBarItem(
              icon: SizedBox.shrink(),
              label: "",
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: currentIndex == 2 ? AppColors.primaryDark.withOpacity(0.1) : Colors.transparent,
                ),
                child: Icon(
                  currentIndex == 2 ? Icons.auto_awesome : Icons.auto_awesome_outlined,
                  size: 24,
                ),
              ),
              label: "AI",
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: currentIndex == 3 ? AppColors.primaryDark.withOpacity(0.1) : Colors.transparent,
                ),
                child: Icon(
                  currentIndex == 3 ? Icons.person : Icons.person_outline,
                  size: 24,
                ),
              ),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: currentIndex == 0 ? _buildFloatingActionButton() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class HomeDashboard extends StatelessWidget {
  final VoidCallback onShowQuickActions;

  const HomeDashboard({super.key, required this.onShowQuickActions});

  String _getDayName(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  String _getMonthName(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[date.month - 1];
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final period = date.hour < 12 ? 'AM' : 'PM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getDayName(DateTime.now())}, ${_getMonthName(DateTime.now())} ${DateTime.now().day}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                final email = authProvider.userEmail ?? '';
                final username = email.split('@').first;
                return Text(
                  'Welcome, Dr. ${username.isNotEmpty ? username : 'User'}',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF2D3142),
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFF2D3142)),
            onPressed: () {
              // Navigate to notifications
            },
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: SyncButton(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final patientProvider = context.read<PatientProvider>();
          final visitProvider = context.read<VisitProvider>();
          await Future.wait([
            patientProvider.loadPatients(),
            visitProvider.loadVisits(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Sync Status
                _buildSyncStatus(context),
                const SizedBox(height: 20),

                // Stats Grid
                Consumer2<PatientProvider, VisitProvider>(
                  builder: (context, patientProvider, visitProvider, _) {
                    final today = DateTime.now();
                    final todayVisits = visitProvider.visits.where((visit) {
                      final visitDate = visit.createdAt;
                      return visitDate.year == today.year && 
                            visitDate.month == today.month && 
                            visitDate.day == today.day;
                    }).length;

                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                title: 'Total Patients',
                                value: patientProvider.patients.length.toString(),
                                icon: Icons.people_outline,
                                color: const Color(0xFF6C63FF),
                                subtitle: '${patientProvider.unsyncedPatients.length} unsynced',
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildStatCard(
                                title: 'Today\'s Visits',
                                value: todayVisits.toString(),
                                icon: Icons.event_available,
                                color: const Color(0xFF4ECDC4),
                                subtitle: 'Appointments',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                title: 'Pending Sync',
                                value: (patientProvider.unsyncedPatients.length + visitProvider.unsyncedVisits.length).toString(),
                                icon: Icons.sync,
                                color: const Color(0xFFFFA726),
                                subtitle: 'Items pending',
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildStatCard(
                                title: 'This Month',
                                value: visitProvider.visits.where((v) {
                                  return v.createdAt.month == today.month && v.createdAt.year == today.year;
                                }).length.toString(),
                                icon: Icons.assessment,
                                color: const Color(0xFFFF6B6B),
                                subtitle: 'Total visits',
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 25),

                // Quick Actions Title
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_horiz, color: Color(0xFF2D3142)),
                        onPressed: onShowQuickActions,
                      ),
                    ],
                  ),
                ),

                // Quick Actions Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.5,
                  children: [
                    _buildActionCard(
                      icon: Icons.person_add_alt_1,
                      title: 'New Patient',
                      color: AppColors.primaryDark,
                      onTap: () {
                        // Navigate to new patient
                      },
                    ),
                    _buildActionCard(
                      icon: Icons.medical_services,
                      title: 'New Visit',
                      color: const Color(0xFF4ECDC4),
                      onTap: () {
                        // Navigate to new visit
                      },
                    ),
                    _buildActionCard(
                      icon: Icons.note_add,
                      title: 'Clinical Note',
                      color: const Color(0xFFFFA726),
                      onTap: () {
                        // Create clinical note
                      },
                    ),
                    _buildActionCard(
                      icon: Icons.medication,
                      title: 'Prescription',
                      color: const Color(0xFFFF6B6B),
                      onTap: () {
                        // Create prescription
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // Recent Patients
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Patients',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // This needs to be handled by parent
                          // Will be implemented when navigation is set up
                        },
                        child: const Row(
                          children: [
                            Text(
                              'View All',
                              style: TextStyle(color: AppColors.primaryDark),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.chevron_right, color: AppColors.primaryDark, size: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Recent Patients List
                Consumer<PatientProvider>(
                  builder: (context, patientProvider, _) {
                    final recentPatients = patientProvider.patients.take(3).toList();
                    
                    if (recentPatients.isEmpty) {
                      return _buildEmptyState(
                        icon: Icons.people_outline,
                        title: 'No patients yet',
                        subtitle: 'Add your first patient to get started',
                      );
                    }

                    return Column(
                      children: recentPatients.map((patient) {
                        return _buildPatientListItem(patient);
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 25),

                // Upcoming Visits
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Upcoming Visits',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigate to visits page
                        },
                        child: const Row(
                          children: [
                            Text(
                              'View All',
                              style: TextStyle(color: AppColors.primaryDark),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.chevron_right, color: AppColors.primaryDark, size: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Upcoming Visits List
                Consumer<VisitProvider>(
                  builder: (context, visitProvider, _) {
                    final now = DateTime.now();
                    final upcomingVisits = visitProvider.visits
                        .where((visit) => visit.visitDate.isAfter(now))
                        .take(2)
                        .toList();
                    
                    if (upcomingVisits.isEmpty) {
                      return _buildEmptyState(
                        icon: Icons.calendar_today,
                        title: 'No upcoming visits',
                        subtitle: 'Schedule appointments to see them here',
                      );
                    }

                    return Column(
                      children: upcomingVisits.map((visit) {
                        return _buildVisitListItem(visit);
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSyncStatus(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, syncProvider, _) {
        if (!syncProvider.isOnline) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SyncScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade100),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.cloud_off, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Offline Mode',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${syncProvider.pendingSyncCount} items pending sync',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.orange),
                ],
              ),
            )
            );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Icon(Icons.more_vert, color: Colors.grey.shade400, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientListItem(Patient patient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryDark.withOpacity(0.1),
          child: Text(
            patient.firstName.isNotEmpty ? patient.firstName[0].toUpperCase() : 'P',
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          patient.fullName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3142),
          ),
        ),
        subtitle: Text(
          'ID: ${patient.idNumber}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: patient.isSynced ? Colors.green.shade50 : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            patient.isSynced ? 'Synced' : 'Pending',
            style: TextStyle(
              fontSize: 10,
              color: patient.isSynced ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        onTap: () {
          // Navigate to patient details
        },
      ),
    );
  }

  Widget _buildVisitListItem(Visit visit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryDark.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              visit.visitDate.day.toString(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ),
        title: Text(
          visit.patientName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3142),
          ),
        ),
        subtitle: Text(
          '${_formatTime(visit.visitDate)} • ${_getMonthName(visit.visitDate)} ${visit.visitDate.day}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.grey,
        ),
        onTap: () {
          // Navigate to visit details
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3142),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}