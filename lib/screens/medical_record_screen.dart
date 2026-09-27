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

    final bool showDocuments =
        (selectedFilter == 'All' ||
            selectedFilter == 'Documents') &&
        _matchesSearch(
          'Blood Test Lab Report Imaging Report Chest X-Ray Discharge Summary Medical Certificate',
        );

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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(label: 'All'),
                    const SizedBox(width: 10),
                    _buildFilterChip(label: 'Diagnoses'),
                    const SizedBox(width: 10),
                    _buildFilterChip(label: 'Vitals'),
                    const SizedBox(width: 10),
                    _buildFilterChip(label: 'Documents'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // -------------------------
              // DIAGNOSES
              // -------------------------
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

              // -------------------------
              // VITALS
              // -------------------------
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

              // -------------------------
              // DOCUMENTS
              // -------------------------
              if (showDocuments) ...[
                const SizedBox(height: 24),

                Text(
                  'Medical Documents',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Appcolors.primaryText,
                  ),
                ),

                const SizedBox(height: 12),

                _buildDocumentCard(
                  title: 'Blood Test Report',
                  type: 'Lab Report',
                  date: '18 September 2026',
                  icon: Icons.science_outlined,
                ),

                const SizedBox(height: 12),

                _buildDocumentCard(
                  title: 'Chest X-Ray',
                  type: 'Imaging Report',
                  date: '15 September 2026',
                  icon: Icons.image_outlined,
                ),

                const SizedBox(height: 12),

                _buildDocumentCard(
                  title: 'Discharge Summary',
                  type: 'Discharge Summary',
                  date: '10 September 2026',
                  icon: Icons.description_outlined,
                ),

                const SizedBox(height: 12),

                _buildDocumentCard(
                  title: 'Medical Certificate',
                  type: 'Medical Certificate',
                  date: '08 September 2026',
                  icon: Icons.verified_outlined,
                ),
              ],

              // -------------------------
              // NO RESULTS
              // -------------------------
              if (!showDiagnosis &&
                  !showVitals &&
                  !showDocuments) ...[
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

  // -------------------------
  // SEARCH
  // -------------------------

  bool _matchesSearch(String text) {
    if (searchQuery.trim().isEmpty) {
      return true;
    }

    return text
        .toLowerCase()
        .contains(searchQuery.trim().toLowerCase());
  }

  // -------------------------
  // FILTER CHIP
  // -------------------------

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

  // -------------------------
  // DIAGNOSIS CARD
  // -------------------------

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
                    borderRadius:
                        BorderRadius.circular(20),
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

  // -------------------------
  // VITALS CARD
  // -------------------------

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

  // -------------------------
  // VITAL ITEM
  // -------------------------

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

  // -------------------------
  // DOCUMENT CARD
  // -------------------------

  Widget _buildDocumentCard({
    required String title,
    required String type,
    required String date,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Appcolors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Appcolors.border,
        ),
      ),
      child: Row(
        children: [
          // Document icon
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Appcolors.primary.withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: Appcolors.primary,
              size: 24,
            ),
          ),

          const SizedBox(width: 12),

          // Document information
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
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
                  type,
                  style: TextStyle(
                    fontSize: 12,
                    color: Appcolors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: Appcolors.secondaryText,
                    ),

                    const SizedBox(width: 5),

                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 11,
                        color: Appcolors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Download button
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context)
                  .showSnackBar(
                const SnackBar(
                  content: Text(
                    'Document download will be connected to the backend.',
                  ),
                ),
              );
            },
            icon: Icon(
              Icons.download_outlined,
              color: Appcolors.primary,
            ),
            tooltip: 'Download',
          ),
        ],
      ),
    );
  }
}