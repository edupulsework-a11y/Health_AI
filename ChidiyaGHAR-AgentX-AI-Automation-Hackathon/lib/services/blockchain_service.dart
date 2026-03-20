import 'dart:convert';
import 'package:crypto/crypto.dart';
// import 'package:web3dart/web3dart.dart'; // Removed for Solana sim
// import 'package:http/http.dart' as http;
import 'dart:math'; // Added for random generation

class BlockchainService {
  // Simulating interaction with Solana Blockchain (Devnet/Mainnet)
  static const String rpcUrl = "https://api.mainnet-beta.solana.com";

  /// Generates a SHA-256 hash of the record data
  static String generateRecordHash(Map<String, dynamic> record) {
    final String jsonString = jsonEncode(record);
    final bytes = utf8.encode(jsonString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Anchors a record hash to the Solana Blockchain (Simulated)
  /// Returns a Transaction Signature (Base58 string)
  static Future<String> anchorToBlockchain(String dataHash) async {
    try {
      // In a real app, this would use 'solana_web3' package to sign and send a transaction
      // containing the 'dataHash' in the memo instruction.
      
      await Future.delayed(const Duration(seconds: 1)); // Network delay

      // Generate a realistic Solana-like Transaction Signature (Base58-like)
      // Solana signatures are typically 88 characters long (64 bytes encoded)
      return _generateSimulatedSolanaTxSignature();
    } catch (e) {
      return "Error: $e";
    }
  }

  static String _generateSimulatedSolanaTxSignature() {
    const chars = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
    final rnd = DateTime.now().microsecondsSinceEpoch;
    // Simple pseudo-random string generation for demo
    List<String> result = [];
    var val = BigInt.from(rnd) * BigInt.parse("583920193492019239"); // Add some entropy
    
    for (int i = 0; i < 88; i++) {
      val = (val * BigInt.from(58) + BigInt.from(i)) % BigInt.parse("583920193492019239123891283");
      // Use modulo to pick char
      int index = (val.remainder(BigInt.from(58))).toInt();
      result.add(chars[index]);
    }
    return result.join();
  }

  static bool verifyDataIntegrity(Map<String, dynamic> record, String storedHash) {
    final newHash = generateRecordHash(record);
    return newHash == storedHash;
  }
}
