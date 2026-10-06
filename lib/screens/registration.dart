import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/appcolors.dart';

// ---------------------------------------------------------
// REGISTRATION PAGE
// ---------------------------------------------------------

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  // Auth service
  final AuthService _authService = AuthService();

  // Controllers
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final houseController = TextEditingController();
  final townController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final pinController = TextEditingController();

  final contactNameController = TextEditingController();
  final contactNumberController = TextEditingController();
  final emergencyDialController = TextEditingController();

  // Page controller
  final PageController pageController = PageController();

  int currentStep = 0;

  // Registration loading state
  bool isRegistering = false;

  // Password visibility
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  // Blood group
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
  ];

  // Gender
  String? selectedGender;

  final List<String> genders = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
  ];

  // Date of birth
  DateTime? dateOfBirth;

  // ---------------------------------------------------------
  // DATE PICKER
  // ---------------------------------------------------------

  Future<void> selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        dateOfBirth = pickedDate;
      });
    }
  }

  // ---------------------------------------------------------
  // GENERATE USERNAME
  // ---------------------------------------------------------

  String generateUsername() {
    final email = emailController.text.trim();

    if (email.contains('@')) {
      return email.split('@').first;
    }

    return email;
  }

  // ---------------------------------------------------------
  // SPLIT FULL NAME
  // ---------------------------------------------------------

  List<String> splitFullName() {
    final fullName = fullNameController.text.trim();

    final parts = fullName.split(RegExp(r'\s+'));

    if (parts.length < 2) {
      return [fullName, ''];
    }

    final firstName = parts.first;
    final lastName = parts.sublist(1).join(' ');

    return [firstName, lastName];
  }

  // ---------------------------------------------------------
  // SHOW MESSAGE
  // ---------------------------------------------------------

  void showMessage(
    String message, {
    bool isError = true,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Appcolors.error : Appcolors.success,
      ),
    );
  }

  // ---------------------------------------------------------
  // REGISTER ACCOUNT
  // ---------------------------------------------------------

  Future<void> registerAccount() async {
    // -----------------------------
    // BASIC VALIDATION
    // -----------------------------

    if (fullNameController.text.trim().isEmpty) {
      showMessage('Please enter your full name.');
      return;
    }

    final nameParts = splitFullName();

    // Backend requires both firstName and lastName
    if (nameParts[0].trim().isEmpty ||
        nameParts[1].trim().isEmpty) {
      showMessage(
        'Please enter your first and last name.',
      );
      return;
    }

    if (emailController.text.trim().isEmpty) {
      showMessage('Please enter your email address.');
      return;
    }

    if (passwordController.text.isEmpty) {
      showMessage('Please enter a password.');
      return;
    }

    if (passwordController.text.length < 8) {
      showMessage(
        'Password must be at least 8 characters.',
      );
      return;
    }

    if (confirmPasswordController.text.isEmpty) {
      showMessage('Please confirm your password.');
      return;
    }

    if (passwordController.text !=
        confirmPasswordController.text) {
      showMessage('Passwords do not match.');
      return;
    }

    // -----------------------------
    // PERSONAL INFORMATION
    // -----------------------------

    if (dateOfBirth == null) {
      showMessage('Please select your date of birth.');
      return;
    }

    if (selectedGender == null) {
      showMessage('Please select your gender.');
      return;
    }

    if (selectedBloodGroup == null) {
      showMessage('Please select your blood group.');
      return;
    }

    // -----------------------------
    // ADDRESS
    // -----------------------------

    if (houseController.text.trim().isEmpty) {
      showMessage('Please enter your house number.');
      return;
    }

    if (townController.text.trim().isEmpty) {
      showMessage('Please enter your town or locality.');
      return;
    }

    if (cityController.text.trim().isEmpty) {
      showMessage('Please enter your city.');
      return;
    }

    if (stateController.text.trim().isEmpty) {
      showMessage('Please enter your state.');
      return;
    }

    if (pinController.text.trim().isEmpty) {
      showMessage('Please enter your PIN code.');
      return;
    }

    // -----------------------------
    // EMERGENCY CONTACT
    // -----------------------------

    if (contactNameController.text.trim().isEmpty) {
      showMessage('Please enter the emergency contact name.');
      return;
    }

    if (contactNumberController.text.trim().isEmpty) {
      showMessage(
        'Please enter the emergency contact number.',
      );
      return;
    }

    // -----------------------------
    // START REGISTRATION
    // -----------------------------

    setState(() {
      isRegistering = true;
    });

    try {
      await _authService.register(
        email: emailController.text.trim(),
        username: generateUsername(),
        password: passwordController.text,
        firstName: nameParts[0].trim(),
        lastName: nameParts[1].trim(),
        phone: phoneController.text.trim(),

        identity: {
          'dateOfBirth': dateOfBirth!.toIso8601String(),

          'gender': selectedGender,

          'bloodGroup': selectedBloodGroup,

          // Backend does NOT support line2.
          // Town/locality is included in line1.
          'address': {
            'line1':
                '${houseController.text.trim()}, '
                '${townController.text.trim()}',
            'city': cityController.text.trim(),
            'state': stateController.text.trim(),
            'postalCode': pinController.text.trim(),
            'country': 'India',
          },

          'emergencyContact': {
            'name':
                contactNameController.text.trim(),
            'relationship': 'Emergency Contact',
            'phone':
                contactNumberController.text.trim(),
          },
        },
      );

      if (!mounted) return;

      showMessage(
        'Account created successfully! Please log in.',
        isError: false,
      );

      // Give the SnackBar a moment to appear
      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      showMessage(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
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
        duration: const Duration(milliseconds: 300),
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
        duration: const Duration(milliseconds: 300),
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
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    VoidCallback? onVisibilityToggle,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),

        suffixIcon: onVisibilityToggle != null
            ? IconButton(
                onPressed: onVisibilityToggle,
                icon: Icon(
                  obscureText
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
              )
            : null,

        filled: true,
        fillColor: Appcolors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Appcolors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Appcolors.secondaryText,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Appcolors.primary,
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Appcolors.primary,
        foregroundColor: Appcolors.primaryText,
        centerTitle: true,
        title: const Text(
          'Create Account',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // -------------------------------------------------
          // STEP INDICATOR
          // -------------------------------------------------

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 25,
              vertical: 20,
            ),
            child: Row(
              children: [
                stepIndicator(
                  number: '1',
                  title: 'Account',
                  active: currentStep >= 0,
                ),

                Expanded(
                  child: Container(
                    height: 2,
                    color: Appcolors.surface,
                  ),
                ),

                stepIndicator(
                  number: '2',
                  title: 'Personal',
                  active: currentStep >= 1,
                ),

                Expanded(
                  child: Container(
                    height: 2,
                    color: currentStep >= 2
                        ? Appcolors.primary
                        : Appcolors.surface,
                  ),
                ),

                stepIndicator(
                  number: '3',
                  title: 'Emergency',
                  active: currentStep >= 2,
                ),
              ],
            ),
          ),

          // -------------------------------------------------
          // PAGES
          // -------------------------------------------------

          Expanded(
            child: PageView(
              controller: pageController,
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
              color: active
                  ? Colors.white
                  : Appcolors.primaryText,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Step 1',
            style: TextStyle(
              color: Appcolors.deepBlue,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Create your account',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Enter your basic account information.',
            style: TextStyle(
              color: Appcolors.secondaryText,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 25),

          inputField(
            label: 'Full Name',
            icon: Icons.person,
            controller: fullNameController,
          ),

          const SizedBox(height: 16),

          inputField(
            label: 'Email Address',
            icon: Icons.email,
            controller: emailController,
            keyboardType:
                TextInputType.emailAddress,
          ),

          const SizedBox(height: 16),

          inputField(
            label: 'Phone Number',
            icon: Icons.phone,
            controller: phoneController,
            keyboardType: TextInputType.phone,
          ),

          const SizedBox(height: 16),

          inputField(
            label: 'Password',
            icon: Icons.lock,
            controller: passwordController,
            obscureText: obscurePassword,
            onVisibilityToggle: () {
              setState(() {
                obscurePassword =
                    !obscurePassword;
              });
            },
          ),

          const SizedBox(height: 16),

          inputField(
            label: 'Confirm Password',
            icon: Icons.lock_outline,
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

          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed:
                  isRegistering ? null : nextPage,
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Appcolors.primary,
                foregroundColor:
                    Appcolors.primaryText,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'NEXT  →',
                style: TextStyle(
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Step 2',
            style: TextStyle(
              color: Appcolors.primary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Enter your personal and address details.',
            style: TextStyle(
              color: Appcolors.secondaryText,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 25),

          // DATE OF BIRTH
          TextFormField(
            readOnly: true,
            onTap: selectDate,
            decoration: InputDecoration(
              labelText: 'Date of Birth',
              prefixIcon:
                  const Icon(Icons.calendar_month),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(14),
              ),
            ),
            controller: TextEditingController(
              text: dateOfBirth == null
                  ? ''
                  : '${dateOfBirth!.day}/'
                      '${dateOfBirth!.month}/'
                      '${dateOfBirth!.year}',
            ),
          ),

          const SizedBox(height: 16),

          // GENDER
          DropdownButtonFormField<String>(
            initialValue: selectedGender,
            decoration: InputDecoration(
              labelText: 'Gender',
              prefixIcon:
                  const Icon(Icons.person_outline),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(14),
              ),
            ),
            items: genders.map(
              (gender) {
                return DropdownMenuItem<String>(
                  value: gender,
                  child: Text(gender),
                );
              },
            ).toList(),
            onChanged: isRegistering
                ? null
                : (value) {
                    setState(() {
                      selectedGender = value;
                    });
                  },
          ),

          const SizedBox(height: 16),

          // BLOOD GROUP
          DropdownButtonFormField<String>(
            initialValue:
                selectedBloodGroup,
            decoration: InputDecoration(
              labelText: 'Blood Group',
              prefixIcon:
                  const Icon(Icons.bloodtype),
              filled: true,
              fillColor:
                  Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(14),
              ),
            ),
            items: bloodGroups.map(
              (group) {
                return DropdownMenuItem(
                  value: group,
                  child: Text(group),
                );
              },
            ).toList(),
            onChanged: isRegistering
                ? null
                : (value) {
                    setState(() {
                      selectedBloodGroup =
                          value;
                    });
                  },
          ),

          const SizedBox(height: 16),

          inputField(
            label: 'House No.',
            icon: Icons.home,
            controller: houseController,
          ),

          const SizedBox(height: 16),

          inputField(
            label: 'Town / Locality',
            icon: Icons.location_on,
            controller: townController,
          ),

          const SizedBox(height: 16),

          inputField(
            label: 'City',
            icon: Icons.location_city,
            controller: cityController,
          ),

          const SizedBox(height: 16),

          inputField(
            label: 'State',
            icon: Icons.map,
            controller: stateController,
          ),

          const SizedBox(height: 16),

          inputField(
            label: 'PIN Code',
            icon: Icons.pin_drop,
            controller: pinController,
            keyboardType:
                TextInputType.number,
          ),

          const SizedBox(height: 30),

          // BACK + NEXT
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
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
                              14),
                    ),
                  ),
                  child: const Text(
                    '←  BACK',
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: ElevatedButton(
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
                              14),
                    ),
                  ),
                  child: const Text(
                    'NEXT  →',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // =========================================================
  // STEP 3 - EMERGENCY CONTACT
  // =========================================================

  Widget emergencyPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Step 3',
            style: TextStyle(
              color: Appcolors.primary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Emergency Contact',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Add a trusted contact for emergencies.',
            style: TextStyle(
              color: Appcolors.secondaryText,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 25),

          inputField(
            label: 'Contact Name',
            icon: Icons.person_outline,
            controller:
                contactNameController,
          ),

          const SizedBox(height: 16),

          inputField(
            label: 'Contact Number',
            icon: Icons.phone,
            controller:
                contactNumberController,
            keyboardType:
                TextInputType.phone,
          ),

          const SizedBox(height: 16),

          inputField(
            label: 'Emergency Dial Number',
            icon: Icons.emergency,
            controller:
                emergencyDialController,
            keyboardType:
                TextInputType.phone,
          ),

          const SizedBox(height: 12),

          // Emergency information box
          Container(
            padding:
                const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Appcolors.deepBlue,
              borderRadius:
                  BorderRadius.circular(14),
              border: Border.all(
                color: Appcolors.primary,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Appcolors.warning,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    'Make sure the emergency contact number '
                    'is correct and reachable.',
                    style: TextStyle(
                      color:
                          Appcolors.warning,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // BACK + REGISTER
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
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
                              14),
                    ),
                  ),
                  child: const Text(
                    '←  BACK',
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: ElevatedButton(
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
                              14),
                    ),
                  ),
                  child: isRegistering
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2.5,
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

          const SizedBox(height: 30),
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