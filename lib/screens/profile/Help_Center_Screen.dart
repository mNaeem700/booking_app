import 'package:booking_app/screens/widgets/animated_background.dart';
import 'package:booking_app/screens/widgets/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Map<String, String>> faqs = [];
  String supportEmail = 'support@salonapp.com';
  String supportWhatsApp = 'https://wa.me/923000000000';
  String supportPhone = '+923000000000';

  List<bool> isExpanded = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    _loadFAQsAndSupport();
  }

  Future<void> _loadFAQsAndSupport() async {
    try {
      // Fetch FAQs
      final faqSnapshot = await _db
          .collection('faqs')
          .orderBy('question')
          .get();
      final loadedFaqs = faqSnapshot.docs.map((doc) {
        return {
          'question': (doc['question'] ?? '').toString(),
          'answer': (doc['answer'] ?? '').toString(),
        };
      }).toList();

      // Fetch support info
      final supportDoc = await _db.collection('settings').doc('support').get();
      final email = supportDoc['email'] ?? supportEmail;
      final whatsapp = supportDoc['whatsapp'] ?? supportWhatsApp;
      final phone = supportDoc['phone'] ?? supportPhone;

      if (mounted) {
        setState(() {
          faqs = loadedFaqs.isNotEmpty
              ? loadedFaqs.cast<Map<String, String>>()
              : [];
          supportEmail = email;
          supportWhatsApp = whatsapp;
          supportPhone = phone;
          isExpanded = List.generate(faqs.length, (_) => false);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load FAQs/support: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Could not open this link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Help Center'),
          backgroundColor: Colors.white.withOpacity(0.9),
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        "Frequently Asked Questions",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (faqs.isEmpty)
                        const Text(
                          "No FAQs available at the moment.",
                          style: TextStyle(fontSize: 15),
                        ),
                      // 🔹 FAQ Section
                      ...faqs.asMap().entries.map((entry) {
                        final i = entry.key;
                        final faq = entry.value;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ExpansionTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            collapsedShape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            iconColor: AppColors.primary,
                            collapsedIconColor: AppColors.primary,
                            title: Text(
                              faq['question']!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            childrenPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            onExpansionChanged: (value) {
                              setState(() => isExpanded[i] = value);
                            },
                            children: [
                              Text(
                                faq['answer']!,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  height: 1.5,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 30),
                      Text(
                        "Need More Help?",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 🔹 Contact Support Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "Our support team is available 24/7 to help you with your issues or questions.",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 15, height: 1.5),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildContactButton(
                                  icon: Icons.email_rounded,
                                  label: "Email",
                                  color: AppColors.primary,
                                  onTap: () => _launchUrl(
                                    'mailto:$supportEmail?subject=Support%20Request',
                                  ),
                                ),
                                _buildContactButton(
                                  icon: Icons.chat_rounded,
                                  label: "WhatsApp",
                                  color: Colors.green,
                                  onTap: () => _launchUrl(supportWhatsApp),
                                ),
                                _buildContactButton(
                                  icon: Icons.call_rounded,
                                  label: "Call",
                                  color: Colors.blueAccent,
                                  onTap: () => _launchUrl('tel:$supportPhone'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
