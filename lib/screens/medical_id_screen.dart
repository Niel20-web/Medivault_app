import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../utils/appcolors.dart';
import '../services/patient_service.dart';

class MedicalIdScreen extends StatefulWidget {
  const MedicalIdScreen({super.key});

  @override
  State<MedicalIdScreen> createState() => _MedicalIdScreenState();
}

class _MedicalIdScreenState extends State<MedicalIdScreen> {
  final PatientService _patientService = PatientService();

  Map<String, dynamic>? _patient;
  bool _isLoading = true;
  String? _error;

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
        throw Exception('Patient data was not returned by the server.');
      }

      if (!mounted) return;

      setState(() {
        _patient = Map<String, dynamic>.from(patientData);
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      print('MEDICAL ID PROFILE ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstName = _patient?['firstName'] ?? '';
    final lastName = _patient?['lastName'] ?? '';
    final patientName = '$firstName $lastName'.trim();
    final patientId = _patient?['patientId'] ?? 'Unavailable';

    return Scaffold(
      backgroundColor: Appcolors.background,

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Appcolors.primary,
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Appcolors.error,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Unable to load Medical ID',
                          style: TextStyle(
                            color: Appcolors.primaryText,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Appcolors.secondaryText,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _error = null;
                            });

                            _loadPatientProfile();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Appcolors.primary,
                          ),
                          child: const Text(
                            'Retry',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ==================================================
                      // PAGE TITLE
                      // ==================================================

                      const Text(
                        'Medical ID',
                        style: TextStyle(
                          color: Appcolors.primaryText,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ==================================================
                      // MEDICAL ID CARD
                      // ==================================================

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Appcolors.primary,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Appcolors.primary.withOpacity(0.18),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Card Header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.health_and_safety,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'MEDICAL ID',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 28),

                            // Patient Information + QR
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        patientName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 27,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      const Text(
                                        'Patient ID',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),

                                      const SizedBox(height: 3),

                                      Text(
                                        patientId,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),

                                      const SizedBox(height: 18),

                                      Row(
                                        children: [
                                          Icon(
                                            Icons.lock_outline,
                                            color:
                                                Colors.white.withOpacity(0.9),
                                            size: 17,
                                          ),
                                          const SizedBox(width: 6),
                                          const Text(
                                            'Securely stored',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 16),

                                // QR Code
                                Container(
                                  width: 125,
                                  height: 125,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
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
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ==================================================
                      // SECTION TITLE
                      // ==================================================

                      const Text(
                        'Your Medical Identity',
                        style: TextStyle(
                          color: Appcolors.primaryText,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Your MediVault Medical ID gives you a secure way '
                        'to identify and access your medical records.',
                        style: TextStyle(
                          color: Appcolors.secondaryText,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 22),

                      // ==================================================
                      // SECURITY INFORMATION CARD
                      // ==================================================

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Appcolors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Appcolors.border,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Appcolors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.security,
                                color: Appcolors.primary,
                                size: 24,
                              ),
                            ),

                            const SizedBox(width: 14),

                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Secure Medical Identity',
                                    style: TextStyle(
                                      color: Appcolors.primaryText,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'Your medical identity is securely stored.',
                                    style: TextStyle(
                                      color: Appcolors.secondaryText,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ==================================================
                      // SHOW QR BUTTON
                      // ==================================================

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  backgroundColor: Appcolors.surface,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  title: const Text(
                                    'Medical ID QR',
                                    style: TextStyle(
                                      color: Appcolors.primaryText,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: SizedBox(
                                    width: 250,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 230,
                                          height: 230,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                              color: Appcolors.border,
                                            ),
                                          ),
                                          child: QrImageView(
                                            data: patientId,
                                            version: QrVersions.auto,
                                            size: 200,
                                            padding: EdgeInsets.zero,
                                          ),
                                        ),

                                        const SizedBox(height: 16),

                                        Text(
                                          patientId,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Appcolors.primaryText,
                                          ),
                                        ),

                                        const SizedBox(height: 8),

                                        const Text(
                                          'Scan this QR code to identify the '
                                          'MediVault patient record.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Appcolors.secondaryText,
                                            fontSize: 13,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text(
                                        'Close',
                                        style: TextStyle(
                                          color: Appcolors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          icon: const Icon(
                            Icons.qr_code_2,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Show Medical QR',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Appcolors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
}