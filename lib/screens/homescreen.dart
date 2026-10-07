import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/patient_service.dart';
import '../utils/appcolors.dart';

import 'lab_reports_screen.dart';
import 'medical_id_screen.dart';
import 'medical_record_screen.dart';
import 'medical_timeline_screen.dart';
import 'notifications_screen.dart';
import 'prescription.dart';
import 'profile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PatientService _patientService = PatientService();

  int _selectedIndex = 0;

  Map<String, dynamic>? _patient;
  bool _isLoadingPatient = true;
  String? _patientError;

  @override
  void initState() {
    super.initState();
    _loadPatientProfile();
  }

  // ===========================================================================
  // LOAD PATIENT PROFILE
  // ===========================================================================

  Future<void> _loadPatientProfile() async {
    if (mounted) {
      setState(() {
        _isLoadingPatient = true;
        _patientError = null;
      });
    }

    try {
      final response =
          await _patientService.getMyPatientProfile();

      debugPrint(
        'HOME PATIENT PROFILE RESPONSE: $response',
      );

      final patient =
          _unwrapPatientResponse(response);

      final patientUuid =
          patient['_id']?.toString().trim();

      if (patientUuid == null ||
          patientUuid.isEmpty) {
        throw Exception(
          'Patient record ID not found.',
        );
      }

      debugPrint(
        'HOME CURRENT PATIENT UUID: $patientUuid',
      );

      debugPrint(
        'HOME CURRENT PATIENT ID: '
        '${patient['patientId']}',
      );

      debugPrint(
        'HOME CURRENT PROFILE ID: '
        '${patient['profileId']}',
      );

      if (!mounted) return;

      setState(() {
        _patient = patient;
        _isLoadingPatient = false;
        _patientError = null;
      });
    } catch (e) {
      debugPrint(
        'HOME PATIENT PROFILE ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _patient = null;
        _isLoadingPatient = false;
        _patientError =
            'Failed to load your patient profile.';
      });
    }
  }

  Map<String, dynamic> _unwrapPatientResponse(
    Map<String, dynamic> response,
  ) {
    final dynamic data = response['data'];

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return response;
  }

  // ===========================================================================
  // NAVIGATION
  // ===========================================================================

  void _onItemTapped(int index) {
    if (!mounted) return;

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeContent(
        onNavigate: _onItemTapped,
        patient: _patient,
        isLoading: _isLoadingPatient,
        error: _patientError,
        onRetry: _loadPatientProfile,
        patientService: _patientService,
      ),
      const MedicalRecordScreen(),
      const MedicalIdScreen(),
      const MedicalTimelineScreen(),
      const ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: Appcolors.background,

      // -----------------------------------------------------------------------
      // APP BAR
      // -----------------------------------------------------------------------

      appBar: AppBar(
        backgroundColor: Appcolors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: false,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Appcolors.background,
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Transform.scale(
                scale: 1.15,
                child: Image.asset(
                  'assets/images/medivault_logo_cropped.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'MediVault',
              style: TextStyle(
                color: Appcolors.primaryText,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
      ),

      // -----------------------------------------------------------------------
      // BODY
      // -----------------------------------------------------------------------

      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),

      // -----------------------------------------------------------------------
      // BOTTOM NAVIGATION
      // -----------------------------------------------------------------------

      bottomNavigationBar:
          BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Appcolors.primary,
        unselectedItemColor:
            Appcolors.secondaryText,
        backgroundColor: Appcolors.surface,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            activeIcon: Icon(Icons.folder),
            label: 'Records',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.badge_outlined),
            activeIcon: Icon(Icons.badge),
            label: 'Medical ID',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timeline_outlined),
            activeIcon: Icon(Icons.timeline),
            label: 'Timeline',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// HOME CONTENT
// =============================================================================

class HomeContent extends StatefulWidget {
  final Function(int) onNavigate;
  final Map<String, dynamic>? patient;
  final bool isLoading;
  final String? error;

  // IMPORTANT:
  // This is async because _loadPatientProfile() returns Future<void>.
  final Future<void> Function() onRetry;

  final PatientService patientService;

  const HomeContent({
    super.key,
    required this.onNavigate,
    required this.patient,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.patientService,
  });

  @override
  State<HomeContent> createState() =>
      _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  String? _qrPayloadUrl;

  bool _isLoadingQr = false;

  String? _qrError;

  String? _lastPatientUuid;

  @override
  void initState() {
    super.initState();
    _loadMedicalQrIfNeeded();
  }

  @override
  void didUpdateWidget(
    covariant HomeContent oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    final oldUuid =
        oldWidget.patient?['_id']
            ?.toString()
            .trim();

    final newUuid =
        widget.patient?['_id']
            ?.toString()
            .trim();

    if (newUuid != null &&
        newUuid.isNotEmpty &&
        newUuid != oldUuid) {
      _loadMedicalQrIfNeeded(
        forceRefresh: true,
      );
    }
  }

  // ===========================================================================
  // GENERATE MEDICAL PROFILE QR
  // ===========================================================================

  Future<void> _loadMedicalQrIfNeeded({
    bool forceRefresh = false,
  }) async {
    final patientUuid =
        widget.patient?['_id']
            ?.toString()
            .trim();

    if (patientUuid == null ||
        patientUuid.isEmpty) {
      return;
    }

    if (!forceRefresh &&
        _lastPatientUuid == patientUuid &&
        _qrPayloadUrl != null &&
        _qrPayloadUrl!.isNotEmpty) {
      return;
    }

    _lastPatientUuid = patientUuid;

    if (mounted) {
      setState(() {
        _isLoadingQr = true;
        _qrError = null;
      });
    }

    try {
      final payloadUrl =
          await _generateQr(patientUuid);

      if (!mounted) return;

      setState(() {
        _qrPayloadUrl = payloadUrl;
        _isLoadingQr = false;
        _qrError = null;
      });
    } catch (e) {
      debugPrint(
        'HOME QR ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _qrPayloadUrl = null;
        _isLoadingQr = false;
        _qrError = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  // ===========================================================================
  // EXACT SAME QR GENERATION AS MEDICAL ID SCREEN
  // ===========================================================================

  Future<String> _generateQr(
    String patientUuid,
  ) async {
    debugPrint(
      'HOME GENERATING MEDICAL QR FOR PATIENT UUID: '
      '$patientUuid',
    );

    final qrResponse =
        await widget.patientService
            .generateMedicalQr(
      patientUuid,
    );

    debugPrint(
      'HOME GENERATED QR RESPONSE: $qrResponse',
    );

    final dynamic rawQrData =
        qrResponse['data'];

    if (rawQrData == null ||
        rawQrData is! Map) {
      throw Exception(
        'QR data was not returned.',
      );
    }

    final qrData =
        Map<String, dynamic>.from(
      rawQrData,
    );

    final payloadUrl =
        qrData['payloadUrl']
            ?.toString()
            .trim();

    if (payloadUrl == null ||
        payloadUrl.isEmpty) {
      throw Exception(
        'QR verification URL was not generated.',
      );
    }

    debugPrint(
      'HOME MEDICAL QR FOR $patientUuid: '
      '$payloadUrl',
    );

    return payloadUrl;
  }

  // ===========================================================================
  // REGENERATE QR
  // ===========================================================================

  Future<void> _regenerateQr() async {
    await _loadMedicalQrIfNeeded(
      forceRefresh: true,
    );
  }

  // ===========================================================================
  // PATIENT HELPERS
  // ===========================================================================

  String _getGreeting(
    String firstName,
  ) {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return 'Good morning, $firstName 👋';
    }

    if (hour >= 12 && hour < 17) {
      return 'Good afternoon, $firstName 👋';
    }

    if (hour >= 17 && hour < 21) {
      return 'Good evening, $firstName 👋';
    }

    return 'Good night, $firstName 👋';
  }

  String _getFirstName() {
    final firstName =
        widget.patient?['firstName']
            ?.toString()
            .trim();

    if (firstName == null ||
        firstName.isEmpty) {
      return 'there';
    }

    return firstName;
  }

  String _getFullName() {
    final first =
        widget.patient?['firstName']
                ?.toString()
                .trim() ??
            '';

    final last =
        widget.patient?['lastName']
                ?.toString()
                .trim() ??
            '';

    final fullName =
        '$first $last'.trim();

    if (fullName.isEmpty) {
      return 'Patient';
    }

    return fullName;
  }

  String _getProfileId() {
    final profileId =
        widget.patient?['profileId']
            ?.toString()
            .trim();

    if (profileId == null ||
        profileId.isEmpty) {
      return 'Unknown';
    }

    return profileId;
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingState();
    }

    if (widget.error != null ||
        widget.patient == null) {
      return _buildErrorState();
    }

    final firstName = _getFirstName();
    final fullName = _getFullName();
    final profileId = _getProfileId();

    return RefreshIndicator(
      color: Appcolors.primary,

      // FIXED:
      // onRetry returns Future<void>, so RefreshIndicator can await it.
      onRefresh: () async {
        await widget.onRetry();
      },

      child: SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          20,
          8,
          20,
          30,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // -----------------------------------------------------------------
            // GREETING
            // -----------------------------------------------------------------

            Text(
              _getGreeting(firstName),
              style: const TextStyle(
                color: Appcolors.primaryText,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Your health. Your records. Your control.',
              style: TextStyle(
                color: Appcolors.secondaryText,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 24),

            // -----------------------------------------------------------------
            // MEDICAL ID CARD
            // -----------------------------------------------------------------

            _buildMedicalIdCard(
              fullName: fullName,
              profileId: profileId,
            ),

            const SizedBox(height: 28),

            // -----------------------------------------------------------------
            // QUICK ACCESS
            // -----------------------------------------------------------------

            const Text(
              'Quick Access',
              style: TextStyle(
                color: Appcolors.primaryText,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 14),

            _buildQuickAccessGrid(context),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // LOADING STATE
  // ===========================================================================

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        color: Appcolors.primary,
      ),
    );
  }

  // ===========================================================================
  // ERROR STATE
  // ===========================================================================

  Widget _buildErrorState() {
    return RefreshIndicator(
      color: Appcolors.primary,

      // FIXED:
      // onRetry returns Future<void>.
      onRefresh: () async {
        await widget.onRetry();
      },

      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 90),

          Container(
            width: 72,
            height: 72,
            margin:
                const EdgeInsets.symmetric(
              horizontal: 120,
            ),
            decoration: BoxDecoration(
              color:
                  Appcolors.primary.withValues(
                alpha: 0.10,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_off_outlined,
              color: Appcolors.primary,
              size: 36,
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Could not load your profile',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Appcolors.primaryText,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            widget.error ??
                'Something went wrong while loading your patient profile.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Appcolors.secondaryText,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: widget.onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Appcolors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Try Again',
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Pull down to refresh',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Appcolors.secondaryText,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MEDICAL ID CARD
  // ===========================================================================

  Widget _buildMedicalIdCard({
    required String fullName,
    required String profileId,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Appcolors.primary,
            Appcolors.deepBlue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color:
                Appcolors.primary.withValues(
              alpha: 0.20,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Medical ID',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  fullName,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  profileId,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 18),

                const Row(
                  children: [
                    Icon(
                      Icons.verified_outlined,
                      color: Colors.white,
                      size: 17,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Securely stored',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          _buildQrCode(),
        ],
      ),
    );
  }

  // ===========================================================================
  // MEDICAL PROFILE QR
  // ===========================================================================

  Widget _buildQrCode() {
    // -------------------------------------------------------------------------
    // LOADING
    // -------------------------------------------------------------------------

    if (_isLoadingQr) {
      return Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(14),
        ),
        child: Center(
          child: SizedBox(
            width: 25,
            height: 25,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Appcolors.primary,
            ),
          ),
        ),
      );
    }

    // -------------------------------------------------------------------------
    // ERROR
    // -------------------------------------------------------------------------

    if (_qrPayloadUrl == null ||
        _qrPayloadUrl!.isEmpty) {
      return Tooltip(
        message: _qrError ??
            'Unable to generate QR code.',
        child: GestureDetector(
          onTap: _regenerateQr,
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color:
                  Colors.white.withValues(
                alpha: 0.15,
              ),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: const Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.qr_code_2,
                  color: Colors.white,
                  size: 36,
                ),
                SizedBox(height: 2),
                Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // -------------------------------------------------------------------------
    // WORKING QR
    // -------------------------------------------------------------------------

    return Container(
      width: 88,
      height: 88,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: QrImageView(
        data: _qrPayloadUrl!,
        version: QrVersions.auto,
        backgroundColor: Colors.white,
      ),
    );
  }

  // ===========================================================================
  // QUICK ACCESS GRID
  // ===========================================================================

  Widget _buildQuickAccessGrid(
    BuildContext context,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.35,
      children: [
        // Medical Records
        QuickAccessCard(
          icon: Icons.folder_outlined,
          title: 'Medical Records',
          onTap: () {
            widget.onNavigate(1);
          },
        ),

        // Medical Timeline
        QuickAccessCard(
          icon: Icons.timeline_outlined,
          title: 'Medical Timeline',
          onTap: () {
            widget.onNavigate(3);
          },
        ),

        // Medical ID
        QuickAccessCard(
          icon: Icons.badge_outlined,
          title: 'Medical ID',
          onTap: () {
            widget.onNavigate(2);
          },
        ),

        // Lab Reports
        QuickAccessCard(
          icon: Icons.science_outlined,
          title: 'Lab Reports',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const LabReportsScreen(),
              ),
            );
          },
        ),

        // Prescriptions
        QuickAccessCard(
          icon: Icons.medication_outlined,
          title: 'Prescriptions',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const PrescriptionsPage(),
              ),
            );
          },
        ),

        // Access Permissions
        QuickAccessCard(
          icon: Icons.security_outlined,
          title: 'Access Permissions',
          onTap: () {
            ScaffoldMessenger.of(context)
                .showSnackBar(
              const SnackBar(
                content: Text(
                  'Access Permissions coming soon',
                ),
              ),
            );
          },
        ),

        // Notifications
        QuickAccessCard(
          icon:
              Icons.notifications_none_outlined,
          title: 'Notifications',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const NotificationsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}

// =============================================================================
// QUICK ACCESS CARD
// =============================================================================

class QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const QuickAccessCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Appcolors.surface,
      borderRadius:
          BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color: Appcolors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:
                      Appcolors.primary.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: Appcolors.primary,
                  size: 23,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                title,
                maxLines: 2,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  color:
                      Appcolors.primaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}