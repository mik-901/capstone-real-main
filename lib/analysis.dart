import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart'; // For date formatting

class AnalysisPage extends StatefulWidget {
  final String username; // This is the rollNumber
  final String rollNumber; // Redundant, but keeping for existing usage. Will use username as rollNumber.
  final String uid; // <-- NEW: The Firebase Auth UID for security rules

  const AnalysisPage({
    super.key,
    required this.username,
    required this.rollNumber,
    required this.uid, // <-- NEW: Must accept the UID
  });

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  // Map to store daily totals for each meal type over the last 30 days
  // Key: meal type (e.g., 'breakfast'), Value: List of 30 doubles (each for a day)
  Map<String, List<double>> wasteData = {
    'Breakfast': List.filled(30, 0.0), // Changed to match mealSlot string values
    'Lunch': List.filled(30, 0.0),
    'Dinner': List.filled(30, 0.0),
  };

  // List of actual dates for the last 30 days, to be used for graph labels
  List<DateTime> last30Days = [];
  String selectedMealType = 'Breakfast'; // Default selected meal type for the graph

  bool _isLoading = true; // State to manage loading indicator

  @override
  void initState() {
    super.initState();
    _initializeDates();
    _fetchAndAggregateWasteData();
  }

  void _initializeDates() {
    final now = DateTime.now();
    for (int i = 29; i >= 0; i--) { // Go back 29 days from today to get 30 days
      last30Days.add(DateTime(now.year, now.month, now.day).subtract(Duration(days: i)));
    }
  }

  /// Fetches individual food waste entries from Firestore and aggregates them into daily totals.
  Future<void> _fetchAndAggregateWasteData() async {
    setState(() {
      _isLoading = true;
      // Reset wasteData before fetching new data
      wasteData = {
        'Breakfast': List.filled(30, 0.0),
        'Lunch': List.filled(30, 0.0),
        'Dinner': List.filled(30, 0.0),
      };
    });

    try {
      final now = DateTime.now();
      final thirtyDaysAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29)); // Start of the 30-day period

      // Query the user's specific foodWaste subcollection
      final QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.rollNumber) // Use rollNumber (widget.username) as the doc ID
          .collection('foodWaste')
          .where('timestamp', isGreaterThanOrEqualTo: thirtyDaysAgo)
          .where('timestamp', isLessThanOrEqualTo: now) // Fetch up to current moment
          .orderBy('timestamp', descending: false) // Order to process chronologically
          .get();

      if (snapshot.docs.isEmpty) {
        print('No food waste data found for ${widget.rollNumber} in the last 30 days.');
      } else {
        print('Found ${snapshot.docs.length} food waste entries for ${widget.rollNumber}.');

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final Timestamp? timestamp = data['timestamp'] as Timestamp?;
          final String? mealSlot = data['mealSlot'] as String?;
          final double? weight = (data['weight'] as num?)?.toDouble(); // Safely cast num to double

          if (timestamp == null || mealSlot == null || weight == null || !wasteData.containsKey(mealSlot)) {
            print("Skipping malformed or incomplete document: ${doc.id}");
            continue;
          }

          final entryDate = timestamp.toDate();
          final dayIndex = last30Days.indexWhere((date) =>
          date.year == entryDate.year &&
              date.month == entryDate.month &&
              date.day == entryDate.day);

          if (dayIndex != -1) { // If the date falls within our 30-day window
            setState(() {
              wasteData[mealSlot]![dayIndex] += weight;
            });
          }
        }
      }
    } catch (e, st) {
      print('Error fetching and aggregating data: $e\n$st');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  // This method for manual updates is removed as per the architecture:
  // Pi sends data, app reads and aggregates.
  // void updateWasteData(int day, double value, String category) async { /* ... removed ... */ }


  @override
  Widget build(BuildContext context) {
    // Calculate total wasted for display
    double totalWasted = 0.0;
    wasteData.values.forEach((list) {
      totalWasted += list.reduce((a, b) => a + b);
    });

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A64F)))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Roll Number: ${widget.rollNumber}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Total Food Wasted (Last 30 Days): ${totalWasted.toStringAsFixed(2)}g', style: const TextStyle(fontSize: 18, color: Colors.red)),
            const SizedBox(height: 20),

            // Dropdown to select meal type for the graph
            DropdownButton<String>(
              value: selectedMealType,
              onChanged: (value) {
                setState(() {
                  selectedMealType = value!;
                });
              },
              items: ['Breakfast', 'Lunch', 'Dinner']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Removed the TextField and related functionality for manual data entry
            // TextField(
            //   controller: wasteController,
            //   keyboardType: TextInputType.number,
            //   decoration: InputDecoration(
            //     labelText: 'Enter waste for $selectedMealType (grams)',
            //     border: OutlineInputBorder(),
            //   ),
            //   onSubmitted: (value) {
            //     double waste = double.tryParse(value) ?? 0.0;
            //     int today = DateTime.now().day;
            //     updateWasteData(today, waste, selectedMealType); // This would require re-implementing logic
            //     wasteController.clear();
            //   },
            // ),
            // const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 30 * 30.0, // Adjust width based on desired bar spacing and count
                  child: BarChart(
                    BarChartData(
                      barGroups: wasteData[selectedMealType]!
                          .asMap()
                          .entries
                          .map((entry) {
                        int index = entry.key; // 0 to 29 for the 30 days
                        double value = entry.value;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: value,
                              color: Theme.of(context).primaryColor, // Using app's primary color
                              width: 8,
                              borderRadius: BorderRadius.circular(4),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: (wasteData.values.map((list) => list.reduce((a, b) => a > b ? a : b))).reduce((a, b) => a > b ? a : b), // Max waste across all meals
                                color: Colors.grey.withOpacity(0.1),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                      // Configure titles and grid for the chart
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          axisNameWidget: const Text("Weight (g)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: 50, // Adjust interval based on typical waste amounts
                            getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          axisNameWidget: const Text("Date", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30, // Space for labels
                            interval: 1, // Show every day
                            getTitlesWidget: (value, meta) {
                              int index = value.toInt();
                              if (index >= 0 && index < last30Days.length) {
                                // Format date to show just day of month
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Text(DateFormat('d').format(last30Days[index]), style: const TextStyle(fontSize: 10)),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: true, border: Border.all(color: const Color(0xff37434d), width: 1)),
                      gridData: FlGridData(show: true, drawVerticalLine: false),
                      // Optional: touch interaction for details
                      // barTouchData: BarTouchData(
                      //   touchTooltipData: BarTouchTooltipData(
                      //     tooltipBgColor: Colors.blueGrey,
                      //     getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      //       String date = DateFormat('MMM d').format(last30Days[group.x.toInt()]);
                      //       return BarTooltipItem(
                      //         '$date\n',
                      //         const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      //         children: <TextSpan>[
                      //           TextSpan(
                      //             text: '${rod.toY.toStringAsFixed(2)}g',
                      //             style: const TextStyle(color: Colors.yellow, fontSize: 16, fontWeight: FontWeight.bold),
                      //           ),
                      //         ],
                      //       );
                      //     },
                      //   ),
                      // ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
