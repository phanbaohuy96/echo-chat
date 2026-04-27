import 'package:core/core.dart';
import 'package:data_source/data_source.dart';
import 'package:flutter_core/domain/entities/auth/response.dart';
import 'package:flutter_core/domain/usecases/auth/auth_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../usecase_test_fakes.dart';

void main() {
  group(AuthInteractorImpl, () {
    test('signin persists the returned token and user', () async {
      const user = UserModel(id: 'user', username: 'alice');
      final token = userToken('signin-token');
      final localDataManager = TestLocalDataManager();
      final restApi = FakeRestApiRepository()
        ..signinResponse = authResultDto(token: token, user: user).toJson();
      final usecase = AuthInteractorImpl(
        localDataManager,
        AppApiService(restApi, localDataManager),
      );

      final response = await usecase.signin(
        username: 'alice',
        password: 'secret',
      );

      expect(restApi.lastSigninBody, {
        'username': 'alice',
        'password': 'secret',
      });
      expect(localDataManager.corePreferences.savedToken, token);
      expect(localDataManager.appPreferences.savedUserInfo?.id, user.id);
      expect(response, isA<AuthSuccessResponse>());
    });

    test('signup persists the returned token and user', () async {
      const user = UserModel(id: 'user', username: 'alice');
      final token = userToken('signup-token');
      final localDataManager = TestLocalDataManager();
      final restApi = FakeRestApiRepository()
        ..signupResponse = authResultDto(token: token, user: user).toJson();
      final usecase = AuthInteractorImpl(
        localDataManager,
        AppApiService(restApi, localDataManager),
      );

      final response = await usecase.signup(
        name: 'Alice',
        username: 'alice',
        password: 'secret',
      );

      expect(restApi.lastSignupBody, {
        'name': 'Alice',
        'username': 'alice',
        'password': 'secret',
      });
      expect(localDataManager.corePreferences.savedToken, token);
      expect(localDataManager.appPreferences.savedUserInfo?.id, user.id);
      expect(response, isA<AuthSuccessResponse>());
    });

    test(
      'loginWithPhoneNumberPassword delegates through signin credentials',
      () async {
        final localDataManager = TestLocalDataManager();
        final restApi = FakeRestApiRepository();
        final usecase = AuthInteractorImpl(
          localDataManager,
          AppApiService(restApi, localDataManager),
        );

        await usecase.loginWithPhoneNumberPassword(
          phoneNumber: '+84901234567',
          password: 'secret',
        );

        expect(restApi.lastSigninBody, {
          'username': '+84901234567',
          'password': 'secret',
        });
      },
    );

    test(
      'authWithUserToken stores token and current user on success',
      () async {
        final token = userToken('restored-token');
        const user = UserModel(id: 'user', username: 'alice');
        final localDataManager = TestLocalDataManager();
        final restApi = FakeRestApiRepository()
          ..meResponse = const MeResponseDto(user: user).toJson();
        final usecase = AuthInteractorImpl(
          localDataManager,
          AppApiService(restApi, localDataManager),
        );

        final response = await usecase.authWithUserToken(token);

        expect(localDataManager.corePreferences.savedToken, token);
        expect(localDataManager.appPreferences.savedUserInfo?.id, user.id);
        expect(response, isA<AuthSuccessResponse>());
      },
    );

    test('authWithUserToken clears token when validation fails', () async {
      final token = userToken('expired-token');
      final localDataManager = TestLocalDataManager();
      final restApi = FakeRestApiRepository()..meError = StateError('expired');
      final usecase = AuthInteractorImpl(
        localDataManager,
        AppApiService(restApi, localDataManager),
      );

      await expectLater(usecase.authWithUserToken(token), throwsStateError);

      expect(localDataManager.corePreferences.savedToken, isNull);
    });
  });
}
