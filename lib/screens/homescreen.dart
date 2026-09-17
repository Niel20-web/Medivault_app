import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../utils/appcolors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeContent(),
    PlaceholderScreen(title: 'Medical Records'),
    PlaceholderScreen(title: 'Medical ID'),
    PlaceholderScreen(title: 'Profile'),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.background,

      body: SafeArea(
        child: Column(
          children: [
            // Fixed MediVault header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 18,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Text(
                'MediVault',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Appcolors.primary,
                ),
              ),
            ),

            // Page content
            Expanded(
              child: _pages[_selectedIndex],
            ),
          ],
        ),
      ),

      // Fixed bottom navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Appcolors.primary,
        unselectedItemColor: Appcolors.secondaryText,
        elevation: 8,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            activeIcon: Icon(Icons.description),
            label: 'Records',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_2_outlined),
            activeIcon: Icon(Icons.qr_code_2),
            label: 'Medical ID',
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
  const HomeContent({super.key});

  // Dynamic greeting based on current time
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Dynamic greeting
          Text(
            '${getGreeting()}, Nathan 👋',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Appcolors.primaryText,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Your health records, all in one place.',
            style: TextStyle(
              fontSize: 14,
              color: Appcolors.secondaryText,
            ),
          ),

          const SizedBox(height: 25),

          // Medical ID heading
          Text(
            'Medical ID',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Appcolors.primaryText,
            ),
          ),

          const SizedBox(height: 12),

          // Medical ID Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Appcolors.primary,
              borderRadius: BorderRadius.circular(22),
            ),

            child: Row(
              children: [

                // Patient information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        'MEDICAL ID',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),

                      const SizedBox(height: 14),

                      const Text(
                        'Nathan',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Patient ID',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.75),
                        ),
                      ),

                      const SizedBox(height: 2),

                      const Text(
                        'MV-10294',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 15),

                      Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 15,
                            color: Colors.white.withOpacity(0.85),
                          ),

                          const SizedBox(width: 5),

                          Text(
                            'Securely stored',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // QR Code
                Container(
                  padding: const EdgeInsets.all(8),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),

                  child: QrImageView(
                    data: 'MV-10294',
                    version: QrVersions.auto,
                    size: 105,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Quick Access heading
          Text(
            'Quick Access',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Appcolors.primaryText,
            ),
          ),

          const SizedBox(height: 12),

          // Row 1
          Row(
            children: [
              QuickAccessCard(
                icon: Icons.description_outlined,
                title: 'Medical Records',
                subtitle: 'View your reports',
              ),

              const SizedBox(width: 12),

              QuickAccessCard(
                icon: Icons.timeline,
                title: 'Medical Timeline',
                subtitle: 'View your history',
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Row 2
          Row(
            children: [
              QuickAccessCard(
                icon: Icons.qr_code_2,
                title: 'Medical ID',
                subtitle: 'Show your QR',
              ),

              const SizedBox(width: 12),

              QuickAccessCard(
                icon: Icons.medication_outlined,
                title: 'Prescriptions',
                subtitle: 'View your medicines',
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Row 3
          Row(
            children: [
              QuickAccessCard(
                icon: Icons.security_outlined,
                title: 'Access Permissions',
                subtitle: 'Manage access',
              ),

              const SizedBox(width: 12),

              QuickAccessCard(
                icon: Icons.notifications_none,
                title: 'Notifications',
                subtitle: 'View updates',
              ),
            ],
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}


// ============================================================
// QUICK ACCESS CARD
// ============================================================

class QuickAccessCard extends StatelessWidget {
  const QuickAccessCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 150,
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Appcolors.border,
          ),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Icon(
              icon,
              size: 30,
              color: Appcolors.primary,
            ),

            const Spacer(),

            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Appcolors.primaryText,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Appcolors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ============================================================
// TEMPORARY PLACEHOLDER SCREENS
// ============================================================

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Appcolors.primaryText,
        ),
      ),
    );
  }
}