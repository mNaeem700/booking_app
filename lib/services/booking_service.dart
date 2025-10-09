import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:booking_app/model/booking.dart';

class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference get _bookings => _db.collection('bookings');

  Future<String> createBooking(Booking b) async {
    final data = b.toCreateMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    final doc = await _bookings.add(data);
    return doc.id;
  }

  Stream<List<Booking>> streamUserBookings(String uid) {
    return _bookings
        .where('userId', isEqualTo: uid)
        .orderBy('scheduledAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Booking.fromDoc(d)).toList());
  }

  Future<void> cancelBooking(String bookingId) async {
    await _bookings.doc(bookingId).update({
      'status': 'cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _bookings.doc(bookingId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Booking> getBookingById(String id) async {
    final doc = await _bookings.doc(id).get();
    return Booking.fromDoc(doc);
  }
}
