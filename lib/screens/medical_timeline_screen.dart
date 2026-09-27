import 'package:flutter/material.dart';

import '../utils/appcolors.dart';
import 'medical_record_detail_screen.dart';

class MedicalTimelineScreen extends StatelessWidget {
  const MedicalTimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Medical Timeline',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Appcolors.primaryText,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'A chronological view of your medical history.',
                style: TextStyle(
                  fontSize: 14,
                  color: Appcolors.secondaryText,
                ),
              ),

              const SizedBox(height: 28),

              // Date
              _buildDateHeader('18 September 2026'),

              const SizedBox(height: 14),

              // Diagnosis
              _buildTimelineItem(
                context: context,
                icon: Icons.medical_services_outlined,
                title: 'Viral Fever',
                subtitle: 'Diagnosis',
                details: 'Diagnosed by Dr. John Doe',
                type: 'diagnosis',
                isLast: false,
              ),

              // Vitals
              _buildTimelineItem(
                context: context,
                icon: Icons.favorite_outline,
                title: 'Vitals Recorded',
                subtitle: 'Blood Pressure 120/80 • Heart Rate 78',
                details: 'SpO₂ 98% • Temperature 36.7 °C',
                type: 'vitals',
                isLast: true,
              ),

              const SizedBox(height: 30),

              // Date
              _buildDateHeader('15 September 2026'),

              const SizedBox(height: 14),

              // Imaging
              _buildTimelineItem(
                context: context,
                icon: Icons.image_outlined,
                title: 'Chest X-Ray',
                subtitle: 'Imaging Report',
                details: 'Medical imaging document',
                type: 'document',
                isLast: true,
              ),

              const SizedBox(height: 30),

              // Date
              _buildDateHeader('10 September 2026'),

              const SizedBox(height: 14),

              // Discharge
              _buildTimelineItem(
                context: context,
                icon: Icons.description_outlined,
                title: 'Discharge Summary',
                subtitle: 'Medical Document',
                details: 'Hospital discharge record',
                type: 'document',
                isLast: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateHeader(String date) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: Appcolors.primary,
            shape: BoxShape.circle,
          ),
        ),

        const SizedBox(width: 10),

        Text(
          date,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Appcolors.primaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String details,
    required String type,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline line
          SizedBox(
            width: 10,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 16,
                  color: Appcolors.primary.withValues(
                    alpha: 0.35,
                  ),
                ),

                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Appcolors.primary,
                    shape: BoxShape.circle,
                  ),
                ),

                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Appcolors.primary.withValues(
                        alpha: 0.35,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // Timeline card
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (type == 'diagnosis') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const MedicalRecordDetailScreen(
                        type: 'diagnosis',
                      ),
                    ),
                  );
                } else if (type == 'vitals') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const MedicalRecordDetailScreen(
                        type: 'vitals',
                      ),
                    ),
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.only(
                  bottom: 14,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Appcolors.surface,
                  borderRadius:
                      BorderRadius.circular(18),
                  border: Border.all(
                    color: Appcolors.border,
                  ),
                ),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color:
                            Appcolors.primary.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: Appcolors.primary,
                        size: 22,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Information
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  Appcolors.primaryText,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  FontWeight.w600,
                              color:
                                  Appcolors.primary,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            details,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Appcolors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 6),

                    Icon(
                      Icons.chevron_right,
                      color: Appcolors.secondaryText,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}