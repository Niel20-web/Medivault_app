import 'package:flutter/material.dart';
import '../utils/appcolors.dart';

void main() {
  runApp(const MyApp());
}

// ==========================================================
// MAIN APP
// ==========================================================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Profile',
      theme: ThemeData(
        scaffoldBackgroundColor: Appcolors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Appcolors.primary,
        ),
      ),
      home: const ProfilePage(),
    );
  }
}

// ==========================================================
// PROFILE PAGE
// ==========================================================

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      // ----------------------------------------------------
      // APP BAR
      // ----------------------------------------------------

      appBar: AppBar(
        backgroundColor: Appcolors.background,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Appcolors.primaryText,
          ),

          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Profile',
          style: TextStyle(
            color: Appcolors.primaryText,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        centerTitle: false,
      ),

      // ----------------------------------------------------
      // BODY
      // ----------------------------------------------------

      body: SingleChildScrollView(

        child: Column(
          children: [

            // =================================================
            // PROFILE HEADER
            // =================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 10,
                bottom: 30,
              ),

              child: Column(
                children: [

                  // Profile picture

                  CircleAvatar(
                    radius: 48,

                    backgroundColor: Appcolors.deepBlue,

                    child: const Icon(
                      Icons.person,
                      size: 55,
                      color: Appcolors.primary,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Name

                  const Text(
                    'Nathan',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  // Patient ID

                  Text(
                    'Patient ID: MV-10294',
                    style: TextStyle(
                      color: Appcolors.surface,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // =================================================
            // PERSONAL INFORMATION
            // =================================================

            sectionTitle(
              title: 'Personal Information',
              icon: Icons.person_outline,
            ),

            const Divider(
              height: 1,
              indent: 20,
              endIndent: 20,
            ),

            informationTile(
              icon: Icons.phone,
              title: 'Phone',
              value: '+91 XXXXX XXXXX',
            ),

            informationTile(
              icon: Icons.email,
              title: 'Email',
              value: 'nathan@email.com',
            ),

            informationTile(
              icon: Icons.cake,
              title: 'Date of Birth',
              value: '20 January 2005',
            ),

            const SizedBox(height: 15),

            // =================================================
            // MEDICAL INFORMATION
            // =================================================

            sectionTitle(
              title: 'Medical Information',
              icon: Icons.medical_information_outlined,
            ),

            const Divider(
              height: 1,
              indent: 20,
              endIndent: 20,
            ),

            informationTile(
              icon: Icons.bloodtype,
              title: 'Blood Group',
              value: 'O+',
            ),

            informationTile(
              icon: Icons.location_on,
              title: 'Location',
              value: 'Shillong',
            ),

            const SizedBox(height: 15),

            // =================================================
            // ACCOUNT
            // =================================================

            sectionTitle(
              title: 'Account',
              icon: Icons.settings_outlined,
              showArrow: false,
            ),

            const Divider(
              height: 1,
              indent: 20,
              endIndent: 20,
            ),

            // Edit Profile

            accountTile(
              icon: Icons.edit_outlined,
              title: 'Edit Profile',
              onTap: () {
                // Open Edit Profile page
              },
            ),

            // Privacy

            accountTile(
              icon: Icons.lock_outline,
              title: 'Privacy & Security',
              onTap: () {
                // Open Privacy page
              },
            ),

            // Notifications

            accountTile(
              icon: Icons.notifications_none,
              title: 'Notifications',
              onTap: () {
                // Open Notifications page
              },
            ),

            const SizedBox(height: 10),

            // =================================================
            // LOG OUT
            // =================================================

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),

              child: ListTile(

                contentPadding: EdgeInsets.zero,

                leading: const Icon(
                  Icons.logout,
                  color: Appcolors.error,
                ),

                title: const Text(
                  'Log Out',
                  style: TextStyle(
                    color: Appcolors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                trailing: const Icon(
                  Icons.chevron_right,
                  color: Appcolors.primary,
                ),

                onTap: () {

                  // Logout action

                  showDialog(
                    context: context,

                    builder: (context) {

                      return AlertDialog(

                        title: const Text(
                          'Log Out',
                        ),

                        content: const Text(
                          'Are you sure you want to log out?',
                        ),

                        actions: [

                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },

                            child: const Text(
                              'CANCEL',
                            ),
                          ),

                          TextButton(
                            onPressed: () {

                              Navigator.pop(context);

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Logged out successfully',
                                  ),
                                ),
                              );
                            },

                            child: const Text(
                              'LOG OUT',
                              style: TextStyle(
                                color: Appcolors.error,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // SECTION TITLE
  // ==========================================================

  static Widget sectionTitle({
    required String title,
    required IconData icon,
    bool showArrow = true,
  }) {

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        12,
      ),

      child: Row(
        children: [

          Icon(
            icon,
            size: 22,
            color: Appcolors.primary,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          if (showArrow)
            const Icon(
              Icons.chevron_right,
              color: Appcolors.surface,
            ),
        ],
      ),
    );
  }

  // ==========================================================
  // INFORMATION TILE
  // ==========================================================

  static Widget informationTile({
    required IconData icon,
    required String title,
    required String value,
  }) {

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 12,
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Container(
            width: 42,
            height: 42,

            decoration: BoxDecoration(
              color: Appcolors.background,
              borderRadius: BorderRadius.circular(12),
            ),

            child: Icon(
              icon,
              color: Appcolors.background,
              size: 21,
            ),
          ),

          const SizedBox(width: 14),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Text(
                title,
                style: TextStyle(
                  color: Appcolors.primaryText,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ACCOUNT TILE
  // ==========================================================

  static Widget accountTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),

      child: ListTile(

        contentPadding: EdgeInsets.zero,

        leading: Icon(
          icon,
          color: Appcolors.background,
        ),

        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),

        trailing: const Icon(
          Icons.chevron_right,
          color: Appcolors.primaryText,
        ),

        onTap: onTap,
      ),
    );
  }
}