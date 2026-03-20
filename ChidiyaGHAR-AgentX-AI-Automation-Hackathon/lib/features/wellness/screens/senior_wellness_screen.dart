import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../../services/dual_ai_service.dart';

class SeniorWellnessScreen extends StatefulWidget {
  const SeniorWellnessScreen({super.key});

  @override
  State<SeniorWellnessScreen> createState() => _SeniorWellnessScreenState();
}

class _SeniorWellnessScreenState extends State<SeniorWellnessScreen> {
  final DualAiService _aiService = DualAiService();
  final TextEditingController _chatController = TextEditingController();
  final List<Message> _messages = [];
  bool _isTyping = false;

  void _sendMessage() async {
    if (_chatController.text.isEmpty) return;
    
    final query = _chatController.text;
    setState(() {
      _messages.add(Message(text: query, isUser: true));
      _isTyping = true;
      _chatController.clear();
    });

    final response = await _aiService.getAyurvedicAdvice(query);

    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add(Message(text: response, isUser: false));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Premium Background with Mandala Opacity
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)], // Soft Gold/Cream
              ),
            ),
          ),
          Positioned(
            right: -100,
            top: -100,
            child: Opacity(
              opacity: 0.1,
              child: Image.asset('assets/mandala_bg.png', width: 400), // Assuming asset exists or use Icon placeholder
            ),
          ),

          // 2. Main Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMobilityCard(),
                        const SizedBox(height: 20),
                        _buildDoshaInsight(),
                        const SizedBox(height: 20),
                        const Text("Wellness Modules", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF5D4037))),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildModuleCard(context, "https://cdn-icons-png.flaticon.com/512/10438/10438127.png", "Chair Yoga", "Ginger (Adrak)", "Follow these steps for Chair Yoga:\n\n1. Sit upright with feet flat.\n2. Inhale and lift arms.\n3. Exhale and twist to the right.\n4. Repeat for 5 minutes.")),
                            const SizedBox(width: 12),
                            Expanded(child: _buildModuleCard(context, "https://cdn-icons-png.flaticon.com/512/11556/11556627.png", "Heart Health", "Garlic (Lahasun)", "Ayurvedic Heart Care:\n\n• Arjun Tea in the morning.\n• Gentle walking (Prana walk).\n• Reduce salty and fried foods.")),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildModuleCard(context, "https://cdn-icons-png.flaticon.com/512/10431/10431707.png", "Pain Relief", "Turmeric (Haldi)", "Joint Pain Relief:\n\n• Apply warm sesame oil.\n• Use Turmeric & Ginger paste.\n• Avoid cold drafts and ice water.")),
                            const SizedBox(width: 12),
                            Expanded(child: _buildModuleCard(context, "https://cdn-icons-png.flaticon.com/512/11548/11548590.png", "Sleep Aid", "Tulsi (Basil)", "Better Sleep:\n\n• Warm milk with nutmeg.\n• Massage feet with ghee.\n• Practice Brahmari Pranayama.")),
                          ],
                        ),
                        const SizedBox(height: 30),
                        const Text("Ask AI Vaidya", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF5D4037))),
                        const Text("Holistic Wisdom Powered by Groq", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 12),
                        _buildChatInterface(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF5D4037)),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            "Holistic Wellness",
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF5D4037),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobilityCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: 0.85,
                  strokeWidth: 8,
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              ),
              const Text("85", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
            ],
          ),
          const SizedBox(width: 24),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Excellent Mobility", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5D4037))),
                Text("Your daily walks are paying off. Joint flexibility is high today.", style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoshaInsight() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFEFEBE9), Color(0xFFD7CCC8)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.balance, color: Color(0xFF5D4037), size: 30),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Dosha Insight: Vata Balanced", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF5D4037))),
                Text("Focus on warm, cooked foods today to maintain stability.", style: TextStyle(fontSize: 13, color: Color(0xFF4E342E))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(BuildContext context, String imageUrl, String title, String subtitle, String detail) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Image.network(imageUrl, width: 50, height: 50, errorBuilder: (c, e, s) => const Icon(Icons.spa, color: Colors.orange)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF5D4037))),
                          Text(subtitle, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(detail, style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.6)),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5D4037),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("Start Wellness Session", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.withOpacity(0.05)),
          boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 60,
              width: 60,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Image.network(
                imageUrl, 
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const Icon(Icons.local_florist, color: Colors.orange),
              ),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF5D4037))),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInterface() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.brown.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 260),
                    decoration: BoxDecoration(
                      color: msg.isUser ? const Color(0xFF5D4037) : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(color: msg.isUser ? Colors.white : Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("AI Vaidya is thinking...", style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: InputDecoration(
                      hintText: "Ask about knee pain, diet...",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF5D4037),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Message {
  final String text;
  final bool isUser;
  Message({required this.text, required this.isUser});
}
