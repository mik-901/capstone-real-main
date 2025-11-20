// analysis.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AnalysisPage extends StatefulWidget {
  final String username; // kept for compatibility (roll number)
  final String rollNumber;
  final String uid;

  const AnalysisPage({
    super.key,
    required this.username,
    required this.rollNumber,
    required this.uid,
  });

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  late DateTime _weekStart; // Monday of the displayed week
  bool _loading = true;
  List<double> _dailyTotals = List<double>.filled(7, 0.0);
  double _weeklyTotal = 0.0;
  double _dailyAverage = 0.0;
  bool _isShowingCurrentWeek = true;

  @override
  void initState() {
    super.initState();
    _weekStart = _getWeekStart(DateTime.now());
    _loadWeekData();
  }

  DateTime _getWeekStart(DateTime dt) {
    // Ensure Monday start
    final monday = dt.subtract(Duration(days: (dt.weekday + 6) % 7));
    return DateTime(monday.year, monday.month, monday.day);
  }

  DateTime _getWeekEnd(DateTime weekStart) {
    return DateTime(weekStart.year, weekStart.month, weekStart.day, 23, 59, 59, 999);
  }

  Future<void> _loadWeekData() async {
    setState(() {
      _loading = true;
    });

    try {
      final start = _weekStart;
      final end = _getWeekEnd(start.add(const Duration(days: 6)));

      // Query the student's foodWaste in that date range
      final QuerySnapshot<Map<String, dynamic>> snap = await FirebaseFirestore
          .instance
          .collection('students')
          .doc(widget.rollNumber)
          .collection('foodWaste')
          .where('timestamp', isGreaterThanOrEqualTo: start)
          .where('timestamp', isLessThanOrEqualTo: end)
          .get();

      // Reset totals
      final List<double> totals = List<double>.filled(7, 0.0);

      for (final doc in snap.docs) {
        final data = doc.data();

        // Defensive parsing
        final num? weightNum = data['weight'] is num ? data['weight'] as num : null;
        final Timestamp? ts = data['timestamp'] is Timestamp ? data['timestamp'] as Timestamp : null;

        if (weightNum == null || ts == null) continue;

        final DateTime dt = ts.toDate();
        final DateTime localDate = DateTime(dt.year, dt.month, dt.day);
        final int dayIndex = localDate.difference(start).inDays;
        if (dayIndex >= 0 && dayIndex < 7) {
          totals[dayIndex] += weightNum.toDouble();
        }
      }

      final double weeklyTotal = totals.fold(0.0, (p, e) => p + e);
      final double average = weeklyTotal / 7.0;

      setState(() {
        _dailyTotals = totals;
        _weeklyTotal = weeklyTotal;
        _dailyAverage = average;
        _loading = false;
      });
    } catch (e, st) {
      // Safe fallback
      debugPrint("Error loading weekly data: $e\n$st");
      setState(() {
        _dailyTotals = List<double>.filled(7, 0.0);
        _weeklyTotal = 0.0;
        _dailyAverage = 0.0;
        _loading = false;
      });
    }
  }

  void _showPreviousWeek() {
    setState(() {
      _weekStart = _weekStart.subtract(const Duration(days: 7));
      _isShowingCurrentWeek = _getWeekStart(DateTime.now()) == _weekStart;
    });
    _loadWeekData();
  }

  void _showNextWeek() {
    final nextStart = _weekStart.add(const Duration(days: 7));
    final currentWeekStart = _getWeekStart(DateTime.now());
    if (!nextStart.isAfter(currentWeekStart)) {
      setState(() {
        _weekStart = nextStart;
      });
      _loadWeekData();
    }
  }

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(7, (index) {
      final double value = _dailyTotals[index];

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            width: 22,
            borderRadius: BorderRadius.circular(4),

            // ✔ ONLY LIGHT GREEN BAR (no dark block)
            color: const Color(0xFF8BC34A),
          ),
        ],
      );
    });
  }




  String _weekdayLabel(int index) {
    // index 0 -> Monday
    final day = _weekStart.add(Duration(days: index));
    return DateFormat.E().format(day); // Mon, Tue, ...
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: Card(
            margin: const EdgeInsets.only(right: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  const Text("Total this week", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("${_weeklyTotal.toStringAsFixed(2)} g", style: const TextStyle(fontSize: 18)),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Card(
            margin: const EdgeInsets.only(left: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  const Text("Average / day", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("${_dailyAverage.toStringAsFixed(2)} g", style: const TextStyle(fontSize: 18)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    final groups = _buildBarGroups();

    // Decide your max Y limit
    const double fixedMaxY = 300; // CHANGE THIS IF NEEDED

    // Expand if larger values exist
    final double maxValue = _dailyTotals.reduce((a, b) => a > b ? a : b);
    final double finalMaxY = maxValue > fixedMaxY ? maxValue * 1.2 : fixedMaxY;

    return AspectRatio(
      aspectRatio: 1.5,
      child: BarChart(
        BarChartData(
          maxY: finalMaxY,
          minY: 0,
          barGroups: groups,

          // 🔥 REMOVE ALL GRID LINES
          gridData: FlGridData(show: false),

          // 🔥 REMOVE ALL BORDER LINES
          borderData: FlBorderData(show: false),

          // LABELS
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 12),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx > 6) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _weekdayLabel(idx),
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                },
                reservedSize: 28,
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),

          // BAR STYLE
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.black87,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  "${_weekdayLabel(group.x)}\n${rod.toY.toStringAsFixed(2)} g",
                  const TextStyle(color: Colors.white),
                );
              },
            ),
          ),
        ),
      ),
    );
  }







  String _weekRangeLabel() {
    final end = _weekStart.add(const Duration(days: 6));
    return "${DateFormat('dd MMM').format(_weekStart)} - ${DateFormat('dd MMM yyyy').format(end)}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Weekly Analysis",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),

      body: RefreshIndicator(
        onRefresh: _loadWeekData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // ------------------------- WEEK NAVIGATION -----------------------
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _showPreviousWeek,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Icon(Icons.arrow_back_ios, size: 16),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    flex: 2,
                    child: Text(
                      _weekRangeLabel(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: _getWeekStart(DateTime.now()) == _weekStart
                          ? null
                          : () => _showNextWeek(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Icon(Icons.arrow_forward_ios, size: 16),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ------------------------- SUMMARY CARDS -------------------------
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              "Total This Week",
                              style: TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "${_weeklyTotal.toStringAsFixed(2)} g",
                              style: const TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              "Average / Day",
                              style: TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "${_dailyAverage.toStringAsFixed(2)} g",
                              style: const TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ------------------------- CHART -------------------------
              _loading
                  ? const SizedBox(
                height: 260,
                child: Center(child: CircularProgressIndicator()),
              )
                  : Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _buildChart(),
                ),
              ),

              const SizedBox(height: 16),

              // ------------------------- NOTE -------------------------
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: const Text(
                    "Daily totals include all meal slots (Breakfast, Lunch, Dinner).",
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  }

