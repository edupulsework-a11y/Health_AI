// ============================================================================
// main.dart — ReviewGuard: E-Commerce Product Page with On-Device ML
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/comment_analyzer.dart';
import 'pages/main_navigation.dart';

import 'services/fall_detection_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  await FallDetectionService.initialize();
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ReviewGuardApp());
}

class ReviewGuardApp extends StatelessWidget {
  const ReviewGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReviewGuard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A73E8),
          brightness: Brightness.light,
        ),
        textTheme: const TextTheme(
          displaySmall: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w700),
          titleLarge:   TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w700),
          bodyMedium:   TextStyle(fontFamily: 'Roboto'),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1A1A2E),
          elevation: 0,
          scrolledUnderElevation: 2,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1A73E8), width: 1.5),
          ),
        ),
      ),
      home: const MainNavigation(),
    );
  }
}

// ── Shared Data Model ─────────────────────────────────────────────────────────

class Review {
  final String author;
  final String text;
  final double rating;
  final DateTime postedAt;
  final String label;      // "Human" or "AI"
  final double confidence; // Confidence percentage

  const Review({
    required this.author,
    required this.text,
    required this.rating,
    required this.postedAt,
    this.label = 'Human',
    this.confidence = 100.0,
  });
}

// ── Shared Widgets (Public) ──────────────────────────────────────────────────

class ReviewCard extends StatelessWidget {
  final Review review;
  const ReviewCard({required this.review, super.key});

  @override
  Widget build(BuildContext context) {
    final bool isAi = review.label == 'AI';
    final Color badgeColor = isAi ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32);
    final Color bgColor = isAi ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF1A73E8).withValues(alpha: 0.15),
                child: Text(
                  review.author.isNotEmpty ? review.author[0].toUpperCase() : '?',
                  style: const TextStyle(color: Color(0xFF1A73E8), fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.author,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1A1A2E)),
                    ),
                    Text(
                      '${review.postedAt.day}/${review.postedAt.month}/${review.postedAt.year}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
                    ),
                  ],
                ),
              ),
              // AI/Human Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isAi ? Icons.warning_amber_rounded : Icons.verified_user_rounded, 
                         size: 12, color: badgeColor),
                    const SizedBox(width: 4),
                    Text(
                      '${review.label} (${review.confidence.toStringAsFixed(1)}%)',
                      style: TextStyle(
                        fontSize: 10, 
                        fontWeight: FontWeight.w800, 
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review.text,
            style: const TextStyle(color: Color(0xFF444444), height: 1.5, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class ReviewInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isAnalyzing;
  final bool mlReady;
  final VoidCallback onSubmit;

  const ReviewInputBar({
    required this.controller,
    required this.isAnalyzing,
    required this.mlReady,
    required this.onSubmit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + keyboardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 3,
              minLines: 1,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: mlReady ? 'Write a review...' : 'AI Shield loading...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: Icon(
                  mlReady ? Icons.edit_note_rounded : Icons.shield_outlined,
                  color: mlReady ? const Color(0xFF1A73E8) : Colors.orange,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: (isAnalyzing || !mlReady) ? null : onSubmit,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (isAnalyzing || !mlReady) 
                    ? Colors.grey.shade300 
                    : const Color(0xFF1A73E8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: isAnalyzing
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Home Page (Electronics Example) ───────────────────────────────────────────

class ProductReviewPage extends StatefulWidget {
  const ProductReviewPage({super.key});

  @override
  State<ProductReviewPage> createState() => _ProductReviewPageState();
}

class _ProductReviewPageState extends State<ProductReviewPage> {
  final CommentAnalyzer _analyzer = CommentAnalyzer();
  bool _mlReady = false;
  final TextEditingController _reviewController = TextEditingController();
  bool _isAnalyzing = false;

  final List<Review> _reviews = [
    Review(
      author: 'Priya M.',
      text: 'Absolutely love these headphones! The noise cancellation is top-notch.',
      rating: 5.0,
      postedAt: DateTime(2025, 12, 10),
      label: 'Human',
      confidence: 99.4,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initML();
  }

  Future<void> _initML() async {
    try {
      await _analyzer.initialize();
      if (mounted) setState(() => _mlReady = true);
    } catch (_) {}
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _analyzer.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final text = _reviewController.text.trim();
    if (text.isEmpty) return;
    setState(() => _isAnalyzing = true);
    
    try {
      final AnalysisResult result = await _analyzer.analyzeText(text);
      
      if (result.isHuman) {
        setState(() {
          _reviews.insert(0, Review(
            author: 'You',
            text: text,
            rating: 5.0,
            postedAt: DateTime.now(),
            label: result.label,
            confidence: result.confidence,
          ));
        });
        _reviewController.clear();
      } else {
        _showBlockedDialog(result);
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _showBlockedDialog(AnalysisResult result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('AI Detected'),
        content: Text(
          'Your review looks generated with ${result.confidence.toStringAsFixed(1)}% confidence.\n\n'
          'Please write it yourself!'
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Electronics Store')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reviews.length,
        itemBuilder: (context, index) => ReviewCard(review: _reviews[index]),
      ),
      bottomNavigationBar: ReviewInputBar(
        controller: _reviewController,
        isAnalyzing: _isAnalyzing,
        mlReady: _mlReady,
        onSubmit: _submitReview,
      ),
    );
  }
}
