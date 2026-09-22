import 'package:flutter/material.dart';

import '../utils/appcolors.dart';
import 'medical_record_detail_screen.dart';

class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key});

  @override
  State<MedicalRecordsScreen> createState() =>
      _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState
    extends State<MedicalRecordsScreen> {
  String selectedFilter = 'All';

  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final bool showDiagnosis =
        (selectedFilter == 'All' ||
            selectedFilter == 'Diagnoses') &&
        _matchesSearch('Viral Fever Diagnosis');

    final bool showVitals =
        (selectedFilter == 'All' ||
            selectedFilter == 'Vitals') &&
        _matchesSearch(
          'Vitals Blood Pressure Heart Rate SpO2 Temperature',
        );

    return Scaffold(
      backgroundColor: Appcolors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Medical Records',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Appcolors.primaryText,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'View and manage your medical history.',
                style: TextStyle(
                  fontSize: 14,
                  color: Appcolors.secondaryText,
                ),
              ),

              const SizedBox(height: 24),

              // Search bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Appcolors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Appcolors.border,
                  ),
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search medical records...',
                    hintStyle: TextStyle(
                      color: Appcolors.secondaryText,
                    ),
                    border: InputBorder.none,
                    icon: Icon(
                      Icons.search,
                      color: Appcolors.secondaryText,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Filter chips
              Row(
                children: [
                  _buildFilterChip(
                    label: 'All',
                  ),

                  const SizedBox(width: 10),

                  _buildFilterChip(
                    label: 'Diagnoses',
                  ),

                  const SizedBox(width: 10),

                  _buildFilterChip(
                    label: 'Vitals',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Diagnosis
              if (showDiagnosis) ...[
                Text(
                  'Recent Diagnoses',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Appcolors.primaryText,
                  ),
                ),

                const SizedBox(height: 12),

                _buildDiagnosisCard(),
              ],

              // Vitals
              if (showVitals) ...[
                const SizedBox(height: 16),

                if (selectedFilter == 'Vitals')
                  Text(
                    'Recent Vitals',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Appcolors.primaryText,
                    ),
                  ),

                if (selectedFilter == 'Vitals')
                  const SizedBox(height: 12),

                _buildVitalsCard(),
              ],

              // No results
              if (!showDiagnosis && !showVitals) ...[
                const SizedBox(height: 30),

                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 48,
                        color: Appcolors.secondaryText,
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'No records found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Appcolors.primaryText,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Try a different search.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Appcolors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _matchesSearch(String text) {
    if (searchQuery.trim().isEmpty) {
      return true;
    }

    return text
        .toLowerCase()
        .contains(searchQuery.trim().toLowerCase());
  }

  Widget _buildFilterChip({
    required String label,
  }) {
    final bool isSelected = selectedFilter == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Appcolors.primary
              : Appcolors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Appcolors.primary
                : Appcolors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : Appcolors.secondaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildDiagnosisCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const MedicalRecordDetailScreen(
              type: 'diagnosis',
            ),
          ),
        );
      },
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Appcolors.primary.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.medical_services_outlined,
                    color: Appcolors.primary,
                    size: 23,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Viral Fever',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Appcolors.primaryText,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        'Diagnosis',
                        style: TextStyle(
                          fontSize: 13,
                          color: Appcolors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color:
                        Appcolors.success.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Appcolors.success,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Divider(
              color: Appcolors.border,
              height: 1,
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: Appcolors.secondaryText,
                ),

                const SizedBox(width: 8),

                Text(
                  '18 September 2026',
                  style: TextStyle(
                    fontSize: 13,
                    color: Appcolors.secondaryText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalsCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const MedicalRecordDetailScreen(
              type: 'vitals',
            ),
          ),
        );
      },
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Appcolors.primary.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.favorite_outline,
                    color: Appcolors.primary,
                    size: 23,
                  ),
                ),

                const SizedBox(width: 12),

                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vitals',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Appcolors.primaryText,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      'Recorded measurements',
                      style: TextStyle(
                        fontSize: 13,
                        color: Appcolors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: _buildVitalItem(
                    label: 'Blood Pressure',
                    value: '120/80',
                    unit: 'mmHg',
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _buildVitalItem(
                    label: 'Heart Rate',
                    value: '78',
                    unit: 'bpm',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildVitalItem(
                    label: 'SpO₂',
                    value: '98',
                    unit: '%',
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _buildVitalItem(
                    label: 'Temperature',
                    value: '36.7',
                    unit: '°C',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Divider(
              color: Appcolors.border,
              height: 1,
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: Appcolors.secondaryText,
                ),

                const SizedBox(width: 8),

                Text(
                  '18 September 2026',
                  style: TextStyle(
                    fontSize: 13,
                    color: Appcolors.secondaryText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalItem({
    required String label,
    required String value,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Appcolors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Appcolors.secondaryText,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Appcolors.primaryText,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            unit,
            style: TextStyle(
              fontSize: 11,
              color: Appcolors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}