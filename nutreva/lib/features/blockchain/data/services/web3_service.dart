import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';

// ── Providers ─────────────────────────────────────────
final web3ServiceProvider = Provider<Web3Service>((ref) => Web3Service());

final walletBalanceProvider =
    FutureProvider.family<double, String>((ref, address) async {
  return ref.read(web3ServiceProvider).getBalance(address);
});

// ── Contract ABI (matches NutrevaConsultation.sol) ────
const String _contractAbi = '''
[
  {"inputs": [{"internalType": "address payable","name": "_professional","type": "address"}],"name": "payForConsultation","outputs": [],"stateMutability": "payable","type": "function"},
  {"inputs": [],"name": "feePerCall","outputs": [{"internalType": "uint256","name": "","type": "uint256"}],"stateMutability": "view","type": "function"},
  {"inputs": [],"name": "getCallFee","outputs": [{"internalType": "uint256","name": "","type": "uint256"}],"stateMutability": "view","type": "function"},
  {"anonymous": false,"inputs": [{"indexed": true,"name": "patient","type": "address"},{"indexed": true,"name": "professional","type": "address"},{"indexed": false,"name": "amountWei","type": "uint256"},{"indexed": false,"name": "timestamp","type": "uint256"}],"name": "ConsultationPaid","type": "event"}
]
''';

// ── Web3 Service ──────────────────────────────────────
class Web3Service {
  late final Web3Client _client;
  final _storage = const FlutterSecureStorage();

  Web3Service() {
    _client = Web3Client(AppConstants.megaEthRpcUrl, http.Client());
  }

  // ── Wallet Management ──────────────────────────────

  /// Creates a random wallet, stores private key, returns address hex
  Future<String> createAndStoreWallet() async {
    final credentials = EthPrivateKey.createRandom(Random.secure());
    final privateKeyHex =
        credentials.privateKeyInt.toRadixString(16).padLeft(64, '0');
    await _storage.write(key: AppConstants.walletKeyRef, value: privateKeyHex);
    return credentials.address.hex;
  }

  /// Alias used by auth_service
  Future<String> createWallet() => createAndStoreWallet();

  /// Loads the stored private key credentials (null if none)
  Future<EthPrivateKey?> loadCredentials() async {
    final hex = await _storage.read(key: AppConstants.walletKeyRef);
    if (hex == null) return null;
    return EthPrivateKey.fromHex(hex);
  }

  /// Returns the stored wallet's address string
  Future<String?> getStoredAddress() async {
    final creds = await loadCredentials();
    return creds?.address.hex;
  }

  // ── Balance ────────────────────────────────────────

  Future<double> getBalance(String address) async {
    try {
      final addr = EthereumAddress.fromHex(address);
      final amount = await _client.getBalance(addr);
      return amount.getValueInUnit(EtherUnit.ether);
    } catch (_) {
      return 0.0;
    }
  }

  // ── Cost Calculation ───────────────────────────────

  Future<BigInt> calculateCost(int durationSeconds) async {
    try {
      final contract = _deployedContract();
      final fn = contract.function('calculateCost');
      final result = await _client.call(
        contract: contract,
        function: fn,
        params: [BigInt.from(durationSeconds)],
      );
      return result.first as BigInt;
    } catch (_) {
      // Fallback: 0.001 ETH per minute
      final minutes = (durationSeconds / 60).ceil();
      return BigInt.from(minutes) * BigInt.from(1000000000000000);
    }
  }

  Future<String> calculateCostEth(int durationSeconds) async {
    final wei = await calculateCost(durationSeconds);
    return (wei.toDouble() / 1e18).toStringAsFixed(6);
  }

  // ── Pay for Consultation ───────────────────────────

  Future<String> payForConsultation({
    required String professionalAddress,
    required int callDurationSeconds,
  }) async {
    final credentials = await loadCredentials();
    if (credentials == null) {
      throw Exception('No wallet found. Please set up your wallet.');
    }
    final amountWei = BigInt.from(10000000000000); // 0.00001 ETH
    final contract = _deployedContract();

    return _client.sendTransaction(
      credentials,
      Transaction.callContract(
        contract: contract,
        function: contract.function('payForConsultation'),
        parameters: [
          EthereumAddress.fromHex(professionalAddress),
        ],
        value: EtherAmount.fromBigInt(EtherUnit.wei, amountWei),
      ),
      chainId: AppConstants.chainId,
    );
  }

  // ── Send ETH directly ──────────────────────────────

  Future<String> sendEth({
    required String toAddress,
    required double amountEth,
  }) async {
    final credentials = await loadCredentials();
    if (credentials == null) throw Exception('No wallet found');

    final amountWei = BigInt.from(amountEth * 1e18);
    return _client.sendTransaction(
      credentials,
      Transaction(
        to: EthereumAddress.fromHex(toAddress),
        value: EtherAmount.fromBigInt(EtherUnit.wei, amountWei),
        gasPrice: EtherAmount.inWei(BigInt.from(20000000000)), // 20 gwei
        maxGas: 21000,
      ),
      chainId: AppConstants.chainId,
    );
  }

  // ── Helpers ────────────────────────────────────────

  DeployedContract _deployedContract() => DeployedContract(
        ContractAbi.fromJson(_contractAbi, 'NutrevaConsultation'),
        EthereumAddress.fromHex(AppConstants.contractAddress),
      );

  void dispose() => _client.dispose();
}
