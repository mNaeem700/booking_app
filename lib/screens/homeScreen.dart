import 'package:flutter/material.dart';
import 'package:booking_app/theme/app_colors.dart';
import 'salon_detail_screen.dart';
import 'my_bookings_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    _HomeContent(),
    MyBookingsScreen(),
    FavoritesScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: "Bookings",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: "Favorites",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  final ValueNotifier<int?> _pressedIndex = ValueNotifier<int?>(null);

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pressedIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: FadeTransition(
          opacity: _entryController.drive(CurveTween(curve: Curves.easeOut)),
          child: const Text(
            "Hi, Naeem 👋",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ),
        actions: [
          FadeTransition(
            opacity: _entryController.drive(CurveTween(curve: Curves.easeOut)),
            child: IconButton(
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.black87,
              ),
              onPressed: () {},
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: CircleAvatar(
              backgroundImage: AssetImage('assets/images/user.jpg'),
              radius: 18,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _animatedItem(0, _buildSearchBar()),
            const SizedBox(height: 20),
            _animatedItem(
              1,
              const Text(
                "Categories",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const SizedBox(height: 10),
            _animatedItem(5, _buildSalonList(context)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const TextField(
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: "Search salons, barbers, spa...",
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCategoryRow() {
    final categories = [
      {"title": "Men", "icon": Icons.male},
      {"title": "Women", "icon": Icons.female},
      {"title": "Spa", "icon": Icons.spa},
      {"title": "Massage", "icon": Icons.self_improvement},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          return Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(cat["icon"] as IconData, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  cat["title"].toString(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOfferBanner() {
    return Container(
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
        child: const Text(
          "💥 20% OFF on your first booking!",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSalonList(BuildContext context) {
    final salons = [
      {
        "name": "Luxury Cuts Salon",
        "rating": "4.8",
        "distance": "1.2 km",
        "image": "assets/images/salon1.jpg",
        "location": "Gulberg, Lahore",
      },
      {
        "name": "Bella Beauty Lounge",
        "rating": "4.9",
        "distance": "2.3 km",
        "image": "assets/images/salon2.png",
        "location": "DHA, Lahore",
      },
      {
        "name": "The Barber Spot",
        "rating": "4.7",
        "distance": "1.8 km",
        "image": "assets/images/salon3.png",
        "location": "Model Town, Lahore",
      },
    ];

    return Column(
      children: List.generate(salons.length, (i) {
        final salon = salons[i];
        return AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: _pressedIndex.value == i ? 0.96 : 1.0,
          child: GestureDetector(
            onTapDown: (_) => _pressedIndex.value = i,
            onTapCancel: () => _pressedIndex.value = null,
            onTapUp: (_) {
              _pressedIndex.value = null;
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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
                              Text(salon["rating"]!),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.location_on,
                                size: 18,
                                color: Colors.grey,
                              ),
                              Text(salon["distance"]!),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
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
                              backgroundColor:
                                  AppColors.primary, // ✅ stays same
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
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
