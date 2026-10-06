import 'package:flutter/material.dart';

import '../services/patient_service.dart';
import '../utils/appcolors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final PatientService _patientService = PatientService();

  bool _notificationsEnabled = true;
  bool _emailNotifications = true;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await _patientService.getMyPatientProfile();

      final data = response['data'] is Map
          ? Map<String, dynamic>.from(response['data'])
          : response;

      final preferences = data['preferences'] is Map
          ? Map<String, dynamic>.from(data['preferences'])
          : <String, dynamic>{};

      if (!mounted) return;

      setState(() {
        _notificationsEnabled =
            preferences['notificationsEnabled'] ?? true;

        _emailNotifications =
            preferences['emailNotifications'] ?? true;

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = 'Failed to load notification preferences.';
      });
    }
  }

  Future<void> _updateNotifications({
    bool? notificationsEnabled,
    bool? emailNotifications,
  }) async {
    if (_isSaving) return;

    final oldNotificationsEnabled = _notificationsEnabled;
    final oldEmailNotifications = _emailNotifications;

    setState(() {
      if (notificationsEnabled != null) {
        _notificationsEnabled = notificationsEnabled;
      }

      if (emailNotifications != null) {
        _emailNotifications = emailNotifications;
      }

      _isSaving = true;
    });

    try {
      await _patientService.updateNotificationPreferences(
        notificationsEnabled: notificationsEnabled,
        emailNotifications: emailNotifications,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification preferences updated'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _notificationsEnabled = oldNotificationsEnabled;
        _emailNotifications = oldEmailNotifications;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update notification preferences',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.notifications_off_outlined,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPreferences,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionTitle('Notification Preferences'),

        const SizedBox(height: 12),

        _buildSettingCard(
          icon: Icons.notifications_outlined,
          title: 'Push Notifications',
          subtitle:
              'Receive notifications about your appointments, health updates and reminders.',
          value: _notificationsEnabled,
          onChanged: _isSaving
              ? null
              : (value) {
                  _updateNotifications(
                    notificationsEnabled: value,
                  );
                },
        ),

        const SizedBox(height: 12),

        _buildSettingCard(
          icon: Icons.email_outlined,
          title: 'Email Notifications',
          subtitle:
              'Receive important updates and reminders by email.',
          value: _emailNotifications,
          onChanged: _isSaving
              ? null
              : (value) {
                  _updateNotifications(
                    emailNotifications: value,
                  );
                },
        ),

        const SizedBox(height: 28),

        if (_isSaving)
          const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Appcolors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Appcolors.primary,
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Appcolors.primary,
          ),
        ],
      ),
    );
  }
}