import 'package:booking_app/screens/widgets/animated_background.dart';
import 'package:booking_app/screens/widgets/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'booking_screen.dart';

class SalonDetailScreen extends StatefulWidget {
  final String salonName;
  final String salonImage;
  final String salonLocation;
  final String? salonId;

  const SalonDetailScreen({
    super.key,
    required this.salonName,
    required this.salonImage,
    required this.salonLocation,
    this.salonId,
  });

  @override
  State<SalonDetailScreen> createState() => _SalonDetailScreenState();
}

class _SalonDetailScreenState extends State<SalonDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Salon details
  late String _name;
  late String _image;
  late String _location;
  String _description = '';
  double _rating = 4.8;
  bool _isLoading = false;

  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _reviews = [];
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _name = widget.salonName;
    _image = widget.salonImage;
    _location = widget.salonLocation;

    _loadSalonDetails();
    if (widget.salonId != null) _loadReviews();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    if (widget.salonId == null) return;
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(widget.salonId)
        .get();
    setState(() {
      _isFavorite = doc.exists;
    });
  }

  Future<void> _toggleFavorite() async {
    if (widget.salonId == null) return;
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      _showSnackBar("Please sign in to manage favorites.");
      return;
    }

    final docRef = _db
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(widget.salonId);

    if (_isFavorite) {
      await docRef.delete();
      setState(() => _isFavorite = false);
      _showSnackBar("Removed from favorites");
    } else {
      await docRef.set({
        'salonId': widget.salonId,
        'salonName': _name,
        'salonImage': _image,
        'salonLocation': _location,
        'rating': _rating,
      });
      setState(() => _isFavorite = true);
      _showSnackBar("Added to favorites");
    }
  }

  Future<void> _loadSalonDetails() async {
    if (widget.salonId == null) return;
    try {
      final doc = await _db.collection('salons').doc(widget.salonId).get();
      if (!doc.exists) return;
      final data = doc.data()!;
      setState(() {
        _description = data['description'] ?? '';
        _rating = (data['rating'] is num)
            ? (data['rating'] as num).toDouble()
            : 4.8;
        final raw = data['services'] as List?;
        if (raw != null) {
          _services = raw.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      });
    } catch (_) {}
  }

  Future<void> _loadReviews() async {
    if (widget.salonId == null) return;
    try {
      final snapshot = await _db
          .collection('salons')
          .doc(widget.salonId)
          .collection('reviews')
          .orderBy('timestamp', descending: true)
          .get();

      final reviews = snapshot.docs.map((d) => d.data()).toList();
      double total = 0;
      for (final r in reviews) {
        total += (r['rating'] ?? 0).toDouble();
      }

      setState(() {
        _reviews = reviews.cast<Map<String, dynamic>>();
        if (reviews.isNotEmpty) _rating = total / reviews.length;
      });
    } catch (_) {}
  }

  Future<void> _addReview() async {
    final user = _auth.currentUser;
    if (user == null) {
      _showSnackBar("Please sign in to add a review.");
      return;
    }

    double rating = 5;
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: StatefulBuilder(
            builder: (context, setModal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Add Your Review",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () => setModal(() => rating = index + 1.0),
                      );
                    }),
                  ),
                  TextField(
                    controller: controller,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Write your experience...",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (controller.text.trim().isEmpty) {
                        _showSnackBar("Please write a review.");
                        return;
                      }

                      Navigator.pop(context);
                      setState(() => _isLoading = true);

                      await _db
                          .collection('salons')
                          .doc(widget.salonId)
                          .collection('reviews')
                          .add({
                            'userId': user.uid,
                            'userName': user.displayName ?? 'Anonymous',
                            'review': controller.text.trim(),
                            'rating': rating,
                            'timestamp': FieldValue.serverTimestamp(),
                          });

                      _showSnackBar("Review added successfully!");
                      await _loadReviews();
                      setState(() => _isLoading = false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.send),
                    label: const Text(
                      "Submit",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _servicesTab() {
    if (_services.isEmpty) {
      return const Center(child: Text("No services available"));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _services.length,
      itemBuilder: (context, i) {
        final s = _services[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(s['name'] ?? "Service"),
            subtitle: Text(s['time'] ?? ""),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (widget.salonId == null) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingScreen(
                      salonId: widget.salonId!,
                      serviceName: s['name'] ?? "Service",
                      servicePrice: (s['price'] ?? 0).toDouble(),
                      salonName: _name,
                      salonImage: _image,
                      salonRating: _rating,
                      price: s['price']?.toDouble(),
                      imagePath: _image,
                    ),
                  ),
                );
              },
              child: Text("Rs ${s['price'] ?? 0}"),
            ),
          ),
        );
      },
    );
  }

  Widget _reviewsTab() {
    if (widget.salonId == null) {
      return const Center(child: Text("No reviews available"));
    }

    return Stack(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: _db
              .collection('salons')
              .doc(widget.salonId)
              .collection('reviews')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(child: Text("No reviews yet"));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final r = docs[i].data() as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.15),
                      child: const Icon(Icons.person, color: Colors.black54),
                    ),
                    title: Row(
                      children: [
                        Text(
                          r['userName'] ?? 'User',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 6),
                        Row(
                          children: List.generate(
                            (r['rating'] ?? 0).toInt(),
                            (index) => const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(r['review'] ?? ''),
                    ),
                  ),
                );
              },
            );
          },
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            backgroundColor: AppColors.primary,
            onPressed: _addReview,
            child: const Icon(Icons.add_comment_outlined),
          ),
        ),
      ],
    );
  }

  Widget _aboutTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "About This Salon",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          _description.isEmpty
              ? "Luxury grooming services for modern clients. Experience top-quality styling, spa, and relaxation treatments."
              : _description,
          style: const TextStyle(height: 1.5),
        ),
        const SizedBox(height: 20),
        Text("📍 $_location"),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber),
            const SizedBox(width: 4),
            Text("${_rating.toStringAsFixed(1)} / 5.0"),
          ],
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: FadeTransition(
          opacity: _fadeController,
          child: Column(
            children: [
              Stack(
                children: [
                  _image.startsWith('http')
                      ? Image.network(
                          _image,
                          height: 280,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          _image,
                          height: 280,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                  Container(
                    height: 280,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.6),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    left: 10,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                  // FAVORITE ICON
                  Positioned(
                    top: 40,
                    right: 16,
                    child: IconButton(
                      onPressed: _toggleFavorite,
                      icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: Colors.redAccent,
                        size: 28,
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
                          _name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.white70,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _location,
                                style: const TextStyle(color: Colors.white70),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _rating.toStringAsFixed(1),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppColors.primary,
                  tabs: const [
                    Tab(text: "Services"),
                    Tab(text: "Reviews"),
                    Tab(text: "About"),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_servicesTab(), _reviewsTab(), _aboutTab()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
