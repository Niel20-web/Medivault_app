import 'package:flutter/material.dart';

//import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';

void main() {
	runApp(const MedivaultApp());
}

class MedivaultApp extends StatelessWidget {
	const MedivaultApp({super.key});

	@override
	Widget build(BuildContext context) {
		return const MaterialApp(
			home: login_screen(),
		);
	}
}

