import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetch all entries matching a Roll_no
  Future<List<Map<String, dynamic>>> fetchByRollNo(String rollNo) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('Students')
          .where('Roll_no', isEqualTo: rollNo)
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print("Error fetching by roll_no: $e");
      return [];
    }
  }

  /// Fetch all waste logs for a given roll number and slot (e.g., slot=1 breakfast).
  Future<List<Map<String, dynamic>>> fetchWasteBySlot(
      {required String rollNo, required int slot}) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('Students')
          .where('Roll_no', isEqualTo: rollNo)
          .where('Slot', isEqualTo: slot)
          .orderBy('Date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['__docId'] = doc.id; // optional: include doc id
        return data;
      })
          .toList();
    } catch (e) {
      print("Error fetching by slot: $e");
      return [];
    }
  }

  /// Fetch all waste logs for a given roll number on a specific calendar date.
  /// `date` can be any DateTime on that day; only the date portion is considered.
  Future<List<Map<String, dynamic>>> fetchWasteByDate({
    required String rollNo,
    required DateTime date,
  }) async {
    try {
      // Normalize to start of day (local)
      final DateTime startOfDay = DateTime(date.year, date.month, date.day);
      final DateTime startOfNextDay = startOfDay.add(Duration(days: 1));

      // Firestore timestamps use UTC internally but Timestamp.fromDate accepts local DateTime.
      final Timestamp startTs = Timestamp.fromDate(startOfDay);
      final Timestamp endTs = Timestamp.fromDate(startOfNextDay);

      QuerySnapshot snapshot = await _db
          .collection('Students')
          .where('Roll_no', isEqualTo: rollNo)
          .where('Date', isGreaterThanOrEqualTo: startTs)
          .where('Date', isLessThan: endTs)
          .orderBy('Date', descending: true) // require ordering by same field used in range filters
          .get();

      return snapshot.docs
          .map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['__docId'] = doc.id; // optional
        return data;
      })
          .toList();
    } catch (e) {
      print("Error fetching by date: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchByEmail(String email) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('Students')
          .where('email', isEqualTo: email)
          .get();

      if (snapshot.docs.isEmpty) {
        print("No entries found for email: $email");
        return [];
      }

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print("Error fetching by email: $e");
      return [];
    }
  }


}
