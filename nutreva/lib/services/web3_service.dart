import 'dart:math';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/api_keys.dart';

class Web3Service {
  late final Web3Client _client;
  final _storage = const FlutterSecureStorage();

  Web3Service() {
    _client = Web3Client(ApiKeys.megaEthRpcUrl, http.Client());
  }

  Future<String> createAndStoreWallet() async {
    final credentials = EthPrivateKey.createRandom(Random.secure());
    final privateKeyHex = credentials.privateKeyInt.toRadixString(16).padLeft(64, '0');
    await _storage.write(key: ApiKeys.walletKeyRef, value: privateKeyHex);
    return credentials.address.hex;
  }

  Future<String> createWallet() => createAndStoreWallet();

  Future<EthPrivateKey?> loadCredentials() async {
    final hex = await _storage.read(key: ApiKeys.walletKeyRef);
    if (hex == null) return null;
    return EthPrivateKey.fromHex(hex);
  }

  Future<String?> getStoredAddress() async {
    final creds = await loadCredentials();
    return creds?.address.hex;
  }

  Future<double> getBalance(String address) async {
    try {
      final addr = EthereumAddress.fromHex(address);
      final amount = await _client.getBalance(addr);
      return amount.getValueInUnit(EtherUnit.ether);
    } catch (_) {
      return 0.0;
    }
  }

  Future<String> payForConsultation({
    required String professionalAddress,
    required int callDurationSeconds,
  }) async {
    final credentials = await loadCredentials();
    if (credentials == null) throw Exception('No wallet found.');

    final contract = DeployedContract(
      ContractAbi.fromJson('[{"inputs":[{"internalType":"address payable","name":"_professional","type":"address"}],"name":"payForConsultation","outputs":[],"stateMutability":"payable","type":"function"}]', 'NutrevaConsultation'),
      EthereumAddress.fromHex(ApiKeys.contractAddress),
    );

    // Using the flat fee mentioned: 0.00001 ETH
    final amountWei = BigInt.from(10000000000000); // 10^13 wei = 0.00001 ETH

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
      chainId: ApiKeys.chainId,
    );
  }
}
