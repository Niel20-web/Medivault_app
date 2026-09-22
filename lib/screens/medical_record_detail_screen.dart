import 'package:flutter/material.dart';

import '../utils/appcolors.dart';

class MedicalRecordDetailScreen extends StatelessWidget {
  final String type;

  const MedicalRecordDetailScreen({
    super.key,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDiagnosis = type == 'diagnosis';

    return Scaffold(
      backgroundColor: Appcolors.background,
      appBar: AppBar(
        backgroundColor: Appcolors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Appcolors.primaryText,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          isDiagnosis ? 'Medical Record' : 'Vital Record',
          style: TextStyle(
            color: Appcolors.primaryText,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        child: isDiagnosis
            ? _buildDiagnosisDetails()
            : _buildVitalsDetails(),
      ),
    );
  }

  Widget _buildDiagnosisDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          icon: Icons.medical_services_outlined,
          title: 'Viral Fever',
          subtitle: 'Diagnosis',
          status: 'Active',
        ),

        const SizedBox(height: 24),

        _buildSectionTitle('Diagnosis'),

        const SizedBox(height: 12),

        _buildInfoCard(
          children: [
            _buildInfoRow(
              label: 'Condition',
              value: 'Viral Fever',
            ),
            _buildInfoRow(
              label: 'Status',
              value: 'Active',
            ),
            _buildInfoRow(
              label: 'Diagnosed',
              value: '18 September 2026',
            ),
          ],
        ),

        const SizedBox(height: 24),

        _buildSectionTitle('Healthcare Provider'),

        const SizedBox(height: 12),

        _buildInfoCard(
          children: [
            _buildInfoRow(
              label: 'Doctor',
              value: 'Dr. John Doe',
            ),
            _buildInfoRow(
              label: 'Hospital',
              value: 'Shillong Civil Hospital',
            ),
          ],
        ),

        const SizedBox(height: 24),

        _buildSectionTitle('Medical Notes'),

        const SizedBox(height: 12),

        _buildInfoCard(
          children: [
            Text(
              'No additional medical notes available.',
              style: TextStyle(
                fontSize: 14,
                color: Appcolors.secondaryText,
                height: 1.5,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        _buildSectionTitle('Follow-up'),

        const SizedBox(height: 12),

        _buildInfoCard(
          children: [
            _buildInfoRow(
              label: 'Follow-up date',
              value: 'Not specified',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVitalsDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          icon: Icons.favorite_outline,
          title: 'Vitals',
          subtitle: 'Recorded measurements',
        ),

        const SizedBox(height: 24),

        _buildSectionTitle('Measurements'),

        const SizedBox(height: 12),

        _buildInfoCard(
          children: [
            _buildInfoRow(
              label: 'Blood Pressure',
              value: '120/80 mmHg',
            ),
            _buildInfoRow(
              label: 'Heart Rate',
              value: '78 bpm',
            ),
            _buildInfoRow(
              label: 'SpO₂',
              value: '98%',
            ),
            _buildInfoRow(
              label: 'Temperature',
              value: '36.7 °C',
            ),
          ],
        ),

        const SizedBox(height: 24),

        _buildSectionTitle('Recorded'),

        const SizedBox(height: 12),

        _buildInfoCard(
          children: [
            _buildInfoRow(
              label: 'Date',
              value: '18 September 2026',
            ),
          ],
        ),

        const SizedBox(height: 24),

        _buildSectionTitle('Healthcare Provider'),

        const SizedBox(height: 12),

        _buildInfoCard(
          children: [
            _buildInfoRow(
              label: 'Recorded by',
              value: 'Dr. John Doe',
            ),
            _buildInfoRow(
              label: 'Hospital',
              value: 'Shillong Civil Hospital',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    String? status,
  }) {
    return Container(
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
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Appcolors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: Appcolors.primary,
              size: 26,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Appcolors.primaryText,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Appcolors.secondaryText,
                  ),
                ),
              ],
            ),
          ),

          if (status != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color:
                    Appcolors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Appcolors.success,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Appcolors.primaryText,
      ),
    );
  }

  Widget _buildInfoCard({
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Appcolors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Appcolors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Appcolors.secondaryText,
              ),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Appcolors.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}