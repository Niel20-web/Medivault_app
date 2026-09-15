import 'package:flutter/material.dart';

import '../utils/appcolors.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  DateTime? selectedDate;
  String? selectedBloodGroup;

  // Date of Birth Picker
  Future<void> selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.background,

      appBar: AppBar(
        title: const Text(
          'Registration',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                'Create Your Profile',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Please enter your details below.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 25),

              // Full Name
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Date of Birth
              TextFormField(
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth',
                  prefixIcon: Icon(Icons.calendar_month),
                ),
                controller: TextEditingController(
                  text: selectedDate == null
                      ? ''
                      : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                ),
                onTap: selectDate,
                validator: (value) {
                  if (selectedDate == null) {
                    return 'Please select your date of birth';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Phone Number
              TextFormField(
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }

                  if (value.length != 10) {
                    return 'Enter a valid 10-digit phone number';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Email
              TextFormField(
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }

                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Password
              TextFormField(
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }

                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Town / Locality
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Town / Locality',
                  prefixIcon: Icon(Icons.location_city),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your town/locality';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // House Number
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'House No.',
                  prefixIcon: Icon(Icons.home),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your house number';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // State
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'State',
                  prefixIcon: Icon(Icons.map),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your state';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // City
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'City',
                  prefixIcon: Icon(Icons.map),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your city';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // PIN Code
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'PIN Code',
                  prefixIcon: Icon(Icons.pin_drop),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your PIN code';
                  }

                  if (value.length != 6) {
                    return 'Enter a valid 6-digit PIN code';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Blood Group
              DropdownButtonFormField<String>(
                value: selectedBloodGroup,

                decoration: const InputDecoration(
                  labelText: 'Blood Group',
                  prefixIcon: Icon(Icons.bloodtype),
                ),

                items: bloodGroups.map((group) {
                  return DropdownMenuItem(
                    value: group,
                    child: Text(group),
                  );
                }).toList(),

                onChanged: (value) {
                  setState(() {
                    selectedBloodGroup = value;
                  });
                },

                validator: (value) {
                  if (value == null) {
                    return 'Please select your blood group';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Emergency Contact Number
              TextFormField(
                keyboardType: TextInputType.phone,

                decoration: const InputDecoration(
                  labelText: 'Emergency Contact Number',
                  prefixIcon: Icon(Icons.emergency),
                  hintText: 'Example: 112',
                ),

                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an emergency number';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 30),

              // Register Button
              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Appcolors.primary,
                    foregroundColor: Colors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Registration successful!',
                          ),
                        ),
                      );
                    }
                  },

                  child: const Text(
                    'REGISTER',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}