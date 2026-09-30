import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../utils/appcolors.dart';
import '../services/patient_service.dart';

import 'medical_record_screen.dart';
import 'medical_timeline_screen.dart';
import 'medical_id_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final PatientService _patientService = PatientService();

  Map<String, dynamic>? _patient;
  bool _isLoadingPatient = true;
  String? _patientError;

  @override
  void initState() {
    super.initState();
    _loadPatientProfile();
  }

  Future<void> _loadPatientProfile() async {
    try {
      final response = await _patientService.getMyPatientProfile();
      final patientData = response['data'];

      if (patientData == null) {
        throw Exception(
          'Patient data was not returned by the server.',
        );
      }

      if (!mounted) return;

      setState(() {
        _patient = Map<String, dynamic>.from(patientData);
        _isLoadingPatient = false;
        _patientError = null;
      });
    } catch (e) {
      print('PATIENT PROFILE ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isLoadingPatient = false;
        _patientError = e.toString();
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  late final List<Widget> _pages = [
    HomeContent(
      onNavigate: _onItemTapped,
      patient: _patient,
      isLoading: _isLoadingPatient,
      error: _patientError,
    ),
    const MedicalRecordsScreen(),
    const MedicalIdScreen(),
    const MedicalTimelineScreen(),
    const PlaceholderScreen(title: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    _pages[0] = HomeContent(
      onNavigate: _onItemTapped,
      patient: _patient,
      isLoading: _isLoadingPatient,
      error: _patientError,
    );

    return Scaffold(
      backgroundColor: Appcolors.background,

      // Fixed header
      appBar: AppBar(
        backgroundColor: Appcolors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: false,

        title: Row(
          children: [
            // MediVault logo
            Container(
              width: 50,
              height: 50,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Appcolors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Transform.scale(
                scale: 1.15,
                child: Image.asset(
                  'assets/images/medivault_logo_cropped.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const SizedBox(width: 10),

            const Text(
              'MediVault',
              style: TextStyle(
                color: Appcolors.primaryText,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
      ),

      // Main page
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      // Fixed bottom navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Appcolors.primary,
        unselectedItemColor: Appcolors.secondaryText,
        backgroundColor: Appcolors.surface,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            activeIcon: Icon(Icons.folder),
            label: 'Records',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.badge_outlined),
            activeIcon: Icon(Icons.badge),
            label: 'Medical ID',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timeline_outlined),
            activeIcon: Icon(Icons.timeline),
            label: 'Timeline',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HOME CONTENT
// ============================================================

class HomeContent extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  final Map<String, dynamic>? patient;
  final bool isLoading;
  final String? error;

  const HomeContent({
    super.key,
    required this.onNavigate,
    required this.patient,
    required this.isLoading,
    required this.error,
  });

  String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else if (hour < 21) {
      return 'Good evening';
    } else {
      return 'Good night';
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstName = patient?['firstName'] ?? 'Patient';
    final lastName = patient?['lastName'] ?? '';
    final patientName = '$firstName $lastName'.trim();
    final patientId = patient?['patientId'] ?? 'Unavailable';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Text(
            isLoading
                ? '${getGreeting()} 👋'
                : '${getGreeting()}, $firstName 👋',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Appcolors.primaryText,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Your health. Your records. Your control.',
            style: TextStyle(
              fontSize: 14,
              color: Appcolors.secondaryText,
            ),
          ),

          const SizedBox(height: 24),

          // ==================================================
          // PATIENT LOADING
          // ==================================================

          if (isLoading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Appcolors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Appcolors.border,
                ),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                    ),
                  ),
                  SizedBox(width: 14),
                  Text(
                    'Loading your medical ID...',
                    style: TextStyle(
                      color: Appcolors.secondaryText,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else if (error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Appcolors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Appcolors.error,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Appcolors.error,
                    size: 28,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Unable to load your medical ID',
                    style: TextStyle(
                      color: Appcolors.primaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    error!,
                    style: const TextStyle(
                      color: Appcolors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else
            // ==================================================
            // MEDICAL ID CARD
            // ==================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Appcolors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  // Patient information
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Medical ID',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          patientName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Patient ID: $patientId',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Row(
                          children: [
                            Icon(
                              Icons.lock_outline,
                              color: Colors.white70,
                              size: 16,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Securely stored',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // QR Code
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: QrImageView(
                      data: patientId,
                      version: QrVersions.auto,
                      size: 105,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 28),

          // ==================================================
          // QUICK ACCESS
          // ==================================================

          const Text(
            'Quick Access',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Appcolors.primaryText,
            ),
          ),

          const SizedBox(height: 14),

          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.95,
            children: [
              // Medical Records
              QuickAccessCard(
                icon: Icons.folder_outlined,
                title: 'Medical Records',
                subtitle: 'View your reports',
                onTap: () {
                  onNavigate(1);
                },
              ),

              // Medical Timeline
              QuickAccessCard(
                icon: Icons.timeline_outlined,
                title: 'Medical Timeline',
                subtitle: 'View your history',
                onTap: () {
                  onNavigate(3);
                },
              ),

              // Medical ID
              QuickAccessCard(
                icon: Icons.badge_outlined,
                title: 'Medical ID',
                subtitle: 'Show your QR',
                onTap: () {
                  onNavigate(2);
                },
              ),

              // Prescriptions
              QuickAccessCard(
                icon: Icons.medication_outlined,
                title: 'Prescriptions',
                subtitle: 'View your medicines',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Prescriptions screen coming soon',
                      ),
                    ),
                  );
                },
              ),

              // Access Permissions
              QuickAccessCard(
                icon: Icons.security_outlined,
                title: 'Access Permissions',
                subtitle: 'Manage access',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Access Permissions coming soon',
                      ),
                    ),
                  );
                },
              ),

              // Notifications
              QuickAccessCard(
                icon: Icons.notifications_none_outlined,
                title: 'Notifications',
                subtitle: 'View updates',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Notifications screen coming soon',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// QUICK ACCESS CARD
// ============================================================

class QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const QuickAccessCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Appcolors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Appcolors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Appcolors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Appcolors.primary,
                  size: 26,
                ),
              ),

              const SizedBox(height: 14),

              Text(
                title,
                style: const TextStyle(
                  color: Appcolors.primaryText,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                subtitle,
                style: const TextStyle(
                  color: Appcolors.secondaryText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PLACEHOLDER SCREEN
// ============================================================

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Appcolors.primaryText,
        ),
      ),
    );
  }
}