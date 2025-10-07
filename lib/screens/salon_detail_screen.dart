import 'package:booking_app/screens/animated_background.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'booking_screen.dart'; // 👈 Ensure this exists

class SalonDetailScreen extends StatefulWidget {
  final String salonName;
  final String salonImage;
  final String salonLocation;

  const SalonDetailScreen({
    super.key,
    required this.salonName,
    required this.salonImage,
    required this.salonLocation,
  });

  @override
  State<SalonDetailScreen> createState() => _SalonDetailScreenState();
}

class _SalonDetailScreenState extends State<SalonDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  AnimationController? _fadeController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_fadeController == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return FadeTransition(
      opacity: _fadeController!,
      child: AnimatedBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              // 🖼️ HEADER IMAGE
              Stack(
                children: [
                  Hero(
                    tag: widget.salonName,
                    child: Image.asset(
                      widget.salonImage,
                      height: 280,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    height: 280,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.25),
                          Colors.black.withOpacity(0.65),
                        ],
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _circleIcon(
                            Icons.arrow_back,
                            onTap: () => Navigator.pop(context),
                          ),
                          _circleIcon(Icons.favorite_border),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.salonName,
                          style: const TextStyle(
                            backgroundColor: Colors.transparent,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 18,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.salonLocation,
                                style: const TextStyle(color: Colors.white70),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(
                              Icons.star,
                              color: Colors.amberAccent,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              "4.8",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // 🧭 TAB BAR
              Container(
                color: Colors.white,
                child: AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, _) {
                    return TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: AppColors.primary,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      tabs: const [
                        Tab(text: "Services"),
                        Tab(text: "Reviews"),
                        Tab(text: "About"),
                      ],
                    );
                  },
                ),
              ),

              // 🧱 TAB CONTENT
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_servicesTab(context), _reviewsTab(), _aboutTab()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🟣 Circular Icon Button
  Widget _circleIcon(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }

  // 💇 SERVICES TAB
  Widget _servicesTab(BuildContext context) {
    final services = [
      {"name": "Haircut", "time": "30 mins", "price": 1200},
      {"name": "Beard Trim", "time": "20 mins", "price": 800},
      {"name": "Facial Treatment", "time": "45 mins", "price": 2500},
      {"name": "Massage Therapy", "time": "50 mins", "price": 3000},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: services.length,
      itemBuilder: (context, i) {
        final s = services[i];

        return TweenAnimationBuilder(
          tween: Tween<double>(begin: 20, end: 0),
          duration: Duration(milliseconds: 400 + (i * 100)),
          builder: (context, offset, child) {
            return Transform.translate(offset: Offset(0, offset), child: child);
          },
          child: Card(
            elevation: 1.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              title: Text(
                s["name"].toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                s["time"].toString(),
                style: const TextStyle(color: Colors.grey),
              ),
              trailing: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.95, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingScreen(
                          serviceName: s["name"].toString(),
                          servicePrice: s["price"] as int,
                        ),
                      ),
                    );
                  },
                  child: Text("Rs ${s["price"]}"),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 💬 REVIEWS TAB
  Widget _reviewsTab() {
    final reviews = [
      {
        "name": "Ali Raza",
        "review": "Amazing experience, staff was really friendly!",
        "rating": 5,
      },
      {
        "name": "Sara Khan",
        "review": "Loved the facial and ambiance, will visit again.",
        "rating": 4,
      },
      {
        "name": "Usman Malik",
        "review": "Professional service and very clean setup.",
        "rating": 5,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reviews.length,
      itemBuilder: (context, i) {
        final r = reviews[i];
        return TweenAnimationBuilder(
          tween: Tween<double>(begin: 30, end: 0),
          duration: Duration(milliseconds: 500 + (i * 100)),
          builder: (context, offset, child) {
            return Transform.translate(offset: Offset(0, offset), child: child);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: const Icon(Icons.person, color: Colors.black),
              ),
              title: Row(
                children: [
                  Text(
                    r["name"].toString(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 6),
                  Row(
                    children: List.generate(
                      r["rating"] as int,
                      (index) =>
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  r["review"].toString(),
                  style: const TextStyle(color: Colors.black87),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 🏠 ABOUT TAB
  Widget _aboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: FadeTransition(
        opacity: _fadeController!.drive(
          CurveTween(curve: Curves.easeInOutCubic),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "About This Salon",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "Elite Men’s Salon provides luxury grooming services "
              "with a modern twist — from precision haircuts and beard "
              "styling to relaxing spa treatments. Our expert stylists "
              "ensure every visit leaves you looking and feeling your best.",
              style: TextStyle(height: 1.5, color: Colors.black87),
            ),
            SizedBox(height: 20),
            Divider(),
            SizedBox(height: 10),
            Text("📍 Address: Model Town, Lahore"),
            SizedBox(height: 6),
            Text("⏰ Hours: 10:00 AM - 9:00 PM"),
            SizedBox(height: 6),
            Text("📞 Contact: +92 300 1234567"),
          ],
        ),
      ),
    );
  }
}
