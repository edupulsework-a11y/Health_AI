import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import 'agora_call_screen.dart';
import 'demo_call_screen.dart';
import '../../../../services/stream_service.dart';

class UnifiedConsultationModal extends StatefulWidget {
  const UnifiedConsultationModal({super.key});

  @override
  State<UnifiedConsultationModal> createState() => _UnifiedConsultationModalState();
}

class _UnifiedConsultationModalState extends State<UnifiedConsultationModal> {
  final _codeCtrl = TextEditingController(text: 'test');
  String? _generatedCode;

  void _generateCode() {
    setState(() {
      _generatedCode = (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
    });
  }

  Future<void> _startCall(String code) async {
    final provider = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Choose Call Provider'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.video_call, color: AppColors.primaryTeal),
              title: const Text('Stream Video Call'),
              subtitle: const Text('High quality · Low latency'),
              onTap: () => Navigator.pop(context, 'stream'),
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.orange),
              title: const Text('Agora Video Call'),
              subtitle: const Text('Standard reliability'),
              onTap: () => Navigator.pop(context, 'agora'),
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))],
      ),
    );

    if (provider == null || !mounted) return;

    final hasPerms = await StreamService.requestPermissions();
    if (!hasPerms) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera & Microphone permissions required.')));
      return;
    }

    if (!mounted) return;
    Navigator.pop(context);

    if (provider == 'stream') {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => DemoCallScreen(channelId: code)));
    } else {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => AgoraCallScreen(channelId: code)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF0E1A2B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Video Consultation Hub',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 32),

            // ── Host ──────────────────────────────────
            const Text('HOST A SESSION',
                style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 12),
            if (_generatedCode == null)
              ElevatedButton.icon(
                onPressed: _generateCode,
                icon: const Icon(Icons.add_call),
                label: const Text('Generate Meeting Code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withAlpha(20),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryTeal.withAlpha(60)),
                ),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(_generatedCode!,
                        style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold,
                            letterSpacing: 4, color: AppColors.primaryTeal)),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: AppColors.primaryTeal),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _generatedCode!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Code copied!')));
                      },
                    ),
                  ]),
                  ElevatedButton(
                    onPressed: () => _startCall(_generatedCode!),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Start Now', style: TextStyle(color: Colors.white)),
                  ),
                ]),
              ),

            const SizedBox(height: 32),
            const Row(children: [
              Expanded(child: Divider(color: Colors.white12)),
              Padding(padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold))),
              Expanded(child: Divider(color: Colors.white12)),
            ]),
            const SizedBox(height: 32),

            // ── Join ──────────────────────────────────
            const Text('JOIN A SESSION',
                style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 12),
            TextField(
              controller: _codeCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter channel / meeting code',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.vpn_key_outlined, color: AppColors.primaryTeal),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final code = _codeCtrl.text.trim();
                if (code.isNotEmpty) _startCall(code);
                else ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a channel name.')));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentViolet,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Join with Code', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
