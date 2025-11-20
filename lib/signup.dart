import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  Future<void> _signup() async {
    try {
      final roll = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (roll.isEmpty || password.isEmpty) {
        throw ArgumentError("Roll number and password cannot be empty.");
      }

      final cleanRoll = roll.replaceAll(" ", "").replaceAll("\n", "");
      final email = "$cleanRoll@gmail.com";

      final UserCredential userCredential =
      await _authService.signup(email, password);

      final User? user = userCredential.user;
      if (user == null) throw Exception("User not created.");

      await FirebaseFirestore.instance
          .collection('students')
          .doc(cleanRoll)
          .set({
        'firebaseAuthUid': user.uid,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully.")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      String errorMessage = e is FirebaseAuthException
          ? e.message ?? "Signup failed"
          : e.toString();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup failed: $errorMessage")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00A64F),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints:
                BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Responsive Banner Image
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.28,
                      child: Image.asset("assets/waste1.png",
                          fit: BoxFit.contain),
                    ),

                    const SizedBox(height: 10),

                    Container(
                      width: double.infinity,
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
                                fontSize: 26, fontWeight: FontWeight.bold),
                          ),

                          const SizedBox(height: 20),

                          // ROLL NUMBER
                          TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.person_outline),
                              hintText: "Roll Number",
                              border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.all(Radius.circular(12)),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),

                          const SizedBox(height: 15),

                          // PASSWORD
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.lock_outline),
                              hintText: "Password",
                              border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.all(Radius.circular(12)),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // CREATE ACCOUNT BUTTON
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _signup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00A64F),
                                padding:
                                const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Create Account",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          const Center(
                            child: Text(
                              "By signing up, you agree to the Terms of Use and Privacy Policy.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // LOGIN LINK
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Already have an account? "),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                        const LoginScreen()),
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
                          ),

                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
