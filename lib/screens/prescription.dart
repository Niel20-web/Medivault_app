import 'package:flutter/material.dart';
import '../utils/appcolors.dart';

class PrescriptionsPage extends StatefulWidget {
  const PrescriptionsPage({super.key});

  @override
  State<PrescriptionsPage> createState() =>
      _PrescriptionsPageState();
}

class _PrescriptionsPageState
    extends State<PrescriptionsPage> {

  final TextEditingController searchController =
      TextEditingController();

  String searchText = '';

  // ---------------------------------------------------------
  // ACTIVE PRESCRIPTIONS
  // ---------------------------------------------------------

  final List<Map<String, String>> activePrescriptions = [
    {
      'medicine': 'Paracetamol 500 mg',
      'dose': '1 tablet • After meals',
      'frequency': 'Twice daily',
      'doctor': 'Dr. John Doe',
      'date': '18 Sep 2026',
      'nextDose': '8:00 PM',
    },
    {
      'medicine': 'Cetirizine 10 mg',
      'dose': '1 tablet • At night',
      'frequency': 'Once daily',
      'doctor': 'Dr. John Doe',
      'date': '18 Sep 2026',
      'nextDose': '10:00 PM',
    },
  ];

  // ---------------------------------------------------------
  // PAST PRESCRIPTIONS
  // ---------------------------------------------------------

  final List<Map<String, String>> pastPrescriptions = [
    {
      'medicine': 'Amoxicillin 500 mg',
      'date': '15 Sep 2026',
    },
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    // Filter active prescriptions
    final filteredActive =
        activePrescriptions.where((prescription) {

      return prescription['medicine']!
          .toLowerCase()
          .contains(searchText.toLowerCase());

    }).toList();

    // Filter past prescriptions
    final filteredPast =
        pastPrescriptions.where((prescription) {

      return prescription['medicine']!
          .toLowerCase()
          .contains(searchText.toLowerCase());

    }).toList();

    return Scaffold(
      backgroundColor: Appcolors.background,

      // =====================================================
      // APP BAR
      // =====================================================

      appBar: AppBar(
        backgroundColor: Appcolors.background,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),

          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              'Prescriptions',
              style: TextStyle(
                color: Appcolors.primaryText,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 2),

            Text(
              'Your prescribed medicines',
              style: TextStyle(
                color: Appcolors.secondaryText,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),

      // =====================================================
      // BODY
      // =====================================================

      body: SingleChildScrollView(

        padding: const EdgeInsets.symmetric(
          horizontal: 20,
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const SizedBox(height: 15),

            // =================================================
            // SEARCH BAR
            // =================================================

            TextField(
              controller: searchController,

              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },

              decoration: InputDecoration(
                hintText: 'Search medicines...',

                prefixIcon: const Icon(
                  Icons.search,
                  color: Appcolors.secondaryText,
                ),

                filled: true,
                fillColor: Appcolors.border,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),

                contentPadding:
                    const EdgeInsets.symmetric(
                  vertical: 15,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // =================================================
            // ACTIVE
            // =================================================

            const Text(
              'ACTIVE',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Appcolors.secondaryText,
              ),
            ),

            const SizedBox(height: 12),

            if (filteredActive.isEmpty)

              const Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 20,
                ),

                child: Center(
                  child: Text(
                    'No active prescriptions found.',
                    style: TextStyle(
                      color: Appcolors.secondaryText,
                    ),
                  ),
                ),
              )

            else

              ...filteredActive.map(
                (prescription) =>
                    activePrescriptionCard(
                  prescription,
                ),
              ),

            const SizedBox(height: 25),

            // =================================================
            // PAST PRESCRIPTIONS
            // =================================================

            const Text(
              'PAST PRESCRIPTIONS',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Appcolors.secondaryText,
              ),
            ),

            const SizedBox(height: 12),

            if (filteredPast.isEmpty)

              const Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 20,
                ),

                child: Center(
                  child: Text(
                    'No past prescriptions found.',
                    style: TextStyle(
                      color: Appcolors.secondaryText,
                    ),
                  ),
                ),
              )

            else

              ...filteredPast.map(
                (prescription) =>
                    pastPrescriptionCard(
                  prescription,
                ),
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // ACTIVE PRESCRIPTION CARD
  // =========================================================

  Widget activePrescriptionCard(
      Map<String, String> prescription) {

    return Container(

      width: double.infinity,

      margin: const EdgeInsets.only(
        bottom: 15,
      ),

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Appcolors.surface,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color: Appcolors.background,
        ),

        boxShadow: [
          BoxShadow(
            color: Appcolors.background,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          // Medicine name

          Row(
            children: [

              Container(
                width: 42,
                height: 42,

                decoration: BoxDecoration(
                  color: Appcolors.background,
                  borderRadius:
                      BorderRadius.circular(12),
                ),

                child: const Icon(
                  Icons.medication,
                  color: Appcolors.primary,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  prescription['medicine']!,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Dose

          Text(
            prescription['dose']!,
            style: const TextStyle(
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 6),

          // Frequency

          Text(
            prescription['frequency']!,
            style: TextStyle(
              color: Appcolors.secondaryText,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 18),

          // Doctor + Date

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,

            children: [

              Text(
                prescription['doctor']!,
                style: TextStyle(
                  color: Appcolors.secondaryText,
                  fontSize: 13,
                ),
              ),

              Text(
                prescription['date']!,
                style: TextStyle(
                  color: Appcolors.secondaryText,
                  fontSize: 13,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Divider(
            color: Appcolors.secondaryText,
          ),

          const SizedBox(height: 8),

          // Next dose

          Row(
            children: [

              const Icon(
                Icons.access_time,
                size: 19,
                color: Appcolors.primary,
              ),

              const SizedBox(width: 8),

              Text(
                'Next dose: ${prescription['nextDose']}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // PAST PRESCRIPTION CARD
  // =========================================================

  Widget pastPrescriptionCard(
      Map<String, String> prescription) {

    return Container(

      width: double.infinity,

      margin: const EdgeInsets.only(
        bottom: 12,
      ),

      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: Appcolors.surface,

        borderRadius: BorderRadius.circular(14),

        border: Border.all(
          color: Appcolors.secondaryText,
        ),
      ),

      child: Row(
        children: [

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(
                  prescription['medicine']!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Completed • ${prescription['date']}',
                  style: TextStyle(
                    color: Appcolors.secondaryText,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.check_circle_outline,
            color: Appcolors.secondaryText,
          ),
        ],
      ),
    );
  }
}