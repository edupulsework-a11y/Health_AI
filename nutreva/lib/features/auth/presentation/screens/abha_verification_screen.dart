import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class AbhaVerificationScreen extends ConsumerStatefulWidget {
  const AbhaVerificationScreen({super.key});

  @override
  ConsumerState<AbhaVerificationScreen> createState() =>
      _AbhaVerificationScreenState();
}

class _AbhaVerificationScreenState
    extends ConsumerState<AbhaVerificationScreen> {
  final _abhaCtrl = TextEditingController();
  bool _loading = false;
  bool _verified = false;

  @override
  void dispose() {
    _abhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() => _loading = true);
    await ref.read(authNotifierProvider.notifier).verifyABHA(_abhaCtrl.text);
    setState(() {
      _loading = false;
      _verified = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ABHA Verification')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accentViolet.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accentViolet.withAlpha(80)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.accentViolet),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'ABHA (Ayushman Bharat Health Account) verification is optional but unlocks advanced features.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (_verified) ...[
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.verified_rounded,
                        size: 64, color: AppColors.success),
                    SizedBox(height: 12),
                    Text('ABHA Verified!',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success)),
                  ],
                ),
              ),
            ] else ...[
              TextFormField(
                controller: _abhaCtrl,
                decoration: const InputDecoration(
                  labelText: 'ABHA Number / ABHA ID',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _verify,
                  child: _loading
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)
                      : const Text('Verify',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/dashboard'),
                  child: const Text('Skip for now'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
