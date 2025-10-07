import 'package:booking_app/screens/animated_background.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  AnimationController? _screenFadeController;
  bool _isRefreshing = false;

  final List<Map<String, dynamic>> bookings = [
    {
      'service': 'Haircut',
      'salon': 'Elite Men’s Salon',
      'date': DateTime(2025, 10, 8, 15, 30),
      'status': 'Upcoming',
      'image': 'assets/images/haircut.jpg',
    },
    {
      'service': 'Facial',
      'salon': 'Glow Beauty Lounge',
      'date': DateTime(2025, 9, 20, 11, 00),
      'status': 'Completed',
      'image': 'assets/images/facial.jpg',
    },
    {
      'service': 'Beard Trim',
      'salon': 'Style Studio',
      'date': DateTime(2025, 9, 25, 13, 30),
      'status': 'Cancelled',
      'image': 'assets/images/beard.jpg',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _screenFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _screenFadeController?.dispose();
    super.dispose();
  }

  Future<void> _refreshBookings() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isRefreshing = false);
  }

  // 🔴 Cancel booking confirmation dialog
  void _cancelBooking(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Cancel Booking?"),
        content: const Text(
          "Are you sure you want to cancel this booking?",
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No", style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                bookings[index]['status'] = 'Cancelled';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("Booking cancelled successfully"),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            child: const Text(
              "Yes, Cancel",
              style: TextStyle(color: Color(0xFFFFFFFF)),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildImage(String path) {
    return path.startsWith('http')
        ? Image.network(path, fit: BoxFit.cover)
        : Image.asset(path, fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    if (_screenFadeController == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return FadeTransition(
      opacity: _screenFadeController!.drive(CurveTween(curve: Curves.easeOut)),
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
            elevation: 4,
            shadowColor: Colors.black26,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.white.withOpacity(0.7),
                  indicator: BoxDecoration(
                    color: Colors.white.withOpacity(.7),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  indicatorPadding: const EdgeInsets.symmetric(
                    horizontal: -10,
                    vertical: 8,
                  ),
                  tabs: const [
                    Tab(text: 'Upcoming'),
                    Tab(text: 'Completed'),
                    Tab(text: 'Cancelled'),
                  ],
                ),
              ),
            ),
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeIn,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBookingsList('Upcoming'),
                _buildBookingsList('Completed'),
                _buildBookingsList('Cancelled'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingsList(String status) {
    final filtered = bookings
        .asMap()
        .entries
        .where((entry) => entry.value['status'] == status)
        .toList();

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: Colors.white,
      onRefresh: _refreshBookings,
      child: filtered.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: Center(
                    child: Text(
                      'No $status bookings yet.',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final booking = filtered[i].value;
                final index = filtered[i].key;
                final formattedDate = DateFormat(
                  'EEE, MMM d, hh:mm a',
                ).format(booking['date']);

                return TweenAnimationBuilder(
                  tween: Tween<double>(begin: 30, end: 0),
                  duration: Duration(milliseconds: 400 + (i * 100)),
                  curve: Curves.easeOutBack,
                  builder: (context, offset, child) {
                    return Transform.translate(
                      offset: Offset(0, offset),
                      child: AnimatedOpacity(
                        opacity: offset == 0 ? 1 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white, // Solid white background
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Hero(
                            tag: '${booking['service']}_$index',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: SizedBox(
                                height: 70,
                                width: 70,
                                child: buildImage(booking['image']),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking['service'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  booking['salon'],
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: Colors.black45,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        formattedDate,
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 13,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    _buildStatusChip(status),
                                    if (status == 'Upcoming') ...[
                                      const SizedBox(width: 10),
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.redAccent
                                              .withOpacity(0.1),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 5,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            side: BorderSide(
                                              color: Colors.redAccent
                                                  .withOpacity(0.4),
                                            ),
                                          ),
                                        ),
                                        onPressed: () => _cancelBooking(index),
                                        child: const Text(
                                          "Cancel",
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Completed':
        color = Colors.green;
        break;
      case 'Cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
