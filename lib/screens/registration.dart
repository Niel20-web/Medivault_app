import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/appcolors.dart';

// ---------------------------------------------------------
// REGISTRATION PAGE
// ---------------------------------------------------------

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() =>
      _RegistrationPageState();
}

class _RegistrationPageState
    extends State<RegistrationPage> {
  // -------------------------------------------------------
  // SERVICES
  // -------------------------------------------------------

  final AuthService _authService = AuthService();

  // -------------------------------------------------------
  // ACCOUNT CONTROLLERS
  // -------------------------------------------------------

  final TextEditingController fullNameController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController phoneController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  // -------------------------------------------------------
  // ADDRESS CONTROLLERS
  // -------------------------------------------------------

  final TextEditingController houseController =
      TextEditingController();

  final TextEditingController townController =
      TextEditingController();

  final TextEditingController cityController =
      TextEditingController();

  final TextEditingController stateController =
      TextEditingController();

  final TextEditingController pinController =
      TextEditingController();

  // -------------------------------------------------------
  // EMERGENCY CONTACT CONTROLLERS
  // -------------------------------------------------------

  final TextEditingController contactNameController =
      TextEditingController();

  final TextEditingController contactNumberController =
      TextEditingController();

  // This field is kept for the UI.
  //
  // IMPORTANT:
  // The backend registration DTO does not have an
  // emergencyDialNumber field, so it is intentionally
  // NOT sent to the API.
  final TextEditingController emergencyDialController =
      TextEditingController();

  // -------------------------------------------------------
  // PAGE CONTROLLER
  // -------------------------------------------------------

  final PageController pageController =
      PageController();

  int currentStep = 0;

  // -------------------------------------------------------
  // REGISTRATION STATE
  // -------------------------------------------------------

  bool isRegistering = false;

  // -------------------------------------------------------
  // PASSWORD VISIBILITY
  // -------------------------------------------------------

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  // -------------------------------------------------------
  // BLOOD GROUP
  // -------------------------------------------------------

  String? selectedBloodGroup;

  final List<String> bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
    'UNKNOWN',
  ];

  // -------------------------------------------------------
  // GENDER
  // -------------------------------------------------------
  //
  // IMPORTANT:
  // These are the EXACT values accepted by the backend.
  //
  // MALE
  // FEMALE
  // OTHER
  // PREFER_NOT_TO_SAY
  //
  // We use a map so the user sees friendly labels while
  // the backend receives the correct enum value.
  // -------------------------------------------------------

  String? selectedGender;

  final Map<String, String> genderOptions = {
    'MALE': 'Male',
    'FEMALE': 'Female',
    'OTHER': 'Non-binary / Other',
    'PREFER_NOT_TO_SAY': 'Prefer not to say',
  };

  // -------------------------------------------------------
  // DATE OF BIRTH
  // -------------------------------------------------------

  DateTime? dateOfBirth;

  // -------------------------------------------------------
  // DATE PICKER
  // -------------------------------------------------------

  Future<void> selectDate() async {
    final DateTime now = DateTime.now();

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (pickedDate != null) {
      setState(() {
        dateOfBirth = pickedDate;
      });
    }
  }

  // -------------------------------------------------------
  // FORMAT DATE FOR BACKEND
  // -------------------------------------------------------
  //
  // Backend expects:
  //
  // YYYY-MM-DD
  //
  // NOT:
  // 2000-01-01T00:00:00.000
  // -------------------------------------------------------

  String formatDateForBackend(DateTime date) {
    final String year =
        date.year.toString().padLeft(4, '0');

    final String month =
        date.month.toString().padLeft(2, '0');

    final String day =
        date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  // -------------------------------------------------------
  // GENERATE USERNAME
  // -------------------------------------------------------

  String generateUsername() {
    final String email =
        emailController.text.trim().toLowerCase();

    if (email.contains('@')) {
      String username = email.split('@').first.trim();

      // Keep only characters that are safe for the
      // backend username field.
      username = username.replaceAll(
        RegExp(r'[^a-zA-Z0-9_.-]'),
        '',
      );

      if (username.isNotEmpty) {
        return username;
      }
    }

    return email;
  }

  // -------------------------------------------------------
  // SPLIT FULL NAME
  // -------------------------------------------------------

  List<String> splitFullName() {
    final String fullName =
        fullNameController.text.trim();

    final List<String> parts =
        fullName.split(RegExp(r'\s+'));

    if (parts.length < 2) {
      return [fullName, ''];
    }

    final String firstName = parts.first;

    final String lastName =
        parts.sublist(1).join(' ');

    return [
      firstName,
      lastName,
    ];
  }

  // -------------------------------------------------------
  // SHOW MESSAGE
  // -------------------------------------------------------

  void showMessage(
    String message, {
    bool isError = true,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Appcolors.error
            : Appcolors.success,
      ),
    );
  }

  // -------------------------------------------------------
  // VALIDATE EMAIL
  // -------------------------------------------------------

  bool isValidEmail(String email) {
    final RegExp emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    return emailRegex.hasMatch(email);
  }

  // -------------------------------------------------------
  // VALIDATE PHONE
  // -------------------------------------------------------

  bool isValidPhone(String phone) {
    if (phone.isEmpty) {
      return true;
    }

    final String cleaned =
        phone.replaceAll(RegExp(r'[\s\-()]'), '');

    return RegExp(r'^\+?[0-9]{7,15}$')
        .hasMatch(cleaned);
  }

  // -------------------------------------------------------
  // VALIDATE PIN
  // -------------------------------------------------------

  bool isValidPin(String pin) {
    return RegExp(r'^[0-9]{4,10}$')
        .hasMatch(pin);
  }

  // -------------------------------------------------------
  // REGISTER ACCOUNT
  // -------------------------------------------------------

  Future<void> registerAccount() async {
    // =====================================================
    // BASIC ACCOUNT VALIDATION
    // =====================================================

    final String fullName =
        fullNameController.text.trim();

    if (fullName.isEmpty) {
      showMessage(
        'Please enter your full name.',
      );
      return;
    }

    final List<String> nameParts =
        splitFullName();

    if (nameParts[0].trim().isEmpty ||
        nameParts[1].trim().isEmpty) {
      showMessage(
        'Please enter your first and last name.',
      );
      return;
    }

    final String email =
        emailController.text.trim().toLowerCase();

    if (email.isEmpty) {
      showMessage(
        'Please enter your email address.',
      );
      return;
    }

    if (!isValidEmail(email)) {
      showMessage(
        'Please enter a valid email address.',
      );
      return;
    }

    final String password =
        passwordController.text;

    final String confirmPassword =
        confirmPasswordController.text;

    if (password.isEmpty) {
      showMessage(
        'Please enter a password.',
      );
      return;
    }

    if (password.length < 8) {
      showMessage(
        'Password must be at least 8 characters.',
      );
      return;
    }

    if (confirmPassword.isEmpty) {
      showMessage(
        'Please confirm your password.',
      );
      return;
    }

    if (password != confirmPassword) {
      showMessage(
        'Passwords do not match.',
      );
      return;
    }

    // =====================================================
    // PHONE VALIDATION
    // =====================================================

    final String phone =
        phoneController.text.trim();

    if (!isValidPhone(phone)) {
      showMessage(
        'Please enter a valid phone number.',
      );
      return;
    }

    // =====================================================
    // PERSONAL INFORMATION
    // =====================================================

    if (dateOfBirth == null) {
      showMessage(
        'Please select your date of birth.',
      );
      return;
    }

    if (selectedGender == null ||
        selectedGender!.trim().isEmpty) {
      showMessage(
        'Please select your gender.',
      );
      return;
    }

    if (!genderOptions.containsKey(
      selectedGender,
    )) {
      showMessage(
        'Please select a valid gender.',
      );
      return;
    }

    if (selectedBloodGroup == null ||
        selectedBloodGroup!.trim().isEmpty) {
      showMessage(
        'Please select your blood group.',
      );
      return;
    }

    if (!bloodGroups.contains(
      selectedBloodGroup,
    )) {
      showMessage(
        'Please select a valid blood group.',
      );
      return;
    }

    // =====================================================
    // ADDRESS VALIDATION
    // =====================================================

    final String house =
        houseController.text.trim();

    final String town =
        townController.text.trim();

    final String city =
        cityController.text.trim();

    final String state =
        stateController.text.trim();

    final String pin =
        pinController.text.trim();

    if (house.isEmpty) {
      showMessage(
        'Please enter your house number.',
      );
      return;
    }

    if (town.isEmpty) {
      showMessage(
        'Please enter your town or locality.',
      );
      return;
    }

    if (city.isEmpty) {
      showMessage(
        'Please enter your city.',
      );
      return;
    }

    if (state.isEmpty) {
      showMessage(
        'Please enter your state.',
      );
      return;
    }

    if (pin.isEmpty) {
      showMessage(
        'Please enter your PIN code.',
      );
      return;
    }

    if (!isValidPin(pin)) {
      showMessage(
        'Please enter a valid PIN code.',
      );
      return;
    }

    // =====================================================
    // EMERGENCY CONTACT
    // =====================================================

    final String contactName =
        contactNameController.text.trim();

    final String contactNumber =
        contactNumberController.text.trim();

    if (contactName.isEmpty) {
      showMessage(
        'Please enter the emergency contact name.',
      );
      return;
    }

    if (contactNumber.isEmpty) {
      showMessage(
        'Please enter the emergency contact number.',
      );
      return;
    }

    if (!isValidPhone(contactNumber)) {
      showMessage(
        'Please enter a valid emergency contact number.',
      );
      return;
    }

    // =====================================================
    // BUILD BACKEND DATE
    // =====================================================

    final String dob =
        formatDateForBackend(
      dateOfBirth!,
    );

    // =====================================================
    // BUILD USERNAME
    // =====================================================

    final String username =
        generateUsername();

    if (username.length < 3) {
      showMessage(
        'Unable to generate a valid username from your email.',
      );
      return;
    }

    // =====================================================
    // START REGISTRATION
    // =====================================================

    setState(() {
      isRegistering = true;
    });

    try {
      // ===================================================
      // THIS PAYLOAD MATCHES THE BACKEND REGISTER DTO
      // ===================================================

      await _authService.register(
        email: email,

        username: username,

        password: password,

        firstName:
            nameParts[0].trim(),

        lastName:
            nameParts[1].trim(),

        phone: phone,

        // IMPORTANT:
        // This causes the backend to create:
        //
        // 1. User account
        // 2. Patient record
        // 3. Medical profile
        // 4. QR identity
        //
        // The AuthService wrapper currently handles the
        // registration role internally and does not accept
        // a role override from this screen.
        createPatientIdentity: true,

        identity: {
          // Backend expects YYYY-MM-DD.
          'dateOfBirth': dob,

          // IMPORTANT:
          // Backend enum values:
          //
          // MALE
          // FEMALE
          // OTHER
          // PREFER_NOT_TO_SAY
          //
          'gender': selectedGender,

          // Backend accepts:
          //
          // A+
          // A-
          // B+
          // B-
          // AB+
          // AB-
          // O+
          // O-
          // UNKNOWN
          //
          'bloodGroup': selectedBloodGroup,

          // Backend SelfRegisterAddressDto
          'address': {
            'line1':
                '$house, $town',
            'city': city,
            'state': state,
            'postalCode': pin,
            'country': 'India',
          },

          // Backend SelfRegisterEmergencyContactDto
          'emergencyContact': {
            'name': contactName,

            // The backend requires relationship to be
            // non-empty.
            'relationship':
                'Emergency Contact',

            'phone': contactNumber,
          },

          // Optional arrays are intentionally included as
          // empty arrays so the identity starts clean.
          'allergies': <Map<String, dynamic>>[],

          'conditions': <Map<String, dynamic>>[],
        },
      );

      // ===================================================
      // SUCCESS
      // ===================================================

      if (!mounted) return;

      showMessage(
        'Account created successfully! Please log in.',
        isError: false,
      );

      await Future.delayed(
        const Duration(
          milliseconds: 700,
        ),
      );

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      String message =
          e.toString();

      if (message.startsWith(
        'Exception: ',
      )) {
        message = message.substring(
          'Exception: '.length,
        );
      }

      showMessage(message);
    } finally {
      if (mounted) {
        setState(() {
          isRegistering = false;
        });
      }
    }
  }

  // ---------------------------------------------------------
  // NEXT PAGE
  // ---------------------------------------------------------

  void nextPage() {
    if (currentStep < 2) {
      setState(() {
        currentStep++;
      });

      pageController.nextPage(
        duration:
            const Duration(
          milliseconds: 300,
        ),
        curve: Curves.easeInOut,
      );
    } else {
      registerAccount();
    }
  }

  // ---------------------------------------------------------
  // PREVIOUS PAGE
  // ---------------------------------------------------------

  void previousPage() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });

      pageController.previousPage(
        duration:
            const Duration(
          milliseconds: 300,
        ),
        curve: Curves.easeInOut,
      );
    }
  }

  // ---------------------------------------------------------
  // INPUT FIELD
  // ---------------------------------------------------------

  Widget inputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType =
        TextInputType.text,
    bool obscureText = false,
    VoidCallback? onVisibilityToggle,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: !isRegistering,
      decoration: InputDecoration(
        labelText: label,

        prefixIcon: Icon(icon),

        suffixIcon:
            onVisibilityToggle != null
                ? IconButton(
                    onPressed:
                        isRegistering
                            ? null
                            : onVisibilityToggle,
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  )
                : null,

        filled: true,

        fillColor:
            Appcolors.background,

        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide:
              const BorderSide(
            color: Appcolors.border,
          ),
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide:
              const BorderSide(
            color:
                Appcolors.secondaryText,
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide:
              const BorderSide(
            color:
                Appcolors.primary,
            width: 2,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            Appcolors.primary,

        foregroundColor:
            Appcolors.primaryText,

        centerTitle: true,

        title: const Text(
          'Create Account',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: Column(
        children: [
          // =================================================
          // STEP INDICATOR
          // =================================================

          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 25,
              vertical: 20,
            ),

            child: Row(
              children: [
                stepIndicator(
                  number: '1',
                  title: 'Account',
                  active:
                      currentStep >= 0,
                ),

                Expanded(
                  child:
                      Container(
                    height: 2,
                    color:
                        currentStep >= 1
                            ? Appcolors.primary
                            : Appcolors.surface,
                  ),
                ),

                stepIndicator(
                  number: '2',
                  title: 'Personal',
                  active:
                      currentStep >= 1,
                ),

                Expanded(
                  child:
                      Container(
                    height: 2,
                    color:
                        currentStep >= 2
                            ? Appcolors.primary
                            : Appcolors.surface,
                  ),
                ),

                stepIndicator(
                  number: '3',
                  title: 'Emergency',
                  active:
                      currentStep >= 2,
                ),
              ],
            ),
          ),

          // =================================================
          // PAGES
          // =================================================

          Expanded(
            child: PageView(
              controller:
                  pageController,

              physics:
                  const NeverScrollableScrollPhysics(),

              children: [
                accountPage(),
                personalPage(),
                emergencyPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // STEP INDICATOR
  // ---------------------------------------------------------

  Widget stepIndicator({
    required String number,
    required String title,
    required bool active,
  }) {
    return Column(
      children: [
        CircleAvatar(
          radius: 18,

          backgroundColor:
              active
                  ? Appcolors.primary
                  : Appcolors.surface,

          child: Text(
            number,

            style: TextStyle(
              color:
                  active
                      ? Colors.white
                      : Appcolors.primaryText,

              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(
          height: 5,
        ),

        Text(
          title,

          style: TextStyle(
            fontSize: 12,

            fontWeight:
                active
                    ? FontWeight.bold
                    : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // STEP 1 - ACCOUNT
  // =========================================================

  Widget accountPage() {
    return SingleChildScrollView(
      padding:
          const EdgeInsets.all(24),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Text(
            'Step 1',

            style: TextStyle(
              color:
                  Appcolors.deepBlue,

              fontSize: 15,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          const Text(
            'Create your account',

            style: TextStyle(
              fontSize: 28,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            'Enter your basic account information.',

            style: TextStyle(
              color:
                  Appcolors.secondaryText,

              fontSize: 15,
            ),
          ),

          const SizedBox(
            height: 25,
          ),

          inputField(
            label: 'Full Name',
            icon: Icons.person,
            controller:
                fullNameController,
          ),

          const SizedBox(
            height: 16,
          ),

          inputField(
            label: 'Email Address',
            icon: Icons.email,
            controller:
                emailController,
            keyboardType:
                TextInputType.emailAddress,
          ),

          const SizedBox(
            height: 16,
          ),

          inputField(
            label: 'Phone Number',
            icon: Icons.phone,
            controller:
                phoneController,
            keyboardType:
                TextInputType.phone,
          ),

          const SizedBox(
            height: 16,
          ),

          inputField(
            label: 'Password',
            icon: Icons.lock,
            controller:
                passwordController,
            obscureText:
                obscurePassword,
            onVisibilityToggle: () {
              setState(() {
                obscurePassword =
                    !obscurePassword;
              });
            },
          ),

          const SizedBox(
            height: 16,
          ),

          inputField(
            label: 'Confirm Password',
            icon:
                Icons.lock_outline,
            controller:
                confirmPasswordController,
            obscureText:
                obscureConfirmPassword,
            onVisibilityToggle: () {
              setState(() {
                obscureConfirmPassword =
                    !obscureConfirmPassword;
              });
            },
          ),

          const SizedBox(
            height: 30,
          ),

          SizedBox(
            width:
                double.infinity,

            height: 55,

            child:
                ElevatedButton(
              onPressed:
                  isRegistering
                      ? null
                      : nextPage,

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Appcolors.primary,

                foregroundColor:
                    Appcolors.primaryText,

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),

              child:
                  const Text(
                'NEXT  →',

                style:
                    TextStyle(
                  fontSize: 16,

                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // STEP 2 - PERSONAL INFORMATION
  // =========================================================

  Widget personalPage() {
    return SingleChildScrollView(
      padding:
          const EdgeInsets.all(24),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Text(
            'Step 2',

            style: TextStyle(
              color:
                  Appcolors.primary,

              fontSize: 15,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          const Text(
            'Personal Information',

            style: TextStyle(
              fontSize: 28,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            'Enter your personal and address details.',

            style: TextStyle(
              color:
                  Appcolors.secondaryText,

              fontSize: 15,
            ),
          ),

          const SizedBox(
            height: 25,
          ),

          // =================================================
          // DATE OF BIRTH
          // =================================================

          TextFormField(
            readOnly: true,

            enabled:
                !isRegistering,

            onTap:
                isRegistering
                    ? null
                    : selectDate,

            decoration:
                InputDecoration(
              labelText:
                  'Date of Birth',

              prefixIcon:
                  const Icon(
                Icons.calendar_month,
              ),

              filled: true,

              fillColor:
                  Colors.grey.shade50,

              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
            ),

            controller:
                TextEditingController(
              text:
                  dateOfBirth == null
                      ? ''
                      : '${dateOfBirth!.day}/'
                          '${dateOfBirth!.month}/'
                          '${dateOfBirth!.year}',
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          // =================================================
          // GENDER
          // =================================================

          DropdownButtonFormField<String>(
            initialValue:
                selectedGender,

            decoration:
                InputDecoration(
              labelText:
                  'Gender',

              prefixIcon:
                  const Icon(
                Icons.person_outline,
              ),

              filled: true,

              fillColor:
                  Colors.grey.shade50,

              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
            ),

            items:
                genderOptions.entries
                    .map(
              (
                MapEntry<String, String>
                    entry,
              ) {
                return DropdownMenuItem<
                    String>(
                  value:
                      entry.key,

                  child:
                      Text(
                    entry.value,
                  ),
                );
              },
            ).toList(),

            onChanged:
                isRegistering
                    ? null
                    : (
                        String? value,
                      ) {
                        setState(() {
                          selectedGender =
                              value;
                        });
                      },
          ),

          const SizedBox(
            height: 16,
          ),

          // =================================================
          // BLOOD GROUP
          // =================================================

          DropdownButtonFormField<String>(
            initialValue:
                selectedBloodGroup,

            decoration:
                InputDecoration(
              labelText:
                  'Blood Group',

              prefixIcon:
                  const Icon(
                Icons.bloodtype,
              ),

              filled: true,

              fillColor:
                  Colors.grey.shade50,

              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
            ),

            items:
                bloodGroups.map(
              (
                String group,
              ) {
                return DropdownMenuItem<
                    String>(
                  value:
                      group,

                  child:
                      Text(
                    group,
                  ),
                );
              },
            ).toList(),

            onChanged:
                isRegistering
                    ? null
                    : (
                        String? value,
                      ) {
                        setState(() {
                          selectedBloodGroup =
                              value;
                        });
                      },
          ),

          const SizedBox(
            height: 16,
          ),

          inputField(
            label:
                'House No.',
            icon:
                Icons.home,
            controller:
                houseController,
          ),

          const SizedBox(
            height: 16,
          ),

          inputField(
            label:
                'Town / Locality',
            icon:
                Icons.location_on,
            controller:
                townController,
          ),

          const SizedBox(
            height: 16,
          ),

          inputField(
            label:
                'City',
            icon:
                Icons.location_city,
            controller:
                cityController,
          ),

          const SizedBox(
            height: 16,
          ),

          inputField(
            label:
                'State',
            icon:
                Icons.map,
            controller:
                stateController,
          ),

          const SizedBox(
            height: 16,
          ),

          inputField(
            label:
                'PIN Code',
            icon:
                Icons.pin_drop,
            controller:
                pinController,
            keyboardType:
                TextInputType.number,
          ),

          const SizedBox(
            height: 30,
          ),

          // =================================================
          // BACK + NEXT
          // =================================================

          Row(
            children: [
              Expanded(
                child:
                    OutlinedButton(
                  onPressed:
                      isRegistering
                          ? null
                          : previousPage,

                  style:
                      OutlinedButton.styleFrom(
                    minimumSize:
                        const Size(
                      double.infinity,
                      55,
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),

                  child:
                      const Text(
                    '←  BACK',
                  ),
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child:
                    ElevatedButton(
                  onPressed:
                      isRegistering
                          ? null
                          : nextPage,

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        Appcolors.primary,

                    foregroundColor:
                        Appcolors.primaryText,

                    minimumSize:
                        const Size(
                      double.infinity,
                      55,
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),

                  child:
                      const Text(
                    'NEXT  →',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }

  // =========================================================
  // STEP 3 - EMERGENCY CONTACT
  // =========================================================

  Widget emergencyPage() {
    return SingleChildScrollView(
      padding:
          const EdgeInsets.all(24),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Text(
            'Step 3',

            style: TextStyle(
              color:
                  Appcolors.primary,

              fontSize: 15,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          const Text(
            'Emergency Contact',

            style: TextStyle(
              fontSize: 28,

              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            'Add a trusted contact for emergencies.',

            style: TextStyle(
              color:
                  Appcolors.secondaryText,

              fontSize: 15,
            ),
          ),

          const SizedBox(
            height: 25,
          ),

          inputField(
            label:
                'Contact Name',
            icon:
                Icons.person_outline,
            controller:
                contactNameController,
          ),

          const SizedBox(
            height: 16,
          ),

          inputField(
            label:
                'Contact Number',
            icon:
                Icons.phone,
            controller:
                contactNumberController,
            keyboardType:
                TextInputType.phone,
          ),

          const SizedBox(
            height: 16,
          ),

          inputField(
            label:
                'Emergency Dial Number',
            icon:
                Icons.emergency,
            controller:
                emergencyDialController,
            keyboardType:
                TextInputType.phone,
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            'This number is kept locally for your emergency UI. '
            'The registration API does not have a separate '
            'emergency dial number field.',

            style: TextStyle(
              color:
                  Appcolors.secondaryText,

              fontSize: 11,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          // =================================================
          // INFORMATION BOX
          // =================================================

          Container(
            padding:
                const EdgeInsets.all(15),

            decoration:
                BoxDecoration(
              color:
                  Appcolors.deepBlue,

              borderRadius:
                  BorderRadius.circular(
                14,
              ),

              border:
                  Border.all(
                color:
                    Appcolors.primary,
              ),
            ),

            child:
                Row(
              children: [
                Icon(
                  Icons.info_outline,

                  color:
                      Appcolors.warning,
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child:
                      Text(
                    'Make sure the emergency contact number '
                    'is correct and reachable.',

                    style:
                        TextStyle(
                      color:
                          Appcolors.warning,

                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 30,
          ),

          // =================================================
          // BACK + REGISTER
          // =================================================

          Row(
            children: [
              Expanded(
                child:
                    OutlinedButton(
                  onPressed:
                      isRegistering
                          ? null
                          : previousPage,

                  style:
                      OutlinedButton.styleFrom(
                    minimumSize:
                        const Size(
                      double.infinity,
                      55,
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),

                  child:
                      const Text(
                    '←  BACK',
                  ),
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child:
                    ElevatedButton(
                  onPressed:
                      isRegistering
                          ? null
                          : nextPage,

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        Appcolors.primary,

                    foregroundColor:
                        Appcolors.primaryText,

                    minimumSize:
                        const Size(
                      double.infinity,
                      55,
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),

                  child:
                      isRegistering
                          ? const SizedBox(
                              height: 22,
                              width: 22,

                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2.5,

                                color:
                                    Colors.white,
                              ),
                            )
                          : const Text(
                              'REGISTER',
                            ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 30,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // DISPOSE
  // ---------------------------------------------------------

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    houseController.dispose();
    townController.dispose();
    cityController.dispose();
    stateController.dispose();
    pinController.dispose();

    contactNameController.dispose();
    contactNumberController.dispose();
    emergencyDialController.dispose();

    pageController.dispose();

    super.dispose();
  }
}