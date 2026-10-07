import 'package:flutter/material.dart';

import '../utils/appcolors.dart';
import '../services/patient_service.dart';
import '../services/auth_service.dart';
import 'edit_profile_screen.dart';
import 'welcome_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final PatientService _patientService = PatientService();
  final AuthService _authService = AuthService();

  Map<String, dynamic>? _patient;

  bool _isLoading = true;
  bool _isLoggingOut = false;

  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _patientService.getMyPatientProfile();
      final patientData = response['data'];

      if (patientData == null) {
        throw Exception('No patient profile is linked to this account.');
      }

      if (!mounted) return;

      setState(() {
        _patient = Map<String, dynamic>.from(patientData);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _displayValue(dynamic value) {
    if (value == null) return 'Not available';

    final text = value.toString().trim();

    if (text.isEmpty) {
      return 'Not available';
    }

    return text;
  }

  String _getFullName() {
    if (_patient == null) {
      return 'Patient';
    }

    final firstName = _patient!['firstName']?.toString().trim() ?? '';

    final lastName = _patient!['lastName']?.toString().trim() ?? '';

    final name = '$firstName $lastName'.trim();

    return name.isEmpty ? 'Patient' : name;
  }

  String _getInitials() {
    final name = _getFullName();

    if (name == 'Patient') {
      return 'P';
    }

    final parts = name.split(' ');

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _formatDate(dynamic value) {
    if (value == null) {
      return 'Not available';
    }

    try {
      final date = DateTime.parse(value.toString());

      return '${date.day.toString().padLeft(2, '0')} '
          '${_monthName(date.month)} '
          '${date.year}';
    } catch (_) {
      return 'Not available';
    }
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }

  String _formatBloodGroup(dynamic value) {
    if (value == null) {
      return 'Not available';
    }

    final bloodGroup = value.toString();

    const bloodGroups = {
      'A_POSITIVE': 'A+',
      'A_NEGATIVE': 'A-',
      'B_POSITIVE': 'B+',
      'B_NEGATIVE': 'B-',
      'AB_POSITIVE': 'AB+',
      'AB_NEGATIVE': 'AB-',
      'O_POSITIVE': 'O+',
      'O_NEGATIVE': 'O-',
    };

    return bloodGroups[bloodGroup] ?? bloodGroup;
  }

  String _getLocation() {
    if (_patient == null) {
      return 'Not available';
    }

    final city = _patient!['city']?.toString().trim() ?? '';

    final state = _patient!['state']?.toString().trim() ?? '';

    if (city.isNotEmpty && state.isNotEmpty) {
      return '$city, $state';
    }

    if (city.isNotEmpty) {
      return city;
    }

    if (state.isNotEmpty) {
      return state;
    }

    final address = _patient!['address'];

    if (address is String && address.trim().isNotEmpty) {
      return address.trim();
    }

    if (address is Map) {
      final addressText =
          [
                address['line1'],
                address['line2'],
                address['city'],
                address['state'],
                address['postalCode'],
              ]
              .where(
                (value) => value != null && value.toString().trim().isNotEmpty,
              )
              .map((value) => value.toString().trim())
              .join(', ');

      if (addressText.isNotEmpty) {
        return addressText;
      }
    }

    return 'Not available';
  }

  Future<void> _openEditProfile() async {
    if (_patient == null) return;

    final updatedProfile = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditProfileScreen(patient: _patient!)),
    );

    if (updatedProfile == true) {
      await _loadProfile();
    }
  }

  Future<void> _logout() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      await _authService.logout();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoggingOut = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Logout failed: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature will be available soon.')));
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _logout();
              },
              child: const Text(
                'LOG OUT',
                style: TextStyle(
                  color: Appcolors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.background,
      appBar: AppBar(
        backgroundColor: Appcolors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Appcolors.primaryText,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Appcolors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_off_outlined,
                size: 55,
                color: Appcolors.secondaryText,
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to load profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Appcolors.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Appcolors.secondaryText, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Appcolors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: Appcolors.primary,
      onRefresh: _loadProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildProfileHeader(),

            _buildSectionTitle(
              title: 'Personal Information',
              icon: Icons.person_outline,
              showArrow: false,
            ),

            const Divider(height: 1, indent: 20, endIndent: 20),

            _buildInformationTile(
              icon: Icons.phone,
              title: 'Phone',
              value: _displayValue(
                _patient?['phone'] ?? _patient?['phoneNumber'],
              ),
            ),

            _buildInformationTile(
              icon: Icons.email,
              title: 'Email',
              value: _displayValue(_patient?['email']),
            ),

            _buildInformationTile(
              icon: Icons.cake,
              title: 'Date of Birth',
              value: _formatDate(_patient?['dateOfBirth']),
            ),

            const SizedBox(height: 15),

            _buildSectionTitle(
              title: 'Medical Information',
              icon: Icons.medical_information_outlined,
              showArrow: false,
            ),

            const Divider(height: 1, indent: 20, endIndent: 20),

            _buildInformationTile(
              icon: Icons.bloodtype,
              title: 'Blood Group',
              value: _formatBloodGroup(_patient?['bloodGroup']),
            ),

            _buildInformationTile(
              icon: Icons.location_on,
              title: 'Location',
              value: _getLocation(),
            ),

            const SizedBox(height: 15),

            _buildSectionTitle(
              title: 'Account',
              icon: Icons.settings_outlined,
              showArrow: false,
            ),

            const Divider(height: 1, indent: 20, endIndent: 20),

            _buildAccountTile(
              icon: Icons.edit_outlined,
              title: 'Edit Profile',
              onTap: _openEditProfile,
            ),

            _buildAccountTile(
              icon: Icons.lock_outline,
              title: 'Privacy & Security',
              onTap: () {
                _showComingSoon('Privacy & Security');
              },
            ),

            _buildAccountTile(
              icon: Icons.notifications_none,
              title: 'Notifications',
              onTap: () {
                _showComingSoon('Notifications');
              },
            ),

            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout, color: Appcolors.error),
                title: const Text(
                  'Log Out',
                  style: TextStyle(
                    color: Appcolors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: _isLoggingOut
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Appcolors.error,
                        ),
                      )
                    : const Icon(Icons.chevron_right, color: Appcolors.primary),
                onTap: _isLoggingOut ? null : _showLogoutConfirmation,
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 10, bottom: 30),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: Appcolors.deepBlue,
            child: Text(
              _getInitials(),
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            _getFullName(),
            style: const TextStyle(
              color: Appcolors.primaryText,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'Patient ID: ${_displayValue(_patient?['profileId'])}',
            style: const TextStyle(
              color: Appcolors.secondaryText,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required IconData icon,
    bool showArrow = true,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Appcolors.primary),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Appcolors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          if (showArrow)
            const Icon(Icons.chevron_right, color: Appcolors.secondaryText),
        ],
      ),
    );
  }

  Widget _buildInformationTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Appcolors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Appcolors.primary, size: 21),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Appcolors.secondaryText,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: const TextStyle(
                    color: Appcolors.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: Appcolors.primary),
        title: Text(
          title,
          style: const TextStyle(color: Appcolors.primaryText, fontSize: 16),
        ),
        trailing: const Icon(Icons.chevron_right, color: Appcolors.primaryText),
        onTap: onTap,
      ),
    );
  }
}
