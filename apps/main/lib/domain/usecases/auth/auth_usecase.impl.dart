part of 'auth_usecase.dart';

@Injectable(as: AuthUsecase)
class AuthInteractorImpl extends AuthUsecase {
  AuthInteractorImpl(this.localDataManager, this.appApiService);

  final LocalDataManager localDataManager;
  final AppApiService appApiService;

  @override
  Future<AuthResponse> signin({
    required String username,
    required String password,
  }) async {
    final result = AuthResultDto.fromJson(
      await appApiService.signin(
        SigninRequest(username: username, password: password).toJson(),
      ),
    );
    return _persistAuthResult(result);
  }

  @override
  Future<AuthResponse> signup({
    required String name,
    required String username,
    required String password,
  }) async {
    final result = AuthResultDto.fromJson(
      await appApiService.signup(
        SignupRequest(
          name: name,
          username: username,
          password: password,
        ).toJson(),
      ),
    );
    return _persistAuthResult(result);
  }

  @override
  Future<AuthResponse> loginWithPhoneNumberPassword({
    required String phoneNumber,
    required String password,
  }) {
    return signin(username: phoneNumber, password: password);
  }

  @override
  Future<AuthResponse> authWithUserToken(UserToken token) async {
    await localDataManager.setToken(token);
    try {
      final result = MeResponseDto.fromJson(await appApiService.me());
      unawaited(localDataManager.saveUserInfo(result.user));
      return AuthSuccessResponse(user: result.user);
    } catch (e) {
      await localDataManager.setToken(null);
      rethrow;
    }
  }

  Future<AuthResponse> _persistAuthResult(AuthResultDto result) async {
    await localDataManager.setToken(result.token);
    await localDataManager.saveUserInfo(result.user);
    return AuthSuccessResponse(user: result.user);
  }

}
