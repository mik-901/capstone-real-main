import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'analysis.dart';
import 'contact.dart';
import 'Loginpage.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for Firestore
import 'auth_services.dart'; // Import AuthService for logout

// REMOVE: import 'db_service.dart'; // <-- This service will no longer be used directly here

class HomePage extends StatefulWidget {
  final String username; // This is actually the rollNumber
  final String email;
  final String uid; // <-- NEW: Add uid parameter

  const HomePage({
    super.key,
    required this.username,
    required this.email,
    required this.uid, // <-- NEW: uid is now required
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String _title = 'Home';

  // date/time strings
  String formattedDate = DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now());
  String formattedTime = DateFormat('hh:mm a').format(DateTime.now());

  // today's totals
  double totalBreakfastWasted = 0.0;
  double totalLunchWasted = 0.0;
  double totalDinnerWasted = 0.0;

  final AuthService _authService = AuthService(); // Initialize AuthService for logout

  // REMOVE: final FirestoreService _db = FirestoreService(); // This service will no longer be used directly here

  @override
  void initState() {
    super.initState();
    _fetchMealWastageData();
    _updateTime();
  }

  void _updateTime() {
    Future.delayed(const Duration(minutes: 1), () {
      if (!mounted) return;
      setState(() {
        formattedTime = DateFormat('hh:mm a').format(DateTime.now());
        formattedDate = DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now());
      });
      _updateTime();
    });
  }

  /// Loads today's totals for the logged-in user using direct Firestore query.
  Future<void> _fetchMealWastageData() async {
    try {
      double breakfast = 0.0;
      double lunch = 0.0;
      double dinner = 0.0;

      final now = DateTime.now();
      // Define the start and end of the current day for the query
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999); // Include milliseconds for full day

      // Query Firestore for food waste data specific to this user's roll number and today's date
      final QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.username) // Use widget.username as the rollNumber document ID
          .collection('foodWaste')
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timestamp', isLessThanOrEqualTo: endOfDay)
          .get();

      print("DEBUG: found ${snapshot.docs.length} docs for roll number ${widget.username} for today.");

      for (final doc in snapshot.docs) {
        final data = doc.data(); // Get the data map from the document
        print("DEBUG: raw doc => $data");

        // Access fields using the new names: 'mealSlot' (String) and 'weight' (double)
        final String? mealSlot = data['mealSlot'] as String?;
        // Ensure weight is treated as a num first, then converted to double to handle potential int or double from Firestore
        final double? weight = (data['weight'] as num?)?.toDouble();

        if (mealSlot == null || weight == null) {
          print("DEBUG: Document with ID ${doc.id} has missing 'mealSlot' or 'weight' field. Skipping.");
          continue; // Skip this document if data is incomplete
        }

        if (mealSlot == 'Breakfast') {
          breakfast += weight;
        } else if (mealSlot == 'Lunch') {
          lunch += weight;
        } else if (mealSlot == 'Dinner') {
          dinner += weight;
        } else {
          print("DEBUG: unknown mealSlot: $mealSlot for doc ${doc.id}. Skipping.");
        }
      }

      if (!mounted) return;

      setState(() {
        totalBreakfastWasted = breakfast;
        totalLunchWasted = lunch;
        totalDinnerWasted = dinner;
      });

      print("TOTALS → Breakfast: $breakfast, Lunch: $lunch, Dinner: $dinner");

    } catch (e, st) {
      print("Error fetching meal wastage data: $e\n$st");
      if (!mounted) return;
      setState(() {
        totalBreakfastWasted = 0.0;
        totalLunchWasted = 0.0;
        totalDinnerWasted = 0.0;
      });
    }
  }

  Widget _buildHomeContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildUserCard()),
              const SizedBox(width: 40),
              Expanded(child: _buildTimeCard()),
            ],
          ),
          const SizedBox(height: 20),
          _buildMealCard('Breakfast', totalBreakfastWasted, Icons.free_breakfast, Colors.orangeAccent),
          _buildMealCard('Dinner', totalDinnerWasted, Icons.dinner_dining, Colors.purpleAccent),
          _buildMealCard('Lunch', totalLunchWasted, Icons.lunch_dining, Colors.blueAccent),
        ],
      ),
    );
  }

  Widget _buildUserCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade300, Colors.green.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Details',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text('Roll No: ${widget.username}', style: const TextStyle(fontSize: 18, color: Colors.white)), // Display Roll No
          Text('Email: ${widget.email}', style: const TextStyle(fontSize: 16, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildMealCard(String meal, double wasted, IconData icon, Color color) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(meal, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        trailing: Text('${wasted.toStringAsFixed(2)}g Wasted', style: const TextStyle(fontSize: 14, color: Colors.red)), // Assuming units are grams
      ),
    );
  }

  Widget _buildTimeCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade300, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(formattedDate, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(formattedTime, style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _logout() async {
    bool shouldLogout = await _showLogoutDialog();
    if (shouldLogout) {
      await _authService.logout(); // Perform Firebase logout
      if (!mounted) return; // Check if the widget is still in the tree before navigating
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    }
  }

  Future<bool> _showLogoutDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Logout')),
        ],
      ),
    ).then((value) => value ?? false); // Ensure a boolean is always returned
  }

  @override
  Widget build(BuildContext context) {
    Widget activePage;
    switch (_selectedIndex) {
      case 1:
      // Pass the uid to the AnalysisPage
        activePage = AnalysisPage(username: widget.username, rollNumber: widget.username, uid: widget.uid);
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
          IconButton(icon: const Icon(Icons.refresh), tooltip: "Refresh", onPressed: _fetchMealWastageData),
          IconButton(icon: const Icon(Icons.logout), tooltip: "Logout", onPressed: _logout),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Colors.green, Colors.lightGreenAccent], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
        ),
      ),
      body: AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: activePage),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Analysis'),
          BottomNavigationBarItem(icon: Icon(Icons.contact_mail), label: 'Contact'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        elevation: 10,
        backgroundColor: Colors.white,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
            _title = (index == 0) ? 'Home' : (index == 1) ? 'Analysis' : 'Contact';
          });
        },
      ),
    );
  }
}
