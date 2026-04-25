import 'package:dio/dio.dart' as dio_p;

import '../../../common/constants.dart';
import '../../../common/utils.dart';
import '../../data.dart';

part 'api_service_error.dart';

class AppApiService {
  final RestApiRepository restApi;
  final CoreLocalDataManager localDataManager;

  AppApiService(this.restApi, this.localDataManager);

  Future<Map<String, dynamic>> signin(Map<String, dynamic> body) {
    return restApi.signin(body).then((value) => value as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> signup(Map<String, dynamic> body) {
    return restApi.signup(body).then((value) => value as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> me() {
    return restApi.me().then((value) => value as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> sendChatMessage(Map<String, dynamic> body) {
    return restApi
        .sendChatMessage(body)
        .then((value) => value as Map<String, dynamic>);
  }
}
