import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'api_contract.dart';

part 'rest_api_repository.g.dart';

///////////////////////////////////////////////////////////////////////
//                https://pub.dev/packages/retrofit                 //
// dart run build_runner build --delete-conflicting-outputs //
////////////////////////////////////////////////////////////////////

@RestApi()
abstract class RestApiRepository {
  factory RestApiRepository(Dio dio) = _RestApiRepository;

  @POST(ApiContract.authSignin)
  Future<dynamic> signin(@Body() Map<String, dynamic> body);

  @POST(ApiContract.authSignup)
  Future<dynamic> signup(@Body() Map<String, dynamic> body);

  @GET(ApiContract.authMe)
  Future<dynamic> me();

  @GET(ApiContract.chatUsers)
  Future<dynamic> getChatUsers();

  @GET(ApiContract.chatMessages)
  Future<dynamic> getChatMessages(
    @Query('peer_user_id') String peerUserId,
    @Query('after_created_at') String? afterCreatedAt,
    @Query('after_updated_at') String? afterUpdatedAt,
    @Query('before_created_at') String? beforeCreatedAt,
    @Query('limit') int? limit,
  );

  @DELETE('${ApiContract.chatMessages}/{message_id}')
  Future<dynamic> deleteChatMessage(@Path('message_id') String messageId);

  @POST(ApiContract.chatMessages)
  Future<dynamic> sendChatMessage(@Body() Map<String, dynamic> body);
}
