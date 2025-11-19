// import 'package:flutter/material.dart';
// import 'Loginpage.dart';
// import 'auth_services.dart';
//
//
// class SignupScreen extends StatefulWidget {
//   const SignupScreen({super.key});
//
//   @override
//   State<SignupScreen> createState() => _SignupScreenState();
// }
//
// class _SignupScreenState extends State<SignupScreen> {
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _authService = AuthService();
//
//   void _signup() async {
//     try {
//       await _authService.signup(_emailController.text.trim(), _passwordController.text.trim());
//       ScaffoldMessenger.of(context).showSn
//       ackBar(const SnackBar(content: Text("Account created. Please log in.")));
//       Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Signup failed: $e")));
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Sign Up")),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           children: [
//             TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email")),
//             TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
//             const SizedBox(height: 20),
//             ElevatedButton(onPressed: _signup, child: const Text("Create Account")),
//             TextButton(
//               onPressed: () {
//                 Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
//               },
//               child: const Text("Already have an account? Log in"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import for UserCredential and FirebaseAuthException
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for Firestore
import 'Loginpage.dart';
import 'auth_services.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  void _signup() async {
    try {
      final roll = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (roll.isEmpty || password.isEmpty) {
        // You can make this throw a more specific exception for better handling
        throw ArgumentError("Roll number and password cannot be empty.");
      }

      // remove spaces/newlines just in case
      final cleanRoll = roll.replaceAll(" ", "").replaceAll("\n", "");

      // THIS IS WHERE @gmail.com IS APPENDED
      final email = "$cleanRoll@gmail.com";

      // 1. Perform Firebase Authentication signup
      // IMPORTANT: Your _authService.signup method MUST return Future<UserCredential>
      final UserCredential userCredential = await _authService.signup(email, password);
      final User? user = userCredential.user;

      if (user == null) {
        throw Exception("User was not created by Firebase Authentication.");
      }

      // 2. Create the corresponding /students/{rollNumber} document in Firestore
      // This links the rollNumber to the Firebase Auth UID, crucial for security rules.
      await FirebaseFirestore.instance.collection('students').doc(cleanRoll).set({
        'firebaseAuthUid': user.uid,
        // You can add other initial student data here if needed,
        // e.g., 'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully. Please log in.")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      String errorMessage = "Signup failed: $e";
      if (e is FirebaseAuthException) {
        errorMessage = "Signup failed: ${e.message}";
      } else if (e is ArgumentError) {
        errorMessage = "Signup failed: ${e.message}";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00A64F), // Green background
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 60),
            // Food banner image (replace with your asset)
            SizedBox(
              height: 300,
              child: Image.asset("assets/waste1.png"),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Sign Up",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Email field (used for Roll Number input)
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person_outline), // Changed icon to person for roll number
                      hintText: "Roll Number",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    keyboardType: TextInputType.number, // Suggest numeric keyboard
                  ),
                  const SizedBox(height: 15),

                  // Password field
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.lock_outline),
                      hintText: "Password",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Create Account button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _signup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A64F),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Create Account",
                        style: TextStyle(fontSize: 16, color: Colors.white), // Added white color for text
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Terms & Privacy
                  const Text(
                    "By signing up, you agree to the Terms of Use and Privacy Policy.", // Generic text
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),

                  const SizedBox(height: 20),

                  // Social buttons (kept as is, though not tied to Firebase Auth here)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.facebook, color: Colors.blue),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.g_mobiledata, color: Colors.red),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.apple, color: Colors.black),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                          );
                        },
                        child: const Text(
                          "Log in",
                          style: TextStyle(
                              color: Color(0xFF00A64F),
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

