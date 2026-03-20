import 'package:flutter/material.dart';
import '../services/comment_analyzer.dart';
import '../main.dart'; // import shared Review models and widgets

class ElectronicsPage extends StatefulWidget {
  const ElectronicsPage({super.key});

  @override
  State<ElectronicsPage> createState() => _ElectronicsPageState();
}

class _ElectronicsPageState extends State<ElectronicsPage> {
  final CommentAnalyzer _analyzer = CommentAnalyzer();
  bool _mlReady = false;
  final TextEditingController _reviewController = TextEditingController();
  bool _isAnalyzing = false;

  final List<Review> _reviews = [
    Review(
      author: 'Vikram S.',
      text: 'The 4K display is breathtaking. HDR content looks so vibrant!',
      rating: 5.0,
      postedAt: DateTime(2025, 12, 1),
      label: 'Human',
      confidence: 98.2,
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
          'Your tech review looks generated with ${result.confidence.toStringAsFixed(1)}% confidence.\n\n'
          'Please write it yourself!'
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF1A1A2E),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Tech Store', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              background: Container(
                color: const Color(0xFF0F172A),
                child: const Icon(Icons.laptop_chromebook_rounded, size: 80, color: Colors.blueAccent),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Gamer Ultimate Pro Laptop', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const Text('RTX 4090 | 32GB RAM | 2TB SSD', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  Text('Customer Feed', style: Theme.of(context).textTheme.titleMedium),
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
