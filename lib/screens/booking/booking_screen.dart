import 'package:booking_app/screens/widgets/animated_background.dart';
import 'package:booking_app/screens/widgets/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'my_bookings_screen.dart';

class BookingScreen extends StatefulWidget {
  final String serviceName;
  final String salonId;
  final double servicePrice;
  final String salonName;
  final String salonImage;
  final double salonRating;

  const BookingScreen({
    super.key,
    required this.serviceName,
    required this.salonId,
    required this.servicePrice,
    required this.salonName,
    required this.salonImage,
    required this.salonRating,
    required price,
    required imagePath,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay? selectedTime;
  bool isBooking = false;
  List<TimeOfDay> bookedTimes = [];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Wallet balance
  double _walletBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchWalletBalance();
    _fetchBookedTimes();
  }

  // Fetch wallet balance
  Future<void> _fetchWalletBalance() async {
    final uid = _auth.currentUser!.uid;
    final doc = await _firestore.collection('wallets').doc(uid).get();
    if (doc.exists) {
      setState(() {
        _walletBalance = (doc.data()?['balance'] ?? 0.0).toDouble();
      });
    } else {
      // Create wallet doc if not exists
      await _firestore.collection('wallets').doc(uid).set({'balance': 0.0});
      setState(() {
        _walletBalance = 0.0;
      });
    }
  }

  // Generate next 7 days
  List<DateTime> _next7Days() =>
      List.generate(7, (i) => DateTime.now().add(Duration(days: i)));

  // Generate time slots from 9:00 to 17:30
  List<TimeOfDay> _timeSlots() {
    List<TimeOfDay> slots = [];
    for (int h = 9; h < 18; h++) {
      slots.add(TimeOfDay(hour: h, minute: 0));
      slots.add(TimeOfDay(hour: h, minute: 30));
    }
    return slots;
  }

  // Fetch already booked times for selected date
  Future<void> _fetchBookedTimes() async {
    bookedTimes.clear();
    final snapshot = await _firestore
        .collection('bookings')
        .where('salonId', isEqualTo: widget.salonId)
        .where('status', whereIn: ['pending', 'completed'])
        .get();

    final selectedDayStart = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final selectedDayEnd = selectedDayStart.add(const Duration(days: 1));

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final Timestamp ts = data['scheduledAt'];
      final DateTime booked = ts.toDate();
      if (booked.isAfter(
            selectedDayStart.subtract(const Duration(seconds: 1)),
          ) &&
          booked.isBefore(selectedDayEnd)) {
        bookedTimes.add(TimeOfDay(hour: booked.hour, minute: booked.minute));
      }
    }
    setState(() {});
  }

  // Book the service with wallet deduction
  Future<void> _bookService() async {
    if (selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a time slot"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please login first"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final scheduledAt = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    if (bookedTimes.any(
      (t) => t.hour == selectedTime!.hour && t.minute == selectedTime!.minute,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("This slot is already booked"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Check wallet balance
    if (_walletBalance < widget.servicePrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Insufficient wallet balance. Please top-up."),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => isBooking = true);

    try {
      final uid = user.uid;
      final bookingRef = _firestore.collection('bookings').doc();
      final walletRef = _firestore.collection('wallets').doc(uid);
      final txRef = _firestore.collection('transactions').doc();

      await _firestore.runTransaction((transaction) async {
        // Deduct wallet balance
        final walletSnap = await transaction.get(walletRef);
        final currentBalance = walletSnap.exists
            ? walletSnap.get('balance')
            : 0.0;
        final newBalance = currentBalance - widget.servicePrice;
        transaction.set(walletRef, {'balance': newBalance});

        // Add transaction record
        transaction.set(txRef, {
          'userId': uid,
          'title': 'Service Booking: ${widget.serviceName}',
          'amount': -widget.servicePrice,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Add booking record
        transaction.set(bookingRef, {
          'userId': uid,
          'salonId': widget.salonId,
          'serviceName': widget.serviceName,
          'servicePrice': widget.servicePrice,
          'status': 'pending',
          'scheduledAt': scheduledAt,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Add to user's myBookings
        final myBookingRef = _firestore
            .collection('users')
            .doc(uid)
            .collection('myBookings')
            .doc(bookingRef.id);
        transaction.set(myBookingRef, {
          'bookingId': bookingRef.id,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      await _fetchWalletBalance();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Booking successful! Wallet deducted."),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint("Booking error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to book service"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dates = _next7Days();
    final times = _timeSlots();

    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text("Book Service"),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Salon info card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.salonImage,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/images/default_salon.jpg',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.serviceName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Price: Rs ${widget.servicePrice.toStringAsFixed(0)}",
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(widget.salonRating.toStringAsFixed(1)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Horizontal Date Picker
              SizedBox(
                height: 70,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: dates.length,
                  itemBuilder: (context, index) {
                    final date = dates[index];
                    final isSelected =
                        date.day == selectedDate.day &&
                        date.month == selectedDate.month;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedDate = date;
                          selectedTime = null;
                        });
                        _fetchBookedTimes();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat.E().format(date),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              date.day.toString(),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Time slots grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: times.map((time) {
                    final isBooked = bookedTimes.any(
                      (t) => t.hour == time.hour && t.minute == time.minute,
                    );
                    final isSelected = selectedTime == time;
                    return GestureDetector(
                      onTap: isBooked
                          ? null
                          : () => setState(() => selectedTime = time),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : isBooked
                              ? Colors.grey.shade300
                              : Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : isBooked
                                ? Colors.grey
                                : AppColors.primary,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          time.format(context),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : isBooked
                                ? Colors.grey.shade700
                                : AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Book Now button
              ElevatedButton(
                onPressed: isBooking ? null : _bookService,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isBooking
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "Book Now (Rs ${widget.servicePrice.toStringAsFixed(0)})",
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
