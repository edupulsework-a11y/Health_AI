import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final List<_ChatMsg> _messages = [
    const _ChatMsg(
      text: "Hello! I'm your Nutreva Health Assistant powered by Llama 3.3 🧠. How can I help you today?",
      isUser: false,
    ),
  ];
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _loading = false;

  final _quickReplies = const [
    "What should I eat today?",
    "Low energy diet tips",
    "Diet for stress",
    "How much protein do I need?",
    "Best foods for sleep",
  ];

  Future<void> _send([String? override]) async {
    final text = override ?? _ctrl.text.trim();
    if (text.isEmpty || _loading) return;

    setState(() {
      _messages.add(_ChatMsg(text: text, isUser: true));
      _ctrl.clear();
      _loading = true;
    });
    _scrollDown();

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConstants.grokApiKey}',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a helpful and knowledgeable AI health assistant for Nutreva, an AI-powered digital health ecosystem. '
                  'Provide concise, accurate health, nutrition, and fitness advice. '
                  'Always mention consulting a doctor for medical conditions.'
            },
            {'role': 'user', 'content': text},
          ],
          'temperature': 0.7,
        }),
      );

      final reply = response.statusCode == 200
          ? jsonDecode(response.body)['choices'][0]['message']['content'].toString().trim()
          : "Sorry, I'm having trouble connecting right now. Please try again.";

      if (mounted) setState(() => _messages.add(_ChatMsg(text: reply, isUser: false)));
    } catch (e) {
      if (mounted) setState(() => _messages.add(_ChatMsg(text: "Error: $e", isUser: false)));
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollDown();
    }
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Health Chat'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(children: [
              Icon(Icons.bolt_rounded, color: AppColors.primaryTeal, size: 14),
              SizedBox(width: 4),
              Text('Llama 3.3', style: TextStyle(color: AppColors.primaryTeal, fontSize: 11, fontWeight: FontWeight.bold)),
            ]),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _messages.length && _loading) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: _TypingIndicator(),
                    ),
                  );
                }
                return _messages[i];
              },
            ),
          ),

          // Quick replies
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _quickReplies.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(_quickReplies[i], style: const TextStyle(fontSize: 12)),
                  backgroundColor: AppColors.primaryTeal.withAlpha(20),
                  side: BorderSide(color: AppColors.primaryTeal.withAlpha(60)),
                  onPressed: () => _send(_quickReplies[i]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    minLines: 1,
                    maxLines: 4,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Ask anything about health...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      filled: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _loading ? null : () => _send(),
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      gradient: _loading ? null : LinearGradient(
                        colors: [AppColors.primaryTeal, AppColors.accentViolet],
                      ),
                      color: _loading ? Colors.grey.withAlpha(60) : null,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _loading ? Icons.hourglass_empty_rounded : Icons.send_rounded,
                      color: Colors.white, size: 20,
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
}

class _ChatMsg extends StatelessWidget {
  final String text;
  final bool isUser;
  const _ChatMsg({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(colors: [AppColors.primaryTeal, AppColors.accentViolet])
              : null,
          color: isUser ? null : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
            bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) {
      return AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: AppColors.primaryTeal.withAlpha(
              (((_anim.value + i * 0.3) % 1.0) * 200 + 55).toInt()),
            shape: BoxShape.circle,
          ),
        ),
      );
    }));
  }
}
