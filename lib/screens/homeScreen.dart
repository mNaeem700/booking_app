import 'package:flutter/material.dart';
import 'package:booking_app/theme/app_colors.dart';
import 'salon_detail_screen.dart';
import 'my_bookings_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';
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

    for (final controller in _tabControllers) {
      controller.value = 1.0;
    }

    // ✅ Pass the callback to activate Profile tab
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
    for (final c in _tabControllers) {
      c.dispose();
    }
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
          items: List.generate(4, (i) {
            final items = [
              {"icon": Icons.home, "label": "Home"},
              {"icon": Icons.calendar_today, "label": "Bookings"},
              {"icon": Icons.favorite, "label": "Favorites"},
              {"icon": Icons.person, "label": "Profile"},
            ];
            return BottomNavigationBarItem(
              icon: ScaleTransition(
                scale: _tabControllers[i],
                child: Icon(items[i]["icon"] as IconData),
              ),
              label: items[i]["label"] as String,
            );
          }),
        ),
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  final VoidCallback?
  onProfileTap; // ✅ nullable callback to prevent null errors

  const _HomeContent({this.onProfileTap, super.key});

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  final ValueNotifier<int?> _pressedIndex = ValueNotifier<int?>(null);

  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = "All";
  bool _showDiscountOnly = false;

  final List<Map<String, dynamic>> _salons = [
    {
      "name": "Luxury Cuts Salon",
      "rating": "4.8",
      "distance": "1.2 km",
      "image": "assets/images/salon1.jpg",
      "location": "Gulberg, Lahore",
      "category": "Men",
      "isDiscounted": true,
    },
    {
      "name": "Bella Beauty Lounge",
      "rating": "4.9",
      "distance": "2.3 km",
      "image": "assets/images/salon2.png",
      "location": "DHA, Lahore",
      "category": "Women",
      "isDiscounted": false,
    },
    {
      "name": "The Barber Spot",
      "rating": "4.7",
      "distance": "1.8 km",
      "image": "assets/images/salon3.png",
      "location": "Model Town, Lahore",
      "category": "Men",
      "isDiscounted": true,
    },
    {
      "name": "Lotus Spa & Wellness",
      "rating": "4.6",
      "distance": "3.0 km",
      "image": "assets/images/salon4.jpg",
      "location": "Johar Town, Lahore",
      "category": "Spa",
      "isDiscounted": false,
    },
  ];

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
    final filteredSalons = _salons.where((salon) {
      final matchesSearch = salon["name"].toString().toLowerCase().contains(
        _searchController.text.toLowerCase(),
      );
      final matchesCategory =
          _selectedCategory == "All" || salon["category"] == _selectedCategory;
      final matchesDiscount =
          !_showDiscountOnly || salon["isDiscounted"] == true;
      return matchesSearch && matchesCategory && matchesDiscount;
    }).toList();

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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          GestureDetector(
            onTap: widget.onProfileTap ?? () {}, // ✅ Safe call — no null crash
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
              filteredSalons.isEmpty
                  ? const Center(
                      child: Text(
                        "No salons found",
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : _buildSalonList(context, filteredSalons),
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
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SalonDetailScreen(
                  salonName: salon["name"]!,
                  salonImage: salon["image"]!,
                  salonLocation: salon["location"]!,
                ),
              ),
            );
          },
          child: Container(
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
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: Image.asset(
                    salon["image"]!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          salon["name"]!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              salon["rating"]!,
                              style: const TextStyle(color: Colors.black),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.location_on,
                              size: 18,
                              color: Colors.grey,
                            ),
                            Text(
                              salon["distance"]!,
                              style: const TextStyle(color: Colors.black),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ValueListenableBuilder<int?>(
                          valueListenable: _pressedIndex,
                          builder: (context, pressedIndex, _) {
                            final isPressed = pressedIndex == i;
                            return AnimatedScale(
                              scale: isPressed ? 1.08 : 1.0,
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOut,
                              child: ElevatedButton(
                                onPressed: () async {
                                  _pressedIndex.value = i;
                                  await Future.delayed(
                                    const Duration(milliseconds: 180),
                                  );
                                  _pressedIndex.value = null;
                                  if (!mounted) return;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SalonDetailScreen(
                                        salonName: salon["name"]!,
                                        salonImage: salon["image"]!,
                                        salonLocation: salon["location"]!,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  elevation: 3,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  "Book Now",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
