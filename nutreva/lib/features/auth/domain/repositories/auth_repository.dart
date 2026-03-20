import 'package:nutreva/core/error/failures.dart';
import '../models/user_model.dart';
import 'package:multiple_result/multiple_result.dart';

abstract class AuthRepository {
  Future<Result<UserModel, Failure>> login(String email, String password);
  Future<Result<UserModel, Failure>> signUp(String email, String password, String name);
  Future<Result<UserModel, Failure>> googleSignIn();
  Future<Result<void, Failure>> logout();
  Future<Result<bool, Failure>> verifyABHA(String abhaId);
}
