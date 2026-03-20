import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'web3_service.dart';

class BlockchainService {
  static final Web3Service _web3 = Web3Service();

  /// Generates a SHA-256 hash of the record data
  static String generateRecordHash(Map<String, dynamic> record) {
    final String jsonString = jsonEncode(record);
    final bytes = utf8.encode(jsonString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Anchors a record hash to the MegaETH Blockchain
  /// This can be used for health records integrity.
  static Future<String> anchorToBlockchain(String dataHash) async {
    try {
      // For now, we simulate anchoring by sending a small amount of ETH or just creating a TX
      // In a real Nutreva app, the dataHash would be stored safely in contract storage or events
      final address = await _web3.getStoredAddress();
      if (address == null) return "No wallet configured";
      
      // Send a 0 ETH transaction to the contract as a "heartbeat/anchor"
      return await _web3.payForConsultation(
        professionalAddress: "0x48D75A0E1A1A8C8C6B1C9B1D9f6E3Ae2Fc6C2e59", 
        callDurationSeconds: 60, // Minimum 1 min
      );
    } catch (e) {
      return "Blockchain Anchor Error: $e";
    }
  }

  static bool verifyDataIntegrity(Map<String, dynamic> record, String storedHash) {
    final newHash = generateRecordHash(record);
    return newHash == storedHash;
  }

  // Delegate wallet functions
  static Future<String?> getWalletAddress() => _web3.getStoredAddress();
  static Future<double> getBalance(String address) => _web3.getBalance(address);
  static Future<String> createWallet() => _web3.createAndStoreWallet();
}
