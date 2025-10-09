import 'package:booking_app/screens/booking/booking_screen.dart';
import 'package:booking_app/screens/booking/my_bookings_screen.dart';
import 'package:booking_app/screens/profile/favorites_screen.dart';
import 'package:booking_app/screens/profile/profile_screen.dart';
import 'package:booking_app/screens/widgets/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;

  late AnimationController _bgController;
  late AnimationController _fadeController;
  late List<AnimationController> _tabControllers;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _tabControllers = List.generate(
      4,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
        lowerBound: 0.9,
        upperBound: 1.0,
      ),
    );

    for (final controller in _tabControllers) controller.value = 1.0;

    _screens = [
      _HomeContent(onProfileTap: () => _onItemTapped(3)),
      const MyBookingsScreen(),
      const FavoritesScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  void dispose() {
    _bgController.dispose();
    _fadeController.dispose();
    for (final c in _tabControllers) c.dispose();
    super.dispose();
  }

  Future<void> _onItemTapped(int index) async {
    if (index == _selectedIndex) return;

    await _tabControllers[index].reverse();
    await _tabControllers[index].forward();

    await _fadeController.reverse();
    if (!mounted) return;
    setState(() => _selectedIndex = index);
    if (mounted) await _fadeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF101820),
                      Color.lerp(
                        const Color(0xFF2E3192),
                        const Color(0xFF1BFFFF),
                        _bgController.value,
                      )!,
                      const Color(0xFF1BFFFF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              );
            },
          ),
          FadeTransition(
            opacity: _fadeController,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _fadeController,
                      curve: Curves.easeOut,
                    ),
                  ),
              child: _screens[_selectedIndex],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.white.withOpacity(0.95),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          elevation: 10,
          items: [
            BottomNavigationBarItem(
              icon: ScaleTransition(
                scale: _tabControllers[0],
                child: const Icon(Icons.home),
              ),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: ScaleTransition(
                scale: _tabControllers[1],
                child: const Icon(Icons.calendar_today),
              ),
              label: "Bookings",
            ),
            BottomNavigationBarItem(
              icon: ScaleTransition(
                scale: _tabControllers[2],
                child: const Icon(Icons.favorite),
              ),
              label: "Favorites",
            ),
            BottomNavigationBarItem(
              icon: ScaleTransition(
                scale: _tabControllers[3],
                child: const Icon(Icons.person),
              ),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  final VoidCallback? onProfileTap;

  const _HomeContent({this.onProfileTap, super.key});

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = "All";
  bool _showDiscountOnly = false;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _entryController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: FadeTransition(
          opacity: _entryController.drive(CurveTween(curve: Curves.easeOut)),
          child: const Text(
            "Hi, Naeem 👋",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          GestureDetector(
            onTap: widget.onProfileTap ?? () {},
            child: const Padding(
              padding: EdgeInsets.only(right: 12),
              child: CircleAvatar(
                backgroundImage: AssetImage('assets/images/user.jpg'),
                radius: 18,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _animatedItem(0, _buildSearchBar()),
            const SizedBox(height: 20),
            _animatedItem(
              1,
              const Text(
                "Categories",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _animatedItem(2, _buildCategoryRow()),
            const SizedBox(height: 24),
            _animatedItem(3, _buildOfferBanner()),
            const SizedBox(height: 24),
            _animatedItem(
              4,
              const Text(
                "Top Rated Salons",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _animatedItem(
              5,
              StreamBuilder<QuerySnapshot>(
                stream: _db.collection('salons').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No salons found",
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  final salons = snapshot.data!.docs
                      .map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        data['id'] = doc.id;
                        return data;
                      })
                      .where((salon) {
                        final matchesSearch = salon['name']
                            .toString()
                            .toLowerCase()
                            .contains(_searchController.text.toLowerCase());
                        final matchesCategory =
                            _selectedCategory == "All" ||
                            salon['category'] == _selectedCategory;
                        final matchesDiscount =
                            !_showDiscountOnly || salon['isDiscounted'] == true;
                        return matchesSearch &&
                            matchesCategory &&
                            matchesDiscount;
                      })
                      .toList();

                  if (salons.isEmpty) {
                    return const Center(
                      child: Text(
                        "No salons found",
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  return _buildSalonList(context, salons);
                },
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _animatedItem(int index, Widget child) {
    final start = 0.1 * index;
    final end = (start + 0.5).clamp(0.0, 1.0);
    final anim = CurvedAnimation(
      parent: _entryController,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: "Search salons, barbers, spa...",
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCategoryRow() {
    final categories = ["All", "Men", "Women", "Spa", "Massage"];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.white70,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOfferBanner() {
    return GestureDetector(
      onTap: () => setState(() => _showDiscountOnly = !_showDiscountOnly),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: const DecorationImage(
            image: AssetImage('assets/images/offer_banner.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          alignment: Alignment.bottomLeft,
          child: Text(
            _showDiscountOnly
                ? "💥 Showing Discounted Salons"
                : "💥 20% OFF on your first booking!",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSalonList(
    BuildContext context,
    List<Map<String, dynamic>> salons,
  ) {
    return Column(
      children: List.generate(salons.length, (i) {
        final salon = salons[i];
        final services = List<Map<String, dynamic>>.from(
          salon['services'] ?? [],
        );
        final rating = (salon['rating'] ?? 4.5).toDouble();
        final location = salon['location'] ?? "No location";
        final salonName = salon['name'] ?? '';
        final salonImage = salon['image'] ?? 'assets/images/default_salon.jpg';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // name + rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      salonName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(rating.toStringAsFixed(1)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // location
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: services.isEmpty
                      ? [
                          const Text(
                            "No services available",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ]
                      : services.map((service) {
                          final serviceName = service['name'] ?? 'Service';
                          final servicePrice = service['price'] ?? 0;
                          return ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BookingScreen(
                                    salonId: salon['id']!,
                                    serviceName: serviceName,
                                    servicePrice: servicePrice.toDouble(),
                                    salonName: salonName,
                                    salonImage: salonImage,
                                    salonRating: rating,
                                    price: null,
                                    imagePath: null,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            child: Text(
                              "$serviceName - Rs $servicePrice",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
