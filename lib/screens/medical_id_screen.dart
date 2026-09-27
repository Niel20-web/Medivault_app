import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../utils/appcolors.dart';

class MedicalIdScreen extends StatelessWidget {
  const MedicalIdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.background,

      appBar: AppBar(
        backgroundColor: Appcolors.background,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Medical ID',
          style: TextStyle(
            color: Appcolors.primaryText,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Appcolors.primaryText,
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medical ID Card
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nathan',
                              style: TextStyle(
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

                            const Text(
                              'MV-10294',
                              style: TextStyle(
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
                                  color: Colors.white.withOpacity(0.9),
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
                          data: 'MV-10294',
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

            // Section Title
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

            // Security Information Card
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

            // Show QR Button
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
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Appcolors.border,
                                  ),
                                ),
                                child: QrImageView(
                                  data: 'MV-10294',
                                  version: QrVersions.auto,
                                  size: 200,
                                  padding: EdgeInsets.zero,
                                ),
                              ),

                              const SizedBox(height: 16),

                              const Text(
                                'MV-10294',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Appcolors.primaryText,
                                ),
                              ),

                              const SizedBox(height: 8),

                              const Text(
                                'Scan this QR code to identify the MediVault patient record.',
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