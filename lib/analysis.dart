import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalysisPage extends StatefulWidget {
  final String username;
  final String rollNumber;

  const AnalysisPage({super.key, required this.username, required this.rollNumber});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  // A map to store food wastage data for breakfast, lunch, and dinner
  Map<String, List<double>> wasteData = {
    'breakfast': List.generate(30, (index) => 0.0),
    'lunch': List.generate(30, (index) => 0.0),
    'dinner': List.generate(30, (index) => 0.0),
  };

  List<int> days = List.generate(30, (index) => index + 1);
  TextEditingController wasteController = TextEditingController();
  String selectedCategory = 'breakfast';

  @override
  void initState() {
    super.initState();
    fetchWasteData();
  }

  // Fetch data from Firestore and populate the 'wasteData' map
  void fetchWasteData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('food_wastage')
          .doc(widget.rollNumber)
          .get();

      // Debug: Check if document exists
      if (doc.exists) {
        print('Document found for rollNumber: ${widget.rollNumber}');

        // Check if 'wasteData' field exists in the document
        if (doc['wasteData'] != null) {
          Map<String, dynamic> data = doc['wasteData'];

          // Check for each category and populate the map
          data.forEach((category, value) {
            if (value != null) {
              List<dynamic> categoryData = value;
              wasteData[category] = categoryData.map((item) {
                return (item is int) ? item.toDouble() : item as double;
              }).toList();
            }
          });

          print('wasteData field found: $wasteData');
          setState(() {});
        } else {
          print('wasteData field is null, initializing with default values.');
          setState(() {
            wasteData = {
              'breakfast': List.generate(30, (index) => 0.0),
              'lunch': List.generate(30, (index) => 0.0),
              'dinner': List.generate(30, (index) => 0.0),
            };
          });
        }
      } else {
        print('No document found for rollNumber: ${widget.rollNumber}');
        setState(() {
          wasteData = {
            'breakfast': List.generate(30, (index) => 0.0),
            'lunch': List.generate(30, (index) => 0.0),
            'dinner': List.generate(30, (index) => 0.0),
          };
        });
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        wasteData = {
          'breakfast': List.generate(30, (index) => 0.0),
          'lunch': List.generate(30, (index) => 0.0),
          'dinner': List.generate(30, (index) => 0.0),
        };
      });
    }
  }

  void updateWasteData(int day, double value, String category) async {
    // Ensure the category exists and is initialized
    if (wasteData[category] == null) {
      wasteData[category] = List.generate(30, (index) => 0.0); // Initialize if null
    }

    // Update the local list first
    setState(() {
      wasteData[category]![day - 1] = value;
    });

    try {
      // Update the 'wasteData' field in Firestore
      await FirebaseFirestore.instance
          .collection('food_wastage')
          .doc(widget.rollNumber)
          .set({'wasteData': wasteData});
      print('Data updated for rollNumber: ${widget.rollNumber}');
    } catch (e) {
      print('Error updating data: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    double totalWasted = wasteData['breakfast']!.reduce((a, b) => a + b) +
        wasteData['lunch']!.reduce((a, b) => a + b) +
        wasteData['dinner']!.reduce((a, b) => a + b);

    return Scaffold(
      //appBar: AppBar(title: const Text('Food Waste Analysis'), backgroundColor: Colors.green),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${widget.username}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Roll Number: ${widget.rollNumber}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            Text('Total Food Wasted: $totalWasted grams', style: const TextStyle(fontSize: 18, color: Colors.red)),
            const SizedBox(height: 20),
            DropdownButton<String>(
              value: selectedCategory,
              onChanged: (value) {
                setState(() {
                  selectedCategory = value!;
                });
              },
              items: ['breakfast', 'lunch', 'dinner']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value[0].toUpperCase() + value.substring(1)),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: wasteController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter waste for $selectedCategory (grams)',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                double waste = double.tryParse(value) ?? 0.0;
                int today = DateTime.now().day;
                updateWasteData(today, waste, selectedCategory);
                wasteController.clear();
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 30 * 30.0,
                  child: BarChart(
                    BarChartData(
                      barGroups: wasteData[selectedCategory]!
                          .asMap()
                          .entries
                          .map((entry) {
                        int index = entry.key;
                        double value = entry.value;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(toY: value, color: Colors.blue, width: 8, borderRadius: BorderRadius.circular(4)),
                          ],
                        );
                      }).toList(),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          axisNameWidget: const Text("Grams", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: 10,
                            getTitlesWidget: (value, meta) => Text('${value.toInt()}'),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          axisNameWidget: const Text("Date", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 5,
                            getTitlesWidget: (value, meta) {
                              int index = value.toInt();
                              if (index >= 0 && index < days.length) {
                                return Text(days[index].toString(), style: const TextStyle(fontSize: 12));
                              }
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: true),
                      gridData: FlGridData(show: true, drawHorizontalLine: true, drawVerticalLine: false),
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
