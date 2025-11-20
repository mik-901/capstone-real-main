// meal_details.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MealDetailsPage extends StatelessWidget {
  final String rollNumber;
  final int mealSlot;

  const MealDetailsPage({
    super.key,
    required this.rollNumber,
    required this.mealSlot,
  });

  String _mealName(int slot) {
    if (slot == 1) return "Breakfast";
    if (slot == 2) return "Lunch";
    if (slot == 3) return "Dinner";
    return "Meal";
  }

  @override
  Widget build(BuildContext context) {
    final collection = FirebaseFirestore.instance
        .collection("students")
        .doc(rollNumber)
        .collection("foodWaste");

    return Scaffold(
      appBar: AppBar(title: Text("${_mealName(mealSlot)} — Recent Entries")),
      body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
        future: collection
            .where("mealSlot", isEqualTo: mealSlot)
            .orderBy("timestamp", descending: true)
            .limit(4)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(child: Text("No recent ${_mealName(mealSlot)} entries."));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final weightNum = data["weight"];
              final List rawLabels = (data["foodLabels"] is List) ? data["foodLabels"] : [];
              final Timestamp? ts = data["timestamp"] as Timestamp?;

              final double weight = (weightNum is num) ? weightNum.toDouble() : 0.0;
              final List<String> labels = rawLabels.map((e) => e.toString()).toList();
              final DateTime? dateTime = ts?.toDate();

              final bool isLatest = index == 0;

              return Card(
                elevation: isLatest ? 6 : 3,
                color: isLatest ? Colors.green.shade50 : Colors.white,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: CircleAvatar(
                    backgroundColor: isLatest ? Colors.green : Colors.grey.shade300,
                    child: Text(
                      "${index + 1}",
                      style: TextStyle(
                        color: isLatest ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  title: Text(
                    "${weight.toStringAsFixed(2)} g wasted",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text("Food: ${labels.isNotEmpty ? labels.join(', ') : '—'}"),
                      const SizedBox(height: 6),
                      Text(
                        dateTime != null
                            ? "Time: ${DateFormat('dd MMM yyyy, hh:mm a').format(dateTime)}"
                            : "Time: Unknown",
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
