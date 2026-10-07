import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../utils/appcolors.dart';
import '../services/patient_service.dart';

import 'medical_record_screen.dart';
import 'medical_timeline_screen.dart';
import 'medical_id_screen.dart';
import 'prescription.dart';
import 'profile.dart';
import 'notifications_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeContent(
        onNavigate: _onItemTapped,
        patient: _patient,
        isLoading: _isLoadingPatient,
        error: _patientError,
      ),
      const MedicalRecordScreen(),
      const MedicalIdScreen(),
      const MedicalTimelineScreen(),
      const ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: Appcolors.background,

      appBar: AppBar(
        backgroundColor: Appcolors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: Row(
          children: [
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

      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),

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

class HomeContent extends StatelessWidget {
  final Function(int) onNavigate;
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

  String _getGreeting(String firstName) {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return 'Good morning, $firstName 👋';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon, $firstName 👋';
    } else if (hour >= 17 && hour < 21) {
      return 'Good evening, $firstName 👋';
    } else {
      return 'Good night, $firstName 👋';
    }
  }

  @override
  Widget build(BuildContext context) {
    String firstName = 'there';
    String fullName = 'Patient';

    // This is the public ID shown to the patient.
    String displayPatientId = 'Loading...';

    if (patient != null) {
      firstName = patient!['firstName']?.toString() ?? 'there';

      final first = patient!['firstName']?.toString() ?? '';
      final last = patient!['lastName']?.toString() ?? '';

      fullName = '$first $last'.trim();

      if (fullName.isEmpty) {
        fullName = 'Patient';
      }

      // Use profileId for the ID displayed in the UI.
      //
      // Example:
      // profileId = KEQNY2C4
      //
      // Do NOT use patientId here because that is the
      // backend/canonical patient identifier.
      displayPatientId =
          patient!['profileId']?.toString() ?? 'Unknown';
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(firstName),
              style: const TextStyle(
                color: Appcolors.primaryText,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Your health. Your records. Your control.',
              style: TextStyle(
                color: Appcolors.secondaryText,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 24),

            // Medical ID Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Appcolors.primary,
                    Appcolors.deepBlue,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Appcolors.primary.withOpacity(0.20),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Medical ID',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          displayPatientId,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 18),

                        Row(
                          children: const [
                            Icon(
                              Icons.verified_outlined,
                              color: Colors.white,
                              size: 17,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Securely stored',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Keep using the internal patient _id for the QR.
                  // This is separate from the public profileId
                  // displayed above.
                  if (patient != null &&
                      patient!['_id'] != null)
                    Container(
                      width: 88,
                      height: 88,
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: QrImageView(
                        data: patient!['_id'].toString(),
                        version: QrVersions.auto,
                        backgroundColor: Colors.white,
                      ),
                    )
                  else
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.qr_code_2,
                        color: Colors.white,
                        size: 55,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Quick Access',
              style: TextStyle(
                color: Appcolors.primaryText,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 14),

            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.35,
              children: [
                QuickAccessCard(
                  icon: Icons.folder_outlined,
                  title: 'Medical Records',
                  onTap: () {
                    onNavigate(1);
                  },
                ),

                QuickAccessCard(
                  icon: Icons.timeline_outlined,
                  title: 'Medical Timeline',
                  onTap: () {
                    onNavigate(3);
                  },
                ),

                QuickAccessCard(
                  icon: Icons.badge_outlined,
                  title: 'Medical ID',
                  onTap: () {
                    onNavigate(2);
                  },
                ),

                QuickAccessCard(
                  icon: Icons.medication_outlined,
                  title: 'Prescriptions',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const PrescriptionsPage(),
                      ),
                    );
                  },
                ),

                QuickAccessCard(
                  icon: Icons.security_outlined,
                  title: 'Access Permissions',
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

                QuickAccessCard(
                  icon: Icons.notifications_none_outlined,
                  title: 'Notifications',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const NotificationsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const QuickAccessCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Appcolors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Appcolors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: Appcolors.primary,
                  size: 23,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                title,
                style: const TextStyle(
                  color: Appcolors.primaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}