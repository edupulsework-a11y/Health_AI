import 'package:supabase_flutter/supabase_flutter.dart';
import 'blockchain_service.dart';
import 'dart:io';

class PaymentService {
  final _supabase = Supabase.instance.client;

  /// Processes a specialist fee, uploads receipt, and logs it
  Future<Map<String, dynamic>?> processSpecialistPayment({
    required String userId,
    required String specialistId,
    required double amount,
    required String serviceType,
    required File receiptFile,
  }) async {
    try {
      // 1. Upload Receipt to Supabase Storage
      final String fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final String path = '$userId/$fileName';
      
      await _supabase.storage.from('receipts').upload(path, receiptFile);
      final String receiptUrl = _supabase.storage.from('receipts').getPublicUrl(path);

      final paymentData = {
        'user_id': userId,
        'specialist_id': specialistId,
        'amount': amount,
        'service_type': serviceType,
        'status': 'success',
        'receipt_url': receiptUrl,
        'created_at': DateTime.now().toIso8601String(),
      };

      // 2. Log to Supabase Database
      await _supabase.from('payments').insert(paymentData);

      // 3. Hash and Anchor to Blockchain (Polygon)
      final recordHash = BlockchainService.generateRecordHash(paymentData);
      final txHash = await BlockchainService.anchorToBlockchain(recordHash);

      return {
        'status': 'success',
        'record_hash': recordHash,
        'blockchain_tx': txHash,
        'receipt_url': receiptUrl,
      };
    } catch (e) {
      print('Payment Error: $e');
      return null;
    }
  }
}
