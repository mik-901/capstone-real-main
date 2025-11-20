import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'analysis.dart';
import 'contact.dart';
import 'Loginpage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_services.dart';
import 'meal_details.dart';
import 'package:fl_chart/fl_chart.dart';

class HomePage extends StatefulWidget {
  final String username; // rollNumber
  final String email;
  final String uid;

  const HomePage({
    super.key,
    required this.username,
    required this.email,
    required this.uid,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String _title = 'Home';

  // today's data
  double totalBreakfastWasted = 0.0;
  double totalLunchWasted = 0.0;
  double totalDinnerWasted = 0.0;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _fetchMealWastageData();
  }

  /// Loads today's totals for the logged-in user
  Future<void> _fetchMealWastageData() async {
    try {
      double breakfast = 0.0;
      double lunch = 0.0;
      double dinner = 0.0;

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

      final QuerySnapshot<Map<String, dynamic>> snapshot =
      await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.username)
          .collection('foodWaste')
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timestamp', isLessThanOrEqualTo: endOfDay)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final int? mealSlot = data['mealSlot'];
        final double? weight = (data['weight'] as num?)?.toDouble();
        if (mealSlot == null || weight == null) continue;

        if (mealSlot == 1) breakfast += weight;
        if (mealSlot == 2) lunch += weight;
        if (mealSlot == 3) dinner += weight;
      }

      if (!mounted) return;

      setState(() {
        totalBreakfastWasted = breakfast;
        totalLunchWasted = lunch;
        totalDinnerWasted = dinner;
      });

    } catch (e) {
      print("Error loading food waste: $e");
    }
  }

  // ------------------------  UI SECTION  -----------------------

  Widget _buildUserHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.green.shade600,
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Roll No: ${widget.username}",
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard(String meal, double wasted, IconData icon, Color color) {
    int slot = (meal == "Breakfast") ? 1 : (meal == "Lunch") ? 2 : 3;

    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MealDetailsPage(
                rollNumber: widget.username,
                mealSlot: slot,
              ),
            ),
          );
        },
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color),
          ),
          title: Text(meal,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          trailing: Text(
            '${wasted.toStringAsFixed(2)} g',
            style: const TextStyle(fontSize: 14, color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildPieChartCard() {
    final double b = totalBreakfastWasted;
    final double l = totalLunchWasted;
    final double d = totalDinnerWasted;
    final double total = b + l + d;

    if (total == 0) {
      return const Center(
        child: Text(
          "No food wasted today.",
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Today's Waste Distribution",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      value: b,
                      color: Colors.orange,
                      title: "${((b / total) * 100).toStringAsFixed(1)}%",
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    PieChartSectionData(
                      value: l,
                      color: Colors.blue,
                      title: "${((l / total) * 100).toStringAsFixed(1)}%",
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    PieChartSectionData(
                      value: d,
                      color: Colors.purple,
                      title: "${((d / total) * 100).toStringAsFixed(1)}%",
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _legendItem(Colors.orange, "Breakfast"),
                _legendItem(Colors.blue, "Lunch"),
                _legendItem(Colors.purple, "Dinner"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserHeader(),
          const SizedBox(height: 20),
          _buildMealCard('Breakfast', totalBreakfastWasted, Icons.free_breakfast, Colors.orange),
          _buildMealCard('Lunch', totalLunchWasted, Icons.lunch_dining, Colors.blue),
          _buildMealCard('Dinner', totalDinnerWasted, Icons.dinner_dining, Colors.purple),
          const SizedBox(height: 25),
          _buildPieChartCard(),
        ],
      ),
    );
  }

  // ------------------------ NAVIGATION / LOGOUT ------------------------

  void _logout() async {
    bool confirmation = await _showLogoutDialog();
    if (confirmation) {
      await _authService.logout();
      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  Future<bool> _showLogoutDialog() async {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Logout")),
        ],
      ),
    ).then((value) => value ?? false);
  }

  @override
  Widget build(BuildContext context) {
    Widget activePage;

    switch (_selectedIndex) {
      case 1:
        activePage = AnalysisPage(
          username: widget.username,
          rollNumber: widget.username,
          uid: widget.uid,
        );
        break;
      case 2:
        activePage = const ContactPage();
        break;
      default:
        activePage = _buildHomeContent();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_title, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchMealWastageData),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Colors.lightGreenAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),

      body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: activePage),

      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Analysis'),
          BottomNavigationBarItem(icon: Icon(Icons.contact_mail), label: 'Contact'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: (i) {
          setState(() {
            _selectedIndex = i;
            _title =
            (i == 0) ? 'Home' : (i == 1) ? 'Analysis' : 'Contact';
          });
        },
      ),
    );
  }
}
