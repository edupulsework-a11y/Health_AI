import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/services/web3_service.dart';

// ── Send dialog state ─────────────────────────────────
final _sendToCtrl = TextEditingController();
final _sendAmtCtrl = TextEditingController();

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  bool _sending = false;
  String? _lastTxHash;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final address = user?.walletAddress ?? '';

    // Live balance from MegaETH RPC
    final balanceAsync = ref.watch(walletBalanceProvider(address));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutreva Wallet'),
        actions: [
          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(walletBalanceProvider(address)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Wallet Card ──────────────────────────
            _WalletCard(
              address: address,
              balanceAsync: balanceAsync,
            ),
            const SizedBox(height: 20),

            // ── Actions ──────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _WalletAction(
                    icon: Icons.arrow_upward_rounded,
                    label: 'Send',
                    color: AppColors.primaryTeal,
                    onTap: () => _showSendDialog(context, address),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _WalletAction(
                    icon: Icons.arrow_downward_rounded,
                    label: 'Receive',
                    color: AppColors.accentViolet,
                    onTap: () => _showReceiveDialog(context, address),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _WalletAction(
                    icon: Icons.open_in_browser_rounded,
                    label: 'Explorer',
                    color: AppColors.info,
                    onTap: () => _openExplorer(address),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Network Info ─────────────────────────
            _NetworkInfoCard(),
            const SizedBox(height: 24),

            // ── Last Transaction ─────────────────────
            if (_lastTxHash != null) ...[
              const Text('Last Transaction',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              _TxHashCard(txHash: _lastTxHash!),
              const SizedBox(height: 24),
            ],

            // ── Consultation Estimator ────────────────
            _ConsultationEstimator(),
            const SizedBox(height: 16),

            // ── Disclaimer ───────────────────────────
            const Center(
              child: Text(
                'Running on MegaETH Testnet · Not real funds',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSendDialog(BuildContext context, String fromAddress) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Send ETH',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _sendToCtrl,
              decoration: const InputDecoration(
                labelText: 'Recipient Address (0x...)',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sendAmtCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount (ETH)',
                prefixIcon: Icon(Icons.currency_exchange_rounded),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _sending
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded),
                label:
                    Text(_sending ? 'Sending...' : 'Confirm & Send'),
                onPressed: _sending
                    ? null
                    : () async {
                        setState(() => _sending = true);
                        Navigator.pop(context);
                        try {
                          final hash = await ref
                              .read(web3ServiceProvider)
                              .sendEth(
                                toAddress: _sendToCtrl.text.trim(),
                                amountEth: double.parse(
                                    _sendAmtCtrl.text.trim()),
                              );
                          setState(() => _lastTxHash = hash);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Sent! TX: ${hash.substring(0, 12)}...'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        } finally {
                          setState(() => _sending = false);
                          ref.invalidate(walletBalanceProvider(fromAddress));
                        }
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReceiveDialog(BuildContext context, String address) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Your Wallet Address',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(12)),
              child: Text(address,
                  style: const TextStyle(
                      fontFamily: 'monospace', fontSize: 13))),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy Address'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: address));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Address copied!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openExplorer(String address) {
    // MegaETH testnet explorer URL (update when live explorer is available)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Explorer: megaeth.testnet/address/$address')),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────

class _WalletCard extends StatelessWidget {
  final String address;
  final AsyncValue<double> balanceAsync;
  const _WalletCard({required this.address, required this.balanceAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1B3E), AppColors.accentViolet],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentViolet.withAlpha(80),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Text('MegaETH Testnet',
                  style: TextStyle(color: Colors.white60, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 20),

          // Balance
          balanceAsync.when(
            data: (bal) => Text(
              '${bal.toStringAsFixed(6)} ETH',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5),
            ),
            loading: () => const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            ),
            error: (_, __) => const Text('Could not fetch balance',
                style: TextStyle(color: Colors.red)),
          ),
          const SizedBox(height: 6),

          // Address
          if (address.isNotEmpty)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: address));
              },
              child: Row(
                children: [
                  Text(
                    '${address.substring(0, 12)}...${address.substring(address.length - 8)}',
                    style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        fontFamily: 'monospace'),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.copy_rounded,
                      color: Colors.white38, size: 14),
                ],
              ),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Chip(label: 'Chain: 6342'),  // MegaETH testnet chain ID
              const SizedBox(width: 8),
              _Chip(label: 'TESTNET', warning: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool warning;
  const _Chip({required this.label, this.warning = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: warning ? AppColors.warning.withAlpha(40) : Colors.white12,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                color: warning ? AppColors.warning : Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      );
}

class _NetworkInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Network',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          _InfoRow(label: 'RPC', value: 'rpc.megaeth.com'),
          _InfoRow(label: 'Chain ID', value: '6342'),
          _InfoRow(label: 'Symbol', value: 'ETH'),
          _InfoRow(
              label: 'Contract',
              value: '0x1234...5678 (NutrevaConsultation)'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                    const TextStyle(color: Colors.grey, fontSize: 12)),
            Text(value,
                style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
}

class _ConsultationEstimator extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ConsultationEstimator> createState() =>
      _ConsultationEstimatorState();
}

class _ConsultationEstimatorState
    extends ConsumerState<_ConsultationEstimator> {
  int _minutes = 15;
  String _estimatedCost = '...';
  bool _calculating = false;

  @override
  void initState() {
    super.initState();
    _estimateCost();
  }

  Future<void> _estimateCost() async {
    setState(() => _calculating = true);
    try {
      final eth = await ref
          .read(web3ServiceProvider)
          .calculateCostEth(_minutes * 60);
      setState(() => _estimatedCost = '$eth ETH');
    } catch (_) {
      // Fallback: 0.001 ETH/min
      setState(() =>
          _estimatedCost = '${(_minutes * 0.001).toStringAsFixed(4)} ETH');
    } finally {
      setState(() => _calculating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryTeal.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryTeal.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calculate_rounded,
                  color: AppColors.primaryTeal, size: 18),
              SizedBox(width: 8),
              Text('Consultation Cost Estimator',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTeal,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Duration: ', style: TextStyle(fontSize: 13)),
              Expanded(
                child: Slider(
                  value: _minutes.toDouble(),
                  min: 5,
                  max: 60,
                  divisions: 11,
                  activeColor: AppColors.primaryTeal,
                  label: '$_minutes min',
                  onChanged: (v) {
                    setState(() => _minutes = v.toInt());
                    _estimateCost();
                  },
                ),
              ),
              Text('$_minutes min',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Estimated Cost:',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              _calculating
                  ? const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_estimatedCost,
                      style: const TextStyle(
                          color: AppColors.primaryTeal,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
              'Rate: 0.001 ETH/min · 10% platform fee included',
              style: TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }
}

class _TxHashCard extends StatelessWidget {
  final String txHash;
  const _TxHashCard({required this.txHash});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withAlpha(60)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Transaction Confirmed',
                    style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                Text(
                  '${txHash.substring(0, 14)}...${txHash.substring(txHash.length - 8)}',
                  style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.grey),
            onPressed: () =>
                Clipboard.setData(ClipboardData(text: txHash)),
          ),
        ],
      ),
    );
  }
}

class _WalletAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _WalletAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
