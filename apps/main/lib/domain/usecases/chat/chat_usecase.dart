import 'package:core/core.dart';
import 'package:data_source/data_source.dart';
import 'package:injectable/injectable.dart';

part 'chat_usecase.impl.dart';

abstract class ChatUsecase {
  Future<SendMessageResponse> sendMessage(String message);
}
