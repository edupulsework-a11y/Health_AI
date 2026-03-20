import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? extra;
  const PaymentScreen({super.key, this.extra});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _processing = false;
  String? _txHash;

  Future<void> _pay() async {
    setState(() => _processing = true);
    // Placeholder payment — real impl uses payProfessional on Web3Service
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _processing = false;
      _txHash = '0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890';
    });
  }

  @override
  Widget build(BuildContext context) {
    final doctor = widget.extra?['doctor'] as Map<String, dynamic>?;
    final fee = doctor?['fee'] as int? ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (doctor != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(child: Icon(Icons.person_rounded)),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doctor['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(doctor['specialty'] as String, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Payment summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withAlpha(20),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryTeal.withAlpha(60)),
              ),
              child: Column(
                children: [
                  _PayRow(label: 'Consultation Fee', value: '₹$fee'),
                  _PayRow(label: 'Platform Fee', value: '₹${(fee * 0.1).toInt()}'),
                  const Divider(),
                  _PayRow(
                    label: 'Total',
                    value: '₹${fee + (fee * 0.1).toInt()}',
                    bold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.account_balance_wallet_rounded, color: AppColors.primaryTeal, size: 18),
                SizedBox(width: 8),
                Text('Paying via MegaETH wallet', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
            const Spacer(),
            if (_txHash != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withAlpha(60)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.check_circle_rounded, color: AppColors.success),
                      SizedBox(width: 8),
                      Text('Payment Successful!', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 8),
                    Text('Tx Hash: ${_txHash!.substring(0, 20)}...',
                        style: const TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'monospace')),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/dashboard'),
                  child: const Text('Back to Dashboard'),
                ),
              ),
            ] else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.currency_bitcoin_rounded),
                  label: _processing
                      ? const Row(mainAxisSize: MainAxisSize.min, children: [
                          SizedBox(height: 18, width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                          SizedBox(width: 8),
                          Text('Processing...')
                        ])
                      : const Text('Pay via Smart Contract',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  onPressed: _processing ? null : _pay,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PayRow extends StatelessWidget {
  final String label, value;
  final bool bold;
  const _PayRow({required this.label, required this.value, this.bold = false});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: bold ? AppColors.primaryTeal : null)),
        ],
      ),
    );
  }
}
