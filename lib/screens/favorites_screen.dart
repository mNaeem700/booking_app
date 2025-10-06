import 'package:flutter/material.dart';
import 'package:booking_app/theme/app_colors.dart';
import 'salon_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with TickerProviderStateMixin {
  late AnimationController _listAnimationController;

  final List<Map<String, String>> favoriteSalons = [
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

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  Future<void> _refreshFavorites() async {
    await Future.delayed(const Duration(milliseconds: 700));
    setState(() {});
  }

  void _removeFavorite(int index) {
    setState(() {
      favoriteSalons.removeAt(index);
    });
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 3,
        shadowColor: Colors.black26,
        centerTitle: true,
        title: const Text(
          "My Favorites 💖",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: favoriteSalons.isEmpty
          ? const Center(
              child: Text(
                "No favorites yet!",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: Colors.white,
              onRefresh: _refreshFavorites,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: favoriteSalons.length,
                itemBuilder: (context, index) {
                  final salon = favoriteSalons[index];
                  final animation = CurvedAnimation(
                    parent: _listAnimationController,
                    curve: Interval(
                      (index / favoriteSalons.length),
                      1.0,
                      curve: Curves.easeOutBack,
                    ),
                  );

                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.15),
                        end: Offset.zero,
                      ).animate(animation),
                      child: Dismissible(
                        key: ValueKey(salon["name"]),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _removeFavorite(index),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                            size: 26,
                          ),
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      Row(
                                        children: [
                                          _AnimatedBookNowButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      SalonDetailScreen(
                                                        salonName:
                                                            salon["name"]!,
                                                        salonImage:
                                                            salon["image"]!,
                                                        salonLocation:
                                                            salon["location"]!,
                                                      ),
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(width: 10),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.favorite,
                                              color: Colors.redAccent,
                                            ),
                                            onPressed: () =>
                                                _removeFavorite(index),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _AnimatedBookNowButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _AnimatedBookNowButton({required this.onPressed});

  @override
  State<_AnimatedBookNowButton> createState() => _AnimatedBookNowButtonState();
}

class _AnimatedBookNowButtonState extends State<_AnimatedBookNowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
      lowerBound: 0.0,
      upperBound: 0.1,
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();
  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }

  void _onTapCancel() => _controller.reverse();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: ElevatedButton(
          onPressed: widget.onPressed, // ✅ enabled (was null before)
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary, // ✅ primary color now visible
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            "Book Now",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
