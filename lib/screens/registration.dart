import 'package:flutter/material.dart';
import '../utils/appcolors.dart';

void main() {
  runApp(const MyApp());
}

// ---------------------------------------------------------
// MAIN APP
// ---------------------------------------------------------

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Registration',
      theme: ThemeData(
        fontFamily: 'Arial',
        scaffoldBackgroundColor: Appcolors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Appcolors.cyan,
        ),
      ),
      home: const RegistrationPage(),
    );
  }
}

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

      // Final registration
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Registration Successful!',
          ),
        ),
      );
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
  }) {

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,

      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),

        filled: true,
        fillColor: Appcolors.background,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Appcolors.border,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
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
                    color: currentStep >= 1
                        ? Appcolors.surface
                        : Appcolors.surface,
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
              physics: const NeverScrollableScrollPhysics(),

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
              active ? Appcolors.primary : Appcolors.surface,

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
        crossAxisAlignment: CrossAxisAlignment.start,

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
            keyboardType: TextInputType.emailAddress,
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
            obscureText: true,
          ),

          const SizedBox(height: 16),

          inputField(
            label: 'Confirm Password',
            icon: Icons.lock_outline,
            controller: confirmPasswordController,
            obscureText: true,
          ),

          const SizedBox(height: 30),

          // NEXT BUTTON

          SizedBox(
            width: double.infinity,
            height: 55,

            child: ElevatedButton(
              onPressed: nextPage,

              style: ElevatedButton.styleFrom(
                backgroundColor: Appcolors.primary,
                foregroundColor: Appcolors.primaryText,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),

              child: const Text(
                'NEXT  →',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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
        crossAxisAlignment: CrossAxisAlignment.start,

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
              prefixIcon: const Icon(
                Icons.calendar_month,
              ),

              filled: true,
              fillColor: Colors.grey.shade50,

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
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

          // BLOOD GROUP

          DropdownButtonFormField<String>(

            value: selectedBloodGroup,

            decoration: InputDecoration(
              labelText: 'Blood Group',
              prefixIcon: const Icon(
                Icons.bloodtype,
              ),

              filled: true,
              fillColor: Colors.grey.shade50,

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
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

            onChanged: (value) {

              setState(() {
                selectedBloodGroup = value;
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
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 30),

          // BACK + NEXT

          Row(
            children: [

              Expanded(
                child: OutlinedButton(
                  onPressed: previousPage,

                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(
                      double.infinity,
                      55,
                    ),

                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
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
                  onPressed: nextPage,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Appcolors.primary,
                    foregroundColor: Appcolors.primaryText,

                    minimumSize: const Size(
                      double.infinity,
                      55,
                    ),

                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
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
        crossAxisAlignment: CrossAxisAlignment.start,

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
            controller: contactNameController,
          ),

          const SizedBox(height: 16),

          inputField(
            label: 'Contact Number',
            icon: Icons.phone,
            controller: contactNumberController,
            keyboardType: TextInputType.phone,
          ),

          const SizedBox(height: 16),

          inputField(
            label: 'Emergency Dial Number',
            icon: Icons.emergency,
            controller: emergencyDialController,
            keyboardType: TextInputType.phone,
          ),

          const SizedBox(height: 12),

          // Emergency information box

          Container(
            padding: const EdgeInsets.all(15),

            decoration: BoxDecoration(
              color: Appcolors.deepBlue,

              borderRadius: BorderRadius.circular(14),

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
                      color: Appcolors.warning,
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
                  onPressed: previousPage,

                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(
                      double.infinity,
                      55,
                    ),

                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
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
                  onPressed: nextPage,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Appcolors.primary,
                    foregroundColor: Appcolors.primaryText,

                    minimumSize: const Size(
                      double.infinity,
                      55,
                    ),

                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),

                  child: const Text(
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
