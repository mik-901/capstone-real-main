//
//
//
//
// import 'package:flutter/material.dart';
// import 'package:mitush/signup.dart';
// import '../main.dart';
// import 'auth_services.dart';
// import 'home.dart';
//
//
//
// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});
//
//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }
//
// class _LoginScreenState extends State<LoginScreen> {
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _authService = AuthService();
//
//
//   void _login() async {
//     try {
//       String email = _emailController.text.trim();
//       await _authService.login(email, _passwordController.text.trim());
//
//       // Extract username from email (before @)
//       String username = email.split('@')[0];
//
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) => HomePage(
//             username: username,
//             rollNumber: email,
//           ),
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Login failed: $e")));
//     }
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Login")),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           children: [
//             TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email")),
//             TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
//             const SizedBox(height: 20),
//             ElevatedButton(onPressed: _login, child: const Text("Login")),
//             TextButton(
//               onPressed: () {
//                 Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen()));
//               },
//               child: const Text("Don't have an account? Sign up"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:mitush/signup.dart';
import 'auth_services.dart';
import 'home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  void _login() async {
    try {
      final roll = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (roll.isEmpty || password.isEmpty) {
        throw "Roll number and password cannot be empty";
      }

      // Remove spaces/newlines
      final cleanRoll = roll.replaceAll(" ", "").replaceAll("\n", "");

      // Convert roll → hidden email
      final email = "$cleanRoll@gmail.com";

      // Firebase login
      await _authService.login(email, password);

      // Extract username (roll number)
      String username = cleanRoll;

      // Navigate exactly like before
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(
            username: username,
            email: email,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: $e")),
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
                    "Sign In",
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

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Forgot password
                      },
                      child: const Text("Forgot your Password?"),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A64F),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Continue",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Terms & Privacy
                  const Text(
                    "By login, you agree to Ticketspace's Terms of Use and Privacy Policy.",
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

                  // Signup link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("You don’t have an account? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SignupScreen()),
                          );
                        },
                        child: const Text(
                          "Sign Up!",
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
