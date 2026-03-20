import 'package:flutter/material.dart';
import '../services/comment_analyzer.dart';
import '../main.dart'; // import shared Review models and widgets

class TravelPage extends StatefulWidget {
  const TravelPage({super.key});

  @override
  State<TravelPage> createState() => _TravelPageState();
}

class _TravelPageState extends State<TravelPage> {
  final CommentAnalyzer _analyzer = CommentAnalyzer();
  bool _mlReady = false;
  final TextEditingController _reviewController = TextEditingController();
  bool _isAnalyzing = false;

  final List<Review> _reviews = [
    Review(
      author: 'Kabir L.',
      text: 'The mountain view from the balcony was surreal. Highly recommend this resort!',
      rating: 5.0,
      postedAt: DateTime(2025, 12, 8),
      label: 'Human',
      confidence: 96.8,
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
          'Your travel review looks generated with ${result.confidence.toStringAsFixed(1)}% confidence.\n\n'
          'Please write it yourself!'
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF059669),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Travel Escapes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              background: Container(
                color: const Color(0xFFD1FAE5),
                child: const Icon(Icons.beach_access_rounded, size: 80, color: Color(0xFF10B981)),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Blue Lagoon Coastal Resort', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const Text('All-Inclusive | Private Beach | Wellness Spa', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  Text('Traveler Stories', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ReviewCard(review: _reviews[index]),
              ),
              childCount: _reviews.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      bottomSheet: ReviewInputBar(
        controller: _reviewController,
        isAnalyzing: _isAnalyzing,
        mlReady: _mlReady,
        onSubmit: _submitReview,
      ),
    );
  }
}
