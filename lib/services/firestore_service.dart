import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 🔹 Real-time stream of all salons
  Stream<List<Map<String, dynamic>>> getSalonsStream() {
    try {
      return _db.collection('salons').snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
      });
    } catch (e) {
      print('❌ FirestoreService.getSalonsStream error: $e');
      rethrow;
    }
  }

  /// 🔹 One-time fetch of all salons
  Future<List<Map<String, dynamic>>> getSalonsOnce() async {
    try {
      final snapshot = await _db.collection('salons').get();
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      print('❌ FirestoreService.getSalonsOnce error: $e');
      rethrow;
    }
  }

  /// 🔹 Fetch single salon by ID
  Future<Map<String, dynamic>?> getSalonById(String salonId) async {
    try {
      final doc = await _db.collection('salons').doc(salonId).get();
      if (!doc.exists) return null;
      return {'id': doc.id, ...doc.data()!};
    } catch (e) {
      print('❌ FirestoreService.getSalonById error: $e');
      rethrow;
    }
  }

  /// 🔸 Search salons by name (case-insensitive)
  Future<List<Map<String, dynamic>>> searchSalonsByName(String query) async {
    try {
      final snapshot = await _db
          .collection('salons')
          .where('keywords', arrayContains: query.toLowerCase())
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      print('❌ FirestoreService.searchSalonsByName error: $e');
      rethrow;
    }
  }

  /// 🏷️ Filter salons by category (e.g. Hair, Spa, Nails)
  Future<List<Map<String, dynamic>>> filterSalonsByCategory(
    String category,
  ) async {
    try {
      final snapshot = await _db
          .collection('salons')
          .where('category', isEqualTo: category)
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      print('❌ FirestoreService.filterSalonsByCategory error: $e');
      rethrow;
    }
  }

  /// ⭐ Sort salons by rating (descending)
  Future<List<Map<String, dynamic>>> getTopRatedSalons({int limit = 10}) async {
    try {
      final snapshot = await _db
          .collection('salons')
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      print('❌ FirestoreService.getTopRatedSalons error: $e');
      rethrow;
    }
  }
}
