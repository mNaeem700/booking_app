import 'package:booking_app/screens/auth/Change_Password_Screen.dart';
import 'package:booking_app/screens/profile/Edit_Profile_Screen.dart';
import 'package:booking_app/screens/profile/Help_Center_Screen.dart';
import 'package:booking_app/screens/home/Wallet_Screen.dart';
import 'package:booking_app/screens/widgets/animated_background.dart';
import 'package:booking_app/screens/widgets/app_colors.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _listAnimationController;
  AnimationController? _glowController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  double _scrollOffset = 0.0;

  final List<Map<String, dynamic>> _profileOptions = [
    {'icon': Icons.edit, 'title': 'Edit Profile'},
    {'icon': Icons.lock, 'title': 'Change Password'},
    {'icon': Icons.account_balance_wallet, 'title': 'My Wallet'},
    {'icon': Icons.help_outline, 'title': 'Help Center'},
    {'icon': Icons.logout, 'title': 'Logout'},
  ];

  @override
  void initState() {
    super.initState();

    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeIn,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _headerAnimationController,
            curve: Curves.easeOut,
          ),
        );

    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _glowController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 3),
      )..repeat(reverse: true);
      setState(() {});
    });

    _headerAnimationController.forward().then((_) {
      _listAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _listAnimationController.dispose();
    _glowController?.dispose();
    super.dispose();
  }

  Future<void> _refreshProfile() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    final glowValue = _glowController != null
        ? sin(_glowController!.value * pi) * 6
        : 0.0;
    final avatarScale = (1 - (_scrollOffset / 200)).clamp(0.7, 1.0);
    final avatarOffset = (_scrollOffset / 4).clamp(0.0, 20.0);

    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            if (scrollInfo.metrics.axis == Axis.vertical) {
              setState(() => _scrollOffset = scrollInfo.metrics.pixels);
            }
            return true;
          },
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _refreshProfile,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // 🔹 HEADER
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 800),
                            height: 230,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withAlpha(240),
                                  AppColors.primary.withAlpha(180),
                                  AppColors.primary.withAlpha(220),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(30),
                                bottomRight: Radius.circular(30),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withAlpha(90),
                                  blurRadius: 16 + glowValue,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 60 - avatarOffset,
                            child: Transform.scale(
                              scale: avatarScale,
                              child: Hero(
                                tag: 'profileAvatar',
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withAlpha(
                                          100 + (glowValue * 10).toInt(),
                                        ),
                                        blurRadius: 12 + glowValue,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: const CircleAvatar(
                                    radius: 50,
                                    backgroundImage: AssetImage(
                                      'assets/images/user.jpg',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 25,
                            child: Column(
                              children: [
                                const Text(
                                  "Naeem Ahmed",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  "naeem@example.com",
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(200),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 🔹 PROFILE OPTIONS
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final option = _profileOptions[index];
                      final isLogout = option['title'] == 'Logout';

                      return AnimatedBuilder(
                        animation: _listAnimationController,
                        builder: (context, child) {
                          final delay = index * 0.1;
                          final animValue =
                              (_listAnimationController.value - delay).clamp(
                                0.0,
                                1.0,
                              );
                          final tilt = (1 - animValue) * 0.1;

                          return Opacity(
                            opacity: animValue,
                            child: Transform(
                              transform: Matrix4.identity()
                                ..translate(0.0, 30 * (1 - animValue))
                                ..rotateZ(tilt),
                              alignment: Alignment.center,
                              child: child,
                            ),
                          );
                        },
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _handleTap(option['title']),
                          splashColor: AppColors.primary.withAlpha(30),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOut,
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              color: isLogout
                                  ? Colors.red.withAlpha(15)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: isLogout
                                  ? Border.all(color: Colors.red, width: 2)
                                  : null,
                              boxShadow: [
                                if (!isLogout)
                                  BoxShadow(
                                    color: Colors.black.withAlpha(20),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isLogout
                                        ? Colors.red.withAlpha(30)
                                        : AppColors.primary.withAlpha(30),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    option['icon'],
                                    color: isLogout
                                        ? Colors.red
                                        : AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    option['title'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isLogout
                                          ? Colors.red
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: isLogout ? Colors.red : Colors.grey,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }, childCount: _profileOptions.length),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 50)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 Handles navigation and logout dialog
  void _handleTap(String title) {
    switch (title) {
      case 'Edit Profile':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EditProfileScreen()),
        );
        break;
      case 'Change Password':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
        );
        break;
      case 'My Wallet':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WalletScreen()),
        );
        break;
      case 'Help Center':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
        );
        break;
      case 'Logout':
        _showLogoutDialog();
        break;
    }
  }

  // 🔹 Professional logout confirmation
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Confirm Logout"),
        content: const Text(
          "Are you sure you want to logout?",
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Logged out successfully!"),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 1),
                ),
              );
              // TODO: Add your actual logout logic here (Firebase/Auth)
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }
}
