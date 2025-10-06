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
  AnimationController? _screenFadeController; // made nullable
  bool _isRefreshing = false;

  final List<Map<String, dynamic>> bookings = [
    {
      'service': 'Haircut',
      'salon': 'Elite Men’s Salon',
      'date': DateTime(2025, 10, 7, 15, 30),
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

  Widget buildImage(String path) {
    return path.startsWith('http')
        ? Image.network(path, fit: BoxFit.cover)
        : Image.asset(path, fit: BoxFit.cover);
  }

  // 🔄 Refresh logic
  Future<void> _refreshBookings() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    // ✅ safely handle controller not ready yet
    if (_screenFadeController == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return FadeTransition(
      opacity: _screenFadeController!.drive(CurveTween(curve: Curves.easeOut)),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'My Bookings',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: Colors.black26,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.primary,
                indicator: BoxDecoration(
                  color: AppColors.primary,
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
    );
  }

  // 🧾 Booking list filtered by status
  Widget _buildBookingsList(String status) {
    final filtered = bookings.where((b) => b['status'] == status).toList();

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: Colors.white,
      displacement: 40,
      strokeWidth: 2.5,
      onRefresh: _refreshBookings,
      child: filtered.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: AnimatedOpacity(
                    opacity: _isRefreshing ? 0.4 : 1,
                    duration: const Duration(milliseconds: 300),
                    child: Center(
                      child: Text(
                        'No $status bookings yet.',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                        ),
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
              itemBuilder: (context, index) {
                final booking = filtered[index];
                final formattedDate = DateFormat(
                  'EEE, MMM d, hh:mm a',
                ).format(booking['date']);

                // 🎬 Slide + fade animation
                return TweenAnimationBuilder(
                  tween: Tween<double>(begin: 30, end: 0),
                  duration: Duration(milliseconds: 400 + (index * 100)),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: () {},
                      splashColor: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(18),
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
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    booking['salon'],
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
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
                                            color: Colors.black45,
                                            fontSize: 13,
                                            letterSpacing: 0.3,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusChip(status),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  // 🎯 Status chip with soft glow
  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Completed':
        color = Colors.green;
        break;
      case 'Cancelled':
        color = Colors.redAccent;
        break;
      default:
        color = AppColors.primary;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1.05),
      duration: const Duration(seconds: 2),
      curve: Curves.easeInOut,
      builder: (context, scale, _) {
        return Transform.scale(
          scale: scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Text(
              status,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        );
      },
    );
  }
}
