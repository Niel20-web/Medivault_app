import 'package:flutter/material.dart';

import '../services/patient_service.dart';
import '../utils/appcolors.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> patient;

  const EditProfileScreen({
    super.key,
    required this.patient,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final PatientService _patientService = PatientService();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _middleNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _pincodeController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _firstNameController = TextEditingController(
      text: widget.patient['firstName']?.toString() ?? '',
    );

    _lastNameController = TextEditingController(
      text: widget.patient['lastName']?.toString() ?? '',
    );

    _middleNameController = TextEditingController(
      text: widget.patient['middleName']?.toString() ?? '',
    );

    _phoneController = TextEditingController(
      text: widget.patient['phone']?.toString() ??
          widget.patient['phoneNumber']?.toString() ??
          '',
    );

    _emailController = TextEditingController(
      text: widget.patient['email']?.toString() ?? '',
    );

    _cityController = TextEditingController(
      text: widget.patient['city']?.toString() ?? '',
    );

    _stateController = TextEditingController(
      text: widget.patient['state']?.toString() ?? '',
    );

    _pincodeController = TextEditingController(
      text: widget.patient['pincode']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();

    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty) {
      _showMessage('First name and last name are required.');
      return;
    }

    if (_phoneController.text.trim().isNotEmpty &&
        !_phoneController.text.trim().startsWith('+')) {
      _showMessage(
        'Phone number must include the country code, e.g. +919876543210.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _patientService.updateMyPatientProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        middleName: _middleNameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pincode: _pincodeController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: Appcolors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Appcolors.border,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Appcolors.border,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Appcolors.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: TextEditingController(text: value),
        enabled: false,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Appcolors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Appcolors.border,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bloodGroup =
        widget.patient['bloodGroup']?.toString() ?? 'Not available';

    final dob =
        widget.patient['dateOfBirth']?.toString() ?? 'Not available';

    return Scaffold(
      backgroundColor: Appcolors.background,
      appBar: AppBar(
        backgroundColor: Appcolors.background,
        elevation: 0,
        automaticallyImplyLeading: true,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Appcolors.primaryText,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Appcolors.primaryText,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Appcolors.primaryText,
                ),
              ),

              const SizedBox(height: 16),

              _buildField(
                label: 'First Name',
                controller: _firstNameController,
              ),

              _buildField(
                label: 'Middle Name',
                controller: _middleNameController,
              ),

              _buildField(
                label: 'Last Name',
                controller: _lastNameController,
              ),

              _buildField(
                label: 'Phone Number',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                hint: '+919876543210',
              ),

              _buildField(
                label: 'Email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 10),

              const Text(
                'Location',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Appcolors.primaryText,
                ),
              ),

              const SizedBox(height: 16),

              _buildField(
                label: 'City',
                controller: _cityController,
              ),

              _buildField(
                label: 'State',
                controller: _stateController,
              ),

              _buildField(
                label: 'Pincode',
                controller: _pincodeController,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 10),

              const Text(
                'Medical Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Appcolors.primaryText,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'These details are managed by your healthcare provider.',
                style: TextStyle(
                  color: Appcolors.secondaryText,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 16),

              _buildReadOnlyField(
                label: 'Date of Birth',
                value: dob,
              ),

              _buildReadOnlyField(
                label: 'Blood Group',
                value: bloodGroup,
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Appcolors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        Appcolors.primary.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}