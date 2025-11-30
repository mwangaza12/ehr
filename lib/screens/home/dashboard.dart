import 'package:ehr/providers/auth_provider.dart';
import 'package:ehr/providers/patient_provider.dart';
import 'package:ehr/providers/visit_provider.dart';
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

  // ✅ Only the content of each tab, not Dashboard itself
  late final List<Widget> screens;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final patientProvider = context.read<PatientProvider>();
      final visitProvider = context.read<VisitProvider>();

      patientProvider.initializeWithAuth(authProvider);
      visitProvider.initializeWithAuth(authProvider);
    });

    screens = [
      _buildHome(),       // Home tab shows the dashboard content
      const PatientsPage(),
      const AiAssistantPage(),
      const ProfilePage(),
    ];
  }

  // The Home tab content (Dashboard UI)
  Widget _buildHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Dashboard",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 20),

          // Example stats cards
          Row(
            children: const [
              Expanded(child: DashboardCard(title: "Total Patients", value: "128")),
              SizedBox(width: 16),
              Expanded(child: DashboardCard(title: "Appointments Today", value: "14")),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(child: DashboardCard(title: "Pending Labs", value: "6")),
              SizedBox(width: 16),
              Expanded(child: DashboardCard(title: "Prescriptions", value: "32")),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => setState(() => currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryDark,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: "Patients",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy_outlined),
            label: "AI Assistant",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}

// Simple dashboard card
class DashboardCard extends StatelessWidget {
  final String title;
  final String value;

  const DashboardCard({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 8, offset: const Offset(0,4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
