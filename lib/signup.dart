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
        throw "Roll number and password cannot be empty";
      }

      // remove spaces/newlines just in case
      final cleanRoll = roll.replaceAll(" ", "").replaceAll("\n", "");

      // 👉 THIS IS WHERE @gmail.com IS APPENDED
      final email = "$cleanRoll@gmail.com";

      await _authService.signup(email, password);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created. Please log in.")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup failed: $e")),
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

                  // Email field
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.email_outlined),
                      hintText: "Roll Number",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
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
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Terms & Privacy
                  const Text(
                    "By signing up, you agree to Ticketspace's Terms of Use and Privacy Policy.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),

                  const SizedBox(height: 20),

                  // Social buttons
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
