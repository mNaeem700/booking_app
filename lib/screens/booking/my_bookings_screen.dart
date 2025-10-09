import 'package:booking_app/screens/widgets/animated_background.dart';
import 'package:booking_app/screens/widgets/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late final AnimationController _screenFadeController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  double _walletBalance = 0.0; // Wallet balance

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _screenFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _fetchWalletBalance();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _screenFadeController.dispose();
    super.dispose();
  }

  /// Fetch wallet balance
  Future<void> _fetchWalletBalance() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('wallets').doc(user.uid).get();
    if (doc.exists) {
      setState(() {
        _walletBalance = (doc.data()?['balance'] ?? 0.0).toDouble();
      });
    }
  }

  /// Format Timestamp
  String _formatDate(Timestamp ts) =>
      DateFormat('EEE, MMM d, hh:mm a').format(ts.toDate().toLocal());

  /// Map Firestore status to display status
  String _mapStatus(String status, Timestamp scheduledAt) {
    final now = DateTime.now();
    if (status == 'pending' && scheduledAt.toDate().isBefore(now)) {
      return 'Completed';
    }
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Upcoming';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Upcoming';
    }
  }

  /// Status color
  Color _statusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  /// Cancel a booking with optional refund
  void _cancelBooking(Map<String, dynamic> booking) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final bookingId = booking['id']!;
    final servicePrice = (booking['servicePrice'] ?? 0.0).toDouble();

    try {
      // Update booking status
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'cancelled',
      });

      // Refund wallet
      final walletRef = _firestore.collection('wallets').doc(user.uid);
      await _firestore.runTransaction((tx) async {
        final snapshot = await tx.get(walletRef);
        final currentBalance = snapshot.exists ? snapshot.get('balance') : 0.0;
        tx.set(walletRef, {'balance': currentBalance + servicePrice});
      });

      // Refresh wallet balance
      _fetchWalletBalance();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Booking cancelled and amount refunded!"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Error cancelling booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to cancel booking"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Open Review Bottom Sheet
  Future<void> _openReviewSheet(Map<String, dynamic> booking) async {
    final TextEditingController _reviewController = TextEditingController(
      text: booking['reviewText'] ?? '',
    );
    double _rating = (booking['rating'] ?? 0).toDouble();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 25,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Rate Your Experience",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final filled = index < _rating;
                    return IconButton(
                      onPressed: () =>
                          setModalState(() => _rating = index + 1.0),
                      icon: Icon(
                        filled ? Icons.star_rounded : Icons.star_border_rounded,
                        color: Colors.amber,
                        size: 34,
                      ),
                    );
                  }),
                ),
                TextField(
                  controller: _reviewController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Write your feedback...",
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (_rating == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please select a rating"),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    final user = _auth.currentUser;
                    if (user == null) return;

                    await _firestore
                        .collection('bookings')
                        .doc(booking['id'])
                        .update({
                          'rating': _rating,
                          'reviewText': _reviewController.text.trim(),
                          'reviewedAt': FieldValue.serverTimestamp(),
                        });

                    if (booking['salonId'] != null) {
                      await _firestore
                          .collection('salons')
                          .doc(booking['salonId'])
                          .collection('reviews')
                          .doc(user.uid)
                          .set({
                            'rating': _rating,
                            'reviewText': _reviewController.text.trim(),
                            'userId': user.uid,
                            'userEmail': user.email,
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Review submitted successfully"),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    "Submit Review",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Shimmer Loading
  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, i) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  /// Firestore Stream per tab
  Stream<QuerySnapshot> _getBookingsStream(String tab) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    Query query = _firestore
        .collection('bookings')
        .where('userId', isEqualTo: user.uid)
        .orderBy('scheduledAt', descending: true);

    if (tab == 'Upcoming') query = query.where('status', isEqualTo: 'pending');
    if (tab == 'Completed')
      query = query.where('status', isEqualTo: 'completed');
    if (tab == 'Cancelled')
      query = query.where('status', isEqualTo: 'cancelled');

    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return FadeTransition(
      opacity: _screenFadeController.drive(CurveTween(curve: Curves.easeOut)),
      child: AnimatedBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text(
              'My Bookings',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(90),
              child: Column(
                children: [
                  // Wallet Balance
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Wallet Balance",
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "Rs ${_walletBalance.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Tabs
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: Colors.white,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorPadding: const EdgeInsets.all(4),
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      tabs: const [
                        Tab(text: 'Upcoming'),
                        Tab(text: 'Completed'),
                        Tab(text: 'Cancelled'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: user == null
              ? const Center(
                  child: Text(
                    "Please login to see your bookings",
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: ['Upcoming', 'Completed', 'Cancelled'].map((tab) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: _getBookingsStream(tab),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return _buildShimmer();

                        final bookings = snapshot.data!.docs
                            .map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              data['id'] = doc.id;
                              return data;
                            })
                            .toList()
                            .cast<Map<String, dynamic>>();

                        if (bookings.isEmpty) {
                          return Center(
                            child: Text(
                              'No $tab bookings yet.',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          );
                        }

                        return RefreshIndicator(
                          color: AppColors.primary,
                          backgroundColor: Colors.white,
                          onRefresh: () async {
                            _fetchWalletBalance();
                            setState(() {});
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: bookings.length,
                            itemBuilder: (context, i) {
                              final booking = bookings[i];
                              final formattedDate = _formatDate(
                                booking['scheduledAt'],
                              );
                              final status = _mapStatus(
                                booking['status'],
                                booking['scheduledAt'],
                              );

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        booking['serviceName'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        formattedDate,
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: _statusColor(
                                                    status,
                                                  ).withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: _statusColor(
                                                      status,
                                                    ).withOpacity(0.3),
                                                  ),
                                                ),
                                                child: Text(
                                                  status,
                                                  style: TextStyle(
                                                    color: _statusColor(status),
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              if (status == 'Upcoming')
                                                _buildCancelButton(booking),
                                              if (status == 'Completed')
                                                _buildReviewButton(booking),
                                            ],
                                          ),
                                          Text(
                                            "Rs ${booking['servicePrice']?.toStringAsFixed(0) ?? '0'}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
        ),
      ),
    );
  }

  /// Cancel Button Widget
  Widget _buildCancelButton(Map<String, dynamic> booking) {
    return TextButton(
      onPressed: () => _cancelBooking(booking),
      style: TextButton.styleFrom(
        backgroundColor: Colors.redAccent.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text(
        "Cancel",
        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
      ),
    );
  }

  /// Review Button Widget
  Widget _buildReviewButton(Map<String, dynamic> booking) {
    final hasReview = booking['rating'] != null;
    return TextButton(
      onPressed: () => _openReviewSheet(booking),
      style: TextButton.styleFrom(
        backgroundColor: AppColors.primary.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        hasReview ? "Edit Review" : "Leave Review",
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
